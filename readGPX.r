# This is a largely unmodified copy of readGPX.R from plotKML
# https://github.com/Envirometrix/plotKML
# recently, plotKML was archived on CRAN 
# for details see: https://github.com/Envirometrix/plotKML/issues/12
# this function seems unaffected so for continued compatiability
# I've extracted it and added explicit mentions to the XML package
# The original code was indicated as being released under GPL but 
# did not specify the version. I have assumed GPL-3.0, 
# but note the complication.
# ~wrc

# Note: corrections in the code by: Berry Boessenkool (berryboessenkool@hotmail.com)

readGPX <- function(
    gpx.file,
    metadata = TRUE,
    bounds = TRUE,
    waypoints = TRUE, 
    tracks = TRUE,  
    routes = TRUE   
    )
    {
require(XML)    
    opt <- options(warn=-1)    
    if(!file.exists(gpx.file)) stop("The file '", gpx.file, "'\n  does not exist in ", getwd() )
  
    if(metadata==TRUE) { metadata <- .readGPX.element(gpx.file, "name") }    
    if(bounds==TRUE) { bounds <- .readGPX.element(gpx.file, "bounds") }    
    if(waypoints==TRUE) { waypoints <- .readGPX.element(gpx.file, "wpt") }
    if(tracks==TRUE) { tracks <- .readGPX.element(gpx.file, "trk") }
    if(routes==TRUE) { routes <- .readGPX.element(gpx.file, "rte") }
        
    gpx <- list(metadata=metadata, bounds=bounds, waypoints=waypoints, tracks=tracks, routes=routes)
    return(gpx)
    on.exit(options(opt))
}

## Read various elements from a *.gpx file:

.readGPX.element <- function(gpx.file, element) {
    # element = "metadata", "wpt", "rte", "trk"
    
    ret <- XML::xmlTreeParse(gpx.file, useInternalNodes = TRUE)
    # top structure: 
    top <- XML::xmlRoot(ret)
    
    # check if there is any content:
    if(any(grep(element, names(top)))) {
    
      # tracks:
      if(element=="trk"){   
      ret <- NULL
      nu <- which(names(top) %in% element)
      for(c in seq_along(nu)){
        lst <- which(names(top[[nu[c]]]) %in% "trkseg")
        nm <- names(top[[nu[c]]][[lst[1]]][[1]])
        ret[[c]] <- list(NULL)
          for(i in seq_along(lst)) {
          trkpt <- top[[nu[c]]][[lst[i]]]
          ret[[c]][[i]] <- data.frame(NULL)
          ## get columns (https://www.topografix.com/GPX/1/1/#type_wptType)
          lon <- as.numeric(XML::xmlSApply(trkpt, XML::xmlGetAttr, "lon"))
          lat <- as.numeric(XML::xmlSApply(trkpt, XML::xmlGetAttr, "lat"))
          ret[[c]][[i]][1:length(lon),"lon"] <- lon
          ret[[c]][[i]][1:length(lat),"lat"] <- lat
          if(!nm[[1]]=="NULL"){
             for(j in 1:length(nm)){
                xm <- as.character(sapply(sapply(XML::xmlChildren(trkpt), function(x) x[[nm[[j]]]]), xmlValue))
                ret[[c]][[i]][1:length(xm), nm[[j]]] <- xm 
                }
          } 
          }
        names(ret[[c]]) <- xmlValue(top[[nu[c]]][["name"]])
       }   
      }
    
      if(element=="wpt"){
      ret <- data.frame(NULL)
      nu <- which(names(top) %in% element)
      nm <- names(top[[nu[1]]])
      for(i in seq_along(nu)) {
        # coordinates:
        ret[i, "lon"] <- as.numeric(xmlGetAttr(top[[nu[i]]], "lon"))
        ret[i, "lat"] <- as.numeric(xmlGetAttr(top[[nu[i]]], "lat"))
        if(!nm[[1]]=="NULL"){
          for(j in 1:length(nm)){
            ret[i, nm[[j]]] <- xmlValue(xmlChildren(top[[nu[i]]])[[nm[[j]]]])
          }  
          }
       }
      }
    
      if(element=="rte"){
      ret <- NULL
      nu <- which(names(top) %in% element)
      for(c in seq_along(nu)){
        ret[[c]] <- data.frame(NULL)
        lst <- which(names(top[[nu[c]]]) %in% "rtept")
        nm <- names(top[[nu[c]]][[lst[1]]])
        for(i in seq_along(lst)) {
          rtept <- top[[nu[c]]][[lst[i]]]
          ret[[c]][i, "lon"] <- as.numeric(XML::xmlGetAttr(rtept, "lon"))
          ret[[c]][i, "lat"] <- as.numeric(XML::xmlGetAttr(rtept, "lat"))
          if(!nm[[1]]=="NULL"){
             for(j in c("name","cmt","desc","sym","type")){
                try(ret[[c]][i, j] <- XML::xmlValue(rtept[[j]]), silent = TRUE)
                }
          } 
        }
        names(ret)[c] <- XML::xmlValue(top[[nu[c]]][["name"]])
        }
      }
      
      # bounds
      if(element=="bounds"){
      nu <- which(names(top) %in% element)
      ret <- matrix(rep(NA, 4), nrow=2, dimnames = list(c("lat", "lon"), c("min", "max")))
      # coordinates:
      ret[1,1] <- as.numeric(XML::xmlGetAttr(top[[nu[1]]], "minlon"))
      ret[1,2] <- as.numeric(XML::xmlGetAttr(top[[nu[1]]], "maxlon"))
      ret[2,1] <- as.numeric(XML::xmlGetAttr(top[[nu[1]]], "minlat"))
      ret[2,2] <- as.numeric(XML::xmlGetAttr(top[[nu[1]]], "maxlat"))
      }
          
      # metadata
      if(element=="name"){
      lst <- c("name","desc","author","email","url","urlname","time")
      nu <- which(names(top) %in% lst)
      if(!nu[[1]]=="NULL"){      
      ret <- data.frame(NULL)
      for(i in seq_along(lst)) {
        try(ret[1,lst[i]] <- xmlValue(top[[nu[[i]]]]), silent = TRUE)
        }
      }
      }
         
    }
    else { ret <- NULL }

    return(ret)
}
