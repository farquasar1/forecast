### Time series graphics and transformations

tsdisplay <- function(x,plot.type="partial",points=TRUE,ci.type="white",
                lag.max, na.action=na.interp, main=NULL,ylab="",xlab="",
                pch=1,cex=0.5, ...)

{
  itype <- charmatch(plot.type, c("partial", "scatter", "spectrum"), nomatch = 0)
  switch(itype + 1,stop("desired type of plot is unknown"),
  plot.type <- "partial",plot.type <- "scatter",plot.type <- "spectrum")

  def.par <- par(no.readonly = TRUE)# save default, for resetting...
  nf <- layout(matrix(c(1,1,2,3), 2, 2, byrow = TRUE))

  if(is.null(main))
    main <- deparse(substitute(x))
  if(!is.ts(x))
    x <- ts(x)
  if(missing(lag.max))
    lag.max <- round(min(max(10*log10(length(x)), 3*frequency(x)), length(x)/3))
     
  plot.ts(x,main=main,ylab=ylab,xlab=xlab,ylim=range(x,na.rm=TRUE),...)
  if(points)
    points(x,pch=pch,cex=cex,...)
  xx <- na.action(x)
  ylim <- c(-1,1)*3/sqrt(length(xx))

  junk1 <- acf(c(xx),lag.max=lag.max,plot=FALSE,na.action=na.pass)
  junk1$acf[1,1,1]<-0
  if(ci.type=="ma")
    ylim <- range(ylim,0.66*ylim * max(sqrt(cumsum(c(1, 2 * junk1$acf[-1, 1, 1]^2)))))
  ylim <- range(ylim,junk1$acf)
  if(plot.type == "partial")
  {
    junk2 <- pacf(c(xx),lag.max=lag.max,plot=FALSE,na.action=na.pass)
    ylim <- range(ylim,junk2$acf)
  }

  oldpar <- par(mar=c(5,4.1,1.5,2))
  plot(junk1,ylim=ylim,xlim=c(1,lag.max),ylab="ACF",main="",ci.type=ci.type,...)
  if(plot.type == "scatter")
  {
    n <- length(x)
    plot(x[1:(n-1)],x[2:n],xlab=expression(Y[t-1]),ylab=expression(Y[t]), ...)
  }
  else if(plot.type == "spectrum")
    spec.ar(xx,main="")
  else
    plot(junk2,ylim=ylim,xlim=c(1,lag.max),ylab="PACF",main="",...)
  par(def.par)
  layout(1)
  invisible()
}

na.interp <- function(x)
{ # interpolates missing values
  n <- length(x)
  nas <- is.na(x)
  idx <- (1:n)[!nas]
  xx <- as.ts(approx(idx,x[idx],1:n)$y)
  tsp(xx) <- tsp(x)
  return(xx)
}

seasonplot <- function(x, s, season.labels=NULL, year.labels=FALSE, year.labels.left=FALSE,
    type="o", main, ylab="", xlab=NULL, col=1, labelgap=0.1, ...)
{
  if(missing(main))
    main = paste("Seasonal plot:", deparse(substitute(x)))
  if(missing(s))
    s = frequency(x)
  if(s<=1)
    stop("Frequency must be > 1")

  # Pad series
  tsx <- x
  if(start(x)[2]>1)
    x <- c(rep(NA,start(x)[2]-1),x)
  x <- c(x,rep(NA,s-length(x)%%s))
  Season <- rep(c(1:s,NA),length(x)/s)
  xnew <- rep(NA,length(x))
  xnew[!is.na(Season)] <- x

  if(s == 12)
  {
    labs <- month.abb
    xLab <- "Month"
  }
  else if(s == 4)
  {
    labs <- month.name[c(1, 4, 7, 10)]
    xLab <- "Quarter"
  }
  else if(s == 7)
  {
    labs <- c("Sun","Mon","Tue","Wed","Thu","Fri","Sat")
    xLab <- "Day"
  }
  else
  {
    labs <- NULL
    xLab <- "Season"
  }
  if(is.null(xlab))
    xlab <- xLab
  if(is.null(season.labels))
    season.labels <- labs
  if(year.labels)
    xlim <- c(1-labelgap,s+0.4+labelgap)
  else
    xlim<-c(1-labelgap,s)
  if(year.labels.left)
    xlim[1] <- 0.4-labelgap
  plot(Season,xnew,xaxt="n",xlab=xlab,type=type,ylab=ylab,main=main,xlim=xlim,col=0,...)
  nn <- length(Season)/s	    
  col <- rep(col,nn)[1:nn]
  for(i in 0:(nn-1))
    lines(Season[(i*(s+1)+1) : ((s+1)*(i+1))], xnew[(i*(s+1)+1) : ((s+1)*(i+1))], type = type, col = col[i+1], ...)
  if(year.labels)
  {
    idx <- which(Season[!is.na(xnew)]==s)
    year <- time(tsx)[idx]
    text(x=rep(s+labelgap,length(year)),y=tsx[idx],labels=paste(c(trunc(year))),adj=0,...,col=col[1:length(idx)])
  }
  if(year.labels.left)
  {
    idx <- which(Season[!is.na(xnew)]==1)
    year <- time(tsx)[idx]
    if(min(idx)>1) # First year starts after season 1n
      col <- col[-1]
    text(x=rep(1-labelgap,length(year)),y=tsx[idx],labels=paste(c(trunc(year))),adj=1,...,col=col[1:length(idx)])
  }
  if(is.null(labs))
    axis(1,...)
  else
    axis(1,labels=season.labels,at=1:s,...)
}
