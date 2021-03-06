#' Function that calculates discards for the non-catch share vessels
#' 
#' @template dat
#' @param strat
#' @param B
#' @param conf.df
#' @param conf.df.cols
#' @param dat.cols
#' @param ratio
#' @param saveBootFile
#' @param logFile
#'
#'
#'
#' @author Allan Hicks and Chantel WEtzel
#' @export
#'
discardsNonCatchShares <- function(dat, strata, B, conf.df=NULL, conf.df.cols=NULL, dat.cols=NULL, ratio=c("proportion","expansion"), saveBootFile="outB.Rdat", logFile="") {
	#calculate catch shares discard quantities
#I think I can set dat.cols=c("Years",strata)
	#check for CatchShares, create if necessary and add to strata
	if(!"CatchShares"%in%colnames(dat)) {
		cat("Keeping only Non-Catch Shares observations.\n")
		dat <- determineCatchShares(dat)
		cat("Removing",sum(dat$CatchShares),"rows from your dataframe.\n")
		dat <- dat[!dat$CatchShares,]
	}
	if(!"CatchShares"%in%strata) {
		strata <- c(strata,"CatchShares")
	}
	if(!"CatchShares"%in%conf.df.cols) {
		conf.df.cols <- c(conf.df.cols,"CatchShares")
	}
	if(!"CatchShares"%in%dat.cols) {
		dat.cols <- c(dat.cols,"CatchShares")
	}

	outB <- bootDiscardRatio.fn(dat, yrColNm="ryear",
									 strat=strata,
									 B=B,
									 vesselColNm="drvid",
									 discard="dis",
									 retained="ret",
									 ratio=ratio,
									 minVessels=1,
									 writeLog=logFile)
	if(!is.null(saveBootFile)) {
		save(outB,file=saveBootFile)
	}
	dis <- bootSummary.fn(outB,B=B,strtNms=strata)

	if(!is.null(conf.df)) {
		#Combine each summary dataframe with confidentiality output
		#   Note: Some strata will have vessels but no data because those strata did not catch the species.
		out <- merge(conf.df[,!colnames(conf.df)%in%c("unique.drvid","sum.dis","sum.ret")],
					 dis,
					 by.x = conf.df.cols,
					 by.y = dat.cols, 
					 all.y = T)

		if(any(is.na(out$numVessels) | (out$numVessels < 3&out$numVessels > 0))) {
			cat("\n-------------- WARNING ------------\n")
			cat("WARNING: There are confidential strata in your non-catch shares data.\n\n")
		}

	} else {
	  	out <- dis
	}

	out$Ratio_Type <- switch(ratio[1],
							  proportion = 'DIS/(DIS + RET)',
							  expansion  = 'DIS/RET',
							  stop("ratio type must be 'proportion' or 'expansion'\n"))

 	colnames(out)[(ncol(out)-17):ncol(out)] <- c('Observed_DISCARD.MTS','Observed_RETAINED.MTS','Observed_Ratio',
 		    'Mean.Boot_DISCARD.MTS','Median.Boot_DISCARD.LBS','StdDev.Boot_DISCARD.LBS','CV.Boot_DISCARD.LBS',
		    'Mean.Boot_RETAINED.MTS','Median.Boot_RETAINED.MTS','StdDev.Boot_RETAINED.MTS','CV.Boot_RETAINED.MTS',
		    'Mean.Boot_Ratio','Median.Boot_Ratio','StdDev.Boot_Ratio','CV.Boot_Ratio',
		    'no.Boot.samples','Est.Bias.Ratio','Ratio_Type')

 	# If not doing a bootstrap remove those columns from the output
 	if( B == 1){
 		out = out[ , c(1:13, dim(out)[2])]
 	}

 	out <- out[!as.logical(out$CatchShares),]
	return(out)
}

