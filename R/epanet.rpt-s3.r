#************************************
#
#  (C) Copyright IBM Corp. 2015
#
#  Author: Bradley J Eck
#
#************************************#


#' Read .rpt file
#' 
#' reads an Epanet .rpt file into R
#' 
#' @export 
#' @param rptFile the file to read
#' @return a list of data frames 
#'
#' @details add lines "Page 0", "Links All" and "Nodes All" to the
#'  [REPORT] section of the .inp file to output info to read in
#' with this function
#' @references Rossman, L. A. (2000). Epanet 2 users manual. US EPA, Cincinnati, Ohio.
# http://nepis.epa.gov/Adobe/PDF/P1007WWU.pdf
read.rpt <- function( rptFile ){
 
  return( epanet.rpt(rptFile))	
}


epanet.rpt <- function( rptFile){
  # read all the lines in the file 
  allLines <- readLines(rptFile)
  lengthOfAllLines <- length( allLines)
  
  resLines <- grep("Results", allLines)
  numTables <- length(resLines)
  
  #create a lits of empty data frames to store each of these
  nodeResList <- list()  
  linkResList <- list()  
  
    # initialize indices for these lists 
  ni <- 0  # node index
  li <- 0  # link index
  
  # go through the tables  
  for( i in 1:numTables ){
    # get the section  
    sectRange <- .getSectionRange( i, resLines, lengthOfAllLines)
    sect <- allLines[ sectRange$start : sectRange$end ]  
    
    # create a data frame from this section
    df <- .section2df( sect )  

    # decide if it's for link or node results 
    isNODE <- grepl( "Node", sect[1] )
    isLINK <- grepl( "Link", sect[1] )
    
    #add  data to approriate list of data frames 
    if( isNODE ){
      # increment node indexer 
      ni <- ni + 1
      nodeResList[[ ni ]] <- df
    }
    
    if( isLINK ){
      # increment indexer 
      li <- li + 1
      linkResList[[ li ]] <- df
    }
  }
  
  # combine all these results together 
  nodeResDF <- do.call("rbind", nodeResList )
  linkResDF <- do.call("rbind", linkResList )
 
  
  # add a column specifying the type of node or link
  # use a factor for this 
	
	if( is.null(nodeResDF) == FALSE ) {	
		# make all of them juncs 
		nodeResDF$nodeType <- factor("Junction", 
				levels = c("Junction", "Tank", "Reservoir"))	
		# then identify the tanks and reservoirs 
		tankRows <- which(nodeResDF$note == "Tank")  
		nodeResDF$nodeType[tankRows] <- "Tank"	
		resRows <- which(nodeResDF$note == "Reservoir")
		nodeResDF$nodeType[resRows] <- "Reservoir"
	}
  
  # same idea for the links 
	if( is.null(linkResDF) == FALSE){
		linkTypeLevels <- 	c("Pipe", "Pump", 
				"PSV", "PRV", "PBV", "FCV", "TCV", "GPV")
		
		linkResDF$linkType <- factor("Pipe", levels = linkTypeLevels)
		
		allLinksArePipes <- as.logical(max(is.na(linkResDF$note)))
		
		if( allLinksArePipes == FALSE){
			# take the notes that are not blank and cast to factor 
			rows2cast <-  which( linkResDF$note != "" ) 
			linkResDF$linkType[rows2cast] <- factor(linkResDF$note[rows2cast ], levels = linkTypeLevels)  
		}
	}
  # and make a list of the to return 
  allResults <- list( nodeResults = nodeResDF, 
                      linkResults = linkResDF )
  
  class(allResults) <- "epanet.rpt"

  return( allResults ) 
}



#' Summary of Water Network Simulation Results
#'
#' Provides a basic sumary of simulation results 
#'
#' @export
#' @param  object of epanet.rpt class
#' @param ... further arguments passed to summary()
#' @details 
#' Summary of pipe results shows positive and negative
#' values of flow but only positive values of velocity
#' as in the rpt file. 
summary.epanet.rpt <- function( object, ... ){

	###############
	# node results 
	###############
	
	# find the number of time steps reported 
	numNodeTimeSteps <- length(unique(object$nodeResults$Timestamp))
	
	if( numNodeTimeSteps > 0 ){
		nodeCols <- names(object$nodeResults)[c(2,4)]
		n5 <- names(object$nodeResults)[5]
		
		if( is.na(n5) == FALSE ){
			if( n5 != "note"){
				nodeCols <- c(nodeCols, n5)
			}
		}
		
		# silence R CMD check 
		nodeType <- NULL 
		
		juncSmry <- summary(  subset(object$nodeResults, nodeType == "Junction",
						select = nodeCols ) )
		
		tankSmry <- summary(  subset(object$nodeResults, nodeType == "Tank", 
						select = nodeCols ) )
	} else {
		
		juncSmry <- NA
		tankSmry <- NA
	}
	 
	 
	################
	#  link results 
	################
	numLinkTimeSteps <- length(unique(object$linkResults$Timestamp))
    
	if( numLinkTimeSteps > 0 ){
		# silence R CMD check 
		linkType <- NULL 
		
		pipeSmry <- summary(  subset(object$linkResults, linkType == "Pipe", 
						select = c("Flow","Velocity", "Headloss") ) )
	} else {
		
		pipeSmry <- NA
	}
	
	
	# Collect items to return in a list 
	rptSmry <- list( numLinkTimeSteps = numLinkTimeSteps,
			         numNodeTimeSteps = numNodeTimeSteps,
			         juncSummary = juncSmry,
					 tankSummary = tankSmry,
					 pipeSummary = pipeSmry) 
	
	class(rptSmry) <- "summary.epanet.rpt"		 
			
	return( rptSmry)
  
}


#' Print rpt summary
#' 
#' The function prints a summary of simulation results
#' contained in the rpt file. 
#'  
#' @export
#' @param x a summary.epanet.rpt object   
#' @param ... further arguments passed to print 
print.summary.epanet.rpt <- function(x,...){
	# how many timesteps for nodes 
	cat("Contains node results for ", x$numNodeTimeSteps, "time steps \n")
	cat("\n") 

	if( x$numNodeTimeSteps >0 ){
		cat("Summary of Junction Results: \n")
		print(x$juncSummary)
		cat("\n") 
		
		cat("Summary of Tank Results:\n")
		print(x$tankSummary)
		cat("\n") 
	}
	
	
	cat("Contains link results for ", x$numLinkTimeSteps, "time steps \n")
	cat("\n") 

	if( x$numLinkTimeSteps >0 ){
		cat("Summary of Pipe Results:\n")
		print(x$pipeSummary)
		cat("\n") 
	}
}


#' Get link quantity at a timestep
#'
#' Extract a table of results for a time step
#' @param rpt epanet.rpt object
#' @param linkQty string with quantity to get
#' @param Timestep string  in h:mm:ss form 
#' @return data.frame with cols "Link" and linkQty
.getLinkQtyAtTime <-function( rpt, linkQty, Timestep){

  if( is.null(linkQty)){
	  return (NULL)
  }	else if( is.na(linkQty)){
	  stop("NA not allowed for linkQty, use NULL instead")
  }	else {
	  # there is some value besides NA or NULL
	  # see if it's present in the results 
	  ok <- match(linkQty, names(rpt$linkResults))
	  if( is.na(ok)){
		  stop("linkQty not present in linkResults")
	  }
	 
	  # validate timestep 
	  ok <- match( Timestep, unique(rpt$linkResults$Timestamp))
	  if( is.na(ok)){
		  msg <- paste("link results not available for", Timestep)
		  stop(msg)
	  } else { 
		  
		  # silence R CMD check
		  Timestamp <- NULL
		  
		  # link results for this timestep		  
		  lqty <- subset( rpt$linkResults,
				  Timestamp == Timestep, 
				  select = c( "Link", linkQty ) )
		  
	  }
	  
      return( lqty)
  }

}



#' Get junc quantity at a timestep
#'
#' Extract a table of results for a time step
#' @param rpt epanet.rpt object
#' @param juncQty string with quantity to get
#' @param Timestep string  in h:mm:ss form 
#' @return data.frame with cols "Node" and juncQty
.getNodeQtyAtTime <- function(rpt,juncQty,Timestep){
# validate juncQty
  if( is.null(juncQty)){ 
	  
	  return (NULL)
  } else if( is.na(juncQty)){
	  stop("NA not allowed for juncQty, use NULL instead")
  }	else {
	  # there is some value besides NA or NULL
	  # see if it's present in the results 
	  ok <- match(juncQty, names(rpt$nodeResults))
	  if( is.na(ok) ){
		  stop("juncQty not present in nodeResults")
	  }
	  
	  # check timestep  
	  ok <- match( Timestep, unique(rpt$nodeResults$Timestamp))
	  if( is.na(ok)){
		  msg <- paste("node results not available for", Timestep)
		  stop(msg)
	  } else { 
		  # silence R CMD check
		  Timestamp <- NULL
		  # extract desired results 
		  juncqty <- subset(rpt$nodeResults, Timestamp == Timestep, select=c("Node", juncQty))
	  }	  
    
	  return( juncqty)
  }
  
}


.plotRptLinks <- function(lqty, inp){
	
	if( is.null(lqty) ){
		# handle the case where we don't want to plot link
		# results but still draw the network structure 
	    plotInpLinks(inp)	
	} else {
		# scale quanity 
		#############
		#  Pipes  
		############# 
		
		if( is.null( inp$Pipes) == FALSE ){
			
			# add coordinates to the pipe table 
			ept <-  expandedLinkTable( inp$Pipes, inp$Coordinates )  
		    
			# add bin info to table 
			# could write merge.expandedLinkTable() but prolly not worth it 
			ept2 <- merge( x = ept, by.x = "ID", y = lqty, by.y = "Link")
	
			# plot the segments 
			segments( x0 = ept2$x1, y0 = ept2$y1,
		              x1 = ept2$x2, y1 = ept2$y2,
					 lwd = ept2$bin   )  
		}
		
		
		#############
		#  Pumps  
		############# 
		if( is.null( inp$Pumps ) == FALSE ){
			ept <-  expandedLinkTable( inp$Pumps, inp$Coordinates )
			
			# add bin info to table 
			# could write merge.expandedLinkTable() but prolly not worth it 
			ept2 <- merge( x = ept, by.x = "ID", y = lqty, by.y = "Link")
	
			# plot the segments 
			segments( x0 = ept2$x1, y0 = ept2$y1,
		              x1 = ept2$x2, y1 = ept2$y2,
					 lwd = ept2$bin   )  
			
			points( ept$midx, ept$midy, pch = 8 ) 
		}
		
		
		#############
		#  Valves 
		############# 
		if( is.null( inp$Valves  )  == FALSE ){
			evt <- expandedLinkTable(inp$Valves, inp$Coordinates)
			# add bin info to table 
			# could write merge.expandedLinkTable() but prolly not worth it 
			ept2 <- merge( x = ept, by.x = "ID", y = lqty, by.y = "Link")
	
			# plot the segments 
			segments( x0 = ept2$x1, y0 = ept2$y1,
		              x1 = ept2$x2, y1 = ept2$y2,
					 lwd = ept2$bin   )  
			
			points( evt$midx, evt$midy, pch = 25 ,
					bg="black", col = "black" )  
		}
		
		
	}
	
	
}

#' @param ndqty
#' @param inp epanet.inp object 
.plotRptNodes <- function(ndqty, inp){
	
	if( is.null( ndqty)){
		
		plotInpNodes(inp, plot.junctions = TRUE)
		
	} else { 
		
		plotInpNodes(inp, plot.junctions = FALSE) # this gets RES and TANKS
		
		# now add the scaled junctions 
		# add coordinates to junctions 
		jpts <- merge( x = subset(inp$Junctions, select = "ID") , by.x = "ID", all.x = TRUE,
				y = inp$Coordinates, by.y = "Node" )
		
		# add desired results too junc table w coordinates 
		jpts <- merge( x = jpts, by.x = "ID", all.x = TRUE,
				y = ndqty, by.y = "Node")
		
		points( jpts$X.coord, jpts$Y.coord, pch = 21, bg = 'gray',  
				cex = jpts$bin )  
	}
}

#' plot legend for results
#' 
#' helper function to plot a legend for the simulation results 

.plotRptLegend <- function(juncQty, juncBinfo, linkQty, linkBinfo, legend2.locn){
	# use legend with three values  for each qty  
	if( is.null(juncBinfo)){
		juncTitle = ""
		juncNums <- c("","","")
	    jpch = c(NA,NA,NA)	
		jbg = c(NA,NA,NA)
		jcex = c(NA,NA,NA)
	} else {
		juncTitle = juncQty
		juncNums <- juncBinfo$Labels
		if( length(juncNums) != 3){
			stop(" legend is setup for 3 bins")
		}
		jpch = c(21,21,21) 	
		jbg =  c('gray','gray','gray')
		jcex = c(1,2,3) 
	}

	
	
	if( is.null(linkQty)){
		linkTitle = ""
		linkNums = c("","","")
		llwd = c(NA,NA,NA) 
	} else {
		linkTitle = linkQty
		linkNums <- linkBinfo$Labels
		if( length(linkNums) != 3){
			stop(" legend is setup for 3 bins")
		}
		llwd = c(1,2,3)
	}

	
	# now actually plot the legend 
	legend( legend2.locn, bty  = 'n', ncol =2 ,
			legend=c(juncNums, linkNums) ,
			title = paste(juncTitle, linkTitle, sep = "   ") ,
			title.adj = 0.5,
			pch = c(jpch,NA,NA,NA),
			pt.bg = c(jbg, NA,NA,NA),
			pt.cex = c(jcex, NA,NA,NA),
			col = 'black',
			lwd = c(NA,NA,NA, llwd)
	)
	
}

#' Plot Simulation Results 
#'
#' Plots simulation results for a single time step in map form  
#'
#' @export
#' @param x  epanet.rpt object 
#' @param inp epanet.inp object associated with x
#' @param Timestep string indicating the time at which to plot 
#' @param juncQty string specifying which column of node results table
#'                to plot for junctions 
#' @param linkQty string specifying which column of link results table 
#'                to plot 
#' @param legend1.locn placement of legend for network elements
#' @param legend2.locn placement of legend for junction and link quantities
#' @param ... further arguments passed to plot 
#' @details juncQty is scaled over only junction result types.  linkQty is
#'         scaled over all of the link types 
plot.epanet.rpt <- function( x,
		inp,
		Timestep = "0:00:00",
		juncQty = "Demand",
		linkQty = "Velocity",
		legend1.locn = "topright",
		legend2.locn = "topleft",
		... ){
	
	
	# check that coordinates actually exist   
	if( is.null(inp$Coordinates) ){
		stop("network does not have coordinates" )
	}
	
	# node results for this time   
	ndqty <- .getNodeQtyAtTime(x,juncQty,Timestep)
	
	if( is.null(ndqty) == FALSE){
		# silence R CMD check 
		nodeType <- NULL 
		
		allJuncVals <- subset( x$nodeResults, nodeType == "Junction", select = juncQty)
		
		juncBinfo <- binBreaker( allJuncVals[,1], nbin = 3 )
		
		# add bin numbers to ndqty 
		ndqty$bin <- cut( ndqty[,2], breaks = juncBinfo$Breaks, labels = FALSE )
		
	}
	
	#  link results for this time  
	lqty <- .getLinkQtyAtTime(x,linkQty,Timestep)
	
	# Find three bins for link quanity considering
	# simulation results at all times 	
	if( is.null(lqty) == FALSE){
        
		# all the values 
		allLinkVals <- abs(  (subset(x$linkResults, select = linkQty ) ))
		
		# find bin breaks and labels 
		linkBinfo <- binBreaker( allLinkVals[,1], nbin = 3 ) 
	
		# add bin numbers to lqty 
		lqty$bin <- cut( lqty[,2], breaks = linkBinfo$Breaks, labels = FALSE )
		
	}
	
	# create blank plot 
	par( mar = c(1,1,1,1))
	plot( range(inp$Coordinates$X.coord),
			range(inp$Coordinates$Y.coord),
			type = 'n',
			xlab = "", xaxt = 'n',
			ylab = "", yaxt = 'n'
	)

  
   .plotRptLinks(lqty, inp)
   
   .plotRptNodes(ndqty,inp)
   
  # legend 1 just to define symbols 
  plotInpLegend(legend1.locn)
 
  .plotRptLegend(juncQty, juncBinfo, linkQty, linkBinfo, legend2.locn)
  

}

