# stv() - core of STV package - last revised 29 jan 2024

#' STV election count - uses Meek STV, allows equal preferences
#'
#' @param votedata File with vote data
#' @param outdirec Needs to be set for permanent record of results
#' @param plot If =TRUE (default) produces plots of count and webpages in outdirec
#' @param webdisplay If =TRUE displays plots and statistics as web pages
#' @param interactive If =TRUE reports and pauses at each stage of the count
#' (press return to continue to next stage)
#' @param messages If=TRUE prints 1-line initial and final reports
#' @param timing Whether to report computing time at each stage
#' @param map Link to a map or other URL associated with election
#'
#' @return A list containing vote and count data, + optional web pages; for details see manual pref_pkg_manual.pdf (section 3)
#' @export
#'
#' @examples cnc17meek=stv(cnc17,plot=FALSE)
#' @examples c99result=stv(c99,plot=FALSE)
#' @examples y12meek=stv(y12,plot=FALSE)
#'
stv=function(votedata,outdirec=tempdir(),plot=TRUE,webdisplay=FALSE,interactive=FALSE,messages=TRUE,timing=FALSE,map=FALSE){
# don't try plotting if package jpeg is not available:
if(requireNamespace("jpeg")==FALSE){
    plot=FALSE; warning("package jpeg not available, setting plot=FALSE")
}
sys="meek"
tim0=proc.time()    # to track computing time taken (use timing=T to print for each stage)
# read and unpack elecdata - only essential component is vote matrix vd$v
vd=votedata; vote=vd$v
nvd=names(vd)
if("s" %in% nvd){ns=vd$s}else{ns=as.numeric(readline("number of seats? "))}
nv0=dim(vote)[[1]]; nc0=dim(vote)[[2]]
if("e" %in% nvd){elecname=vd$e}else{elecname="election"}
if("c" %in% nvd){nc=vd$c}else{nc=nc0}
if("nv" %in% nvd){nv=vd$nv}else{nv=nv0}
if("m" %in% nvd){mult=vd$m}else{mult=rep(1,nv)}
totalvotes=sum(mult); na2=dimnames(vote)[[2]]
if(is.null(na2)){na2=let(nc)}else{if(na2[[1]]=="V1"){na2=let(nc)}}
if("n" %in% nvd){name=vd$n}else{if("n2" %in% nvd){name=vd$n2}else{name=na2}}
if("n2" %in% nvd){name2=vd$n2}else{name2=name}
if("f" %in% nvd){fname=vd$f}else{fname=rep("",nc)}
if("p" %in% nvd){party=vd$p}else{party=rep("",nc)}; np={party[[1]]==""}
if("col" %in% nvd){colour=vd$col}else{colour=grDevices::rainbow(nc)}
vd=list(e=elecname,s=ns,c=nc,nv=nv,m=mult,v=vote,f=fname,n=name,n2=name2,p=party,col=colour); votedata=vd

q0=totalvotes/(ns+1)	# initial quota

if(interactive==TRUE){
cat("\n"); cat("Election: ",elecname,"\n")
cat("System: meek STV\n")
cat("To fill",ns,"seats; ",nc," candidates:\n")
cat(paste(name,collapse=", ")); cat("\n")
cat(totalvotes,"votes;  initial quota",round(q0,2)); cat("\n\n")
}else{
if(messages==TRUE){packageStartupMessage(paste("Election:",elecname,"(Meek STV) -",nc,"candidates,",totalvotes,"votes"))}
}

if(interactive==TRUE){
width0=getOption("width")
on.exit(options(width=width0))
options(width=120)
}

# initialise quota (=q0), keep values (=1), and housekeeping variables:
qa=q0
k=rep(1,(nc+1))		# initial keep values (the +1 is for non-transferable)
ks=numeric() 		# record keep value at each stage
ems=c(min(0.01,qa*0.001),0.0000001)	# initial error margin will be decreased ..
hp=1 		        # .. if close call (when hp is changed from 1 to 2)
surplus=1		# to ensure calculation gets going
iter=0			# keeps track of number of iterations in count
it=numeric()		# it=elec(+) and excl(-) in order of being decided
ie=rep(0,nc); ne=0	# indicator (ie=1 indicates elected, =-1 excluded)
st=character()          # for stages
csum=numeric()          # count summary (votes at each stage); note also vm, va
stage=0; fin=0
elec=numeric()
sel=select(ns)          # ways of selecting subsets - needed in share
dnext=""                # text carried over from one stage to next
txt=character()         # text describing decisions at each stage
itt=list()              # cand nos in order of elec/excl for each stage
trf=c("","t")
if(!dir.exists(outdirec)){dir.create(outdirec)}
# main cycle - to elect or exclude next candidate(s)
while(ne<ns){
 em=ems[[hp]]
 # recalculate keep values and transfer surpluses
 tr=transfer(k,iter,vote,mult,ns,ie,em,surplus,sel)
  k=tr$k; vm=tr$vm; vc=tr$vc; qa=tr$qa; inn=tr$inn
 iter=tr$iter; surplus=tr$sur
# make next decision to elect or exclude
 hp0=hp
 dn=decision(nc,vc,qa,ie,k,stage,fin,csum,st,surplus,hp)
 hp=dn$hp
 if(hp!=hp0){if(interactive==TRUE){warning("close call - need high precision")}
 }else{
  k=dn$k; ie=dn$ie; elec=dn$elec; xcl=dn$xcl; it=c(it,elec,xcl*ie[xcl])
  stage=dn$stage; csum=dn$csum; st=dn$st
  ne=length(ie[ie==1])
  ks=cbind(ks,k)
  x=decision_text(stage,ne,ns,elec,xcl,name2,dnext)
  dnext=x$d; dtext=x$t; txt=c(txt,dtext)
  if(stage==1){
   va=vm; itt=list(it)
  }else{
   va=array(c(va,vm),dim=c(nc,(nc+1),stage))
   itt=append(itt,list(it))
  }
  qpc=100*qa/totalvotes
  tim=proc.time()-tim0;  pt=tim[[1]]
# if plot=TRUE : make permanent plots of stage
  if(plot==TRUE){
  wi=(nc+4.5); w=wi*120   # plot width in (approx) inches, and in pixels
  for(i in 2:1){  # 2 plots, with/without separate transfers plot
   transf=i-1
   plotfile=paste(outdirec,paste("stage",trf[[i]],stage,".jpg",sep=""),sep="/")
   h=600+200*transf
   grDevices::jpeg(plotfile,width=w,height=h)
  voteplot(ns,vm,qpc,it,dtext,name2,party,colour,transf,elecname,sys=sys)
   grDevices::dev.off()
  }}

  if(timing==TRUE){message(paste(stage,"   process time ",round(pt,3)," secs"))}

# if interactive=TRUE : print decision, require interaction (CR) at each stage
  if(interactive==TRUE){
  if(stage==1){cat(dtext,sep="\n")}else{cat(dtext,sep=",\n")}
  cat("\n")
# .. and plot current state of votes if plot=TRUE
  if(plot==TRUE){plot_jpeg(plotfile,stage)}
   readline("next? ")
  }
 }}
fin=1; nstages=stage;  qf=qa   # final values of count proper
# extra stage to calculate final keep values
if(length(ie[ie>=0])>ns){
 tr=transfer(k,iter,vote,mult,ns,ie,em,surplus,sel)
 k=tr$k; vmp=tr$vmp; vc=tr$vc; qa=tr$qa; inn=tr$inn; iter=tr$iter; surplus=tr$sur
 while(length(k[k>0])>(ns+2)){
  dn=decision(nc,vc,qa,ie,k,stage,fin,csum,st,surplus,hp)
  k=dn$k; ie=dn$ie; elec=dn$elec; xcl=dn$xcl; it=c(it,elec,xcl*ie[xcl])
  surplus=dn$surplus; stage=dn$stage; csum=dn$csum; st=dn$st
  tr=transfer(k,iter,vote,mult,ns,ie,em,surplus,sel)
  k=tr$k; vmp=tr$vmp; vc=tr$vc; qa=tr$qa; inn=tr$inn; iter=tr$iter; surplus=tr$sur
 }
 tim=proc.time()-tim0;  pt=tim[[1]]
}
# final result
elec=it[it>0]; x=elec
if(np==FALSE){pp=paste(" (",party,")",sep="")}else{pp=party}
elected=paste(fname[x]," ",name[x],pp[x],sep="",collapse=", ")

# Runner-up
ic=1:nc; ru=ic[k[ic]==1]
if(interactive==TRUE){cat(paste("Runner-up: ",fname[ru]," ",name[ru],pp[ru],sep="",collapse=", ")); cat("\n")}

# finalise matrices of keep values and votes at each stage (ks, csum)
ks=cbind(ks,k)
dimnames(ks)=list(name=c(paste(name,fname,sep=", "),"non-transferable"),stage=1:dim(ks)[[2]])
csum=cbind(csum,100*k); st=c(st,"  final keep values (%)")
txt=matrix(txt,nrow=2)
cname=name
if(length(fname[fname!=""])>0){cname=paste0(cname,", ",fname)}
if(length(party[party!=""])>0){cname=paste0(cname," (",party,")")}    
dimnames(csum)=list(name=c(cname,"non-transferable"),stage=st)
    
if(nstages>1){qf=sum(va[1:nc,1:nc,nstages])/(ns+1)}else{qf=q0}
qtxt=paste0("Total votes ",totalvotes,",  initial quota = ",round(q0,2),", final quota = ",round(qf,2))

if(interactive==TRUE){cat("\nVotes at each stage and final keep values:\n")
 print(round(csum,2))
cat("\n",qtxt,"\n")
}else{
if(messages==TRUE){packageStartupMessage(paste("Those elected, in order of election:",elected))}
}
    
# save votedata and result details countdata as elecdata in one list
countdata=list(sys="meek",elec=elected,itt=itt,narrative=txt,count=csum,quotatext=qtxt,va=va,keep=ks[1:nc,]*100)
elecdata=c(votedata,countdata)
report=stv.report(elecdata)
elecdata=c(elecdata,list(report=report))    # add report narrative

elecfile=paste(strsplit(elecname," ")[[1]],collapse="_")
save(elecdata,file=paste0(outdirec,"/",elecfile,"_",sys,".rda"))

# if plot=TRUE make webpages to go with vote plots,
#   and if interactive=TRUE display them
if(plot==TRUE){
 wp=webpages(elecdata,outdirec,map)
 if(interactive==TRUE){grDevices::dev.off()}
 if(webdisplay==TRUE){utils::browseURL(paste(outdirec,"index.html",sep="/"),browser="open")}
 }
elecdata
}
