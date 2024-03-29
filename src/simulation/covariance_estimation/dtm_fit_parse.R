#!/usr/bin/env Rscript

library(GetoptLong,quietly = T)
library(mvtnorm,quietly = T)
library(LTN,quietly = T)
niter=10000
nmc=10^6
GetoptLong(
  "SEED=i","random seed of simulation.",
  "niter=i","number of Gibbs iterations.",
  "nmc=i","number of MC samples in estimating clr covariance.",
  "lambda=f","lambda, 0 represents Gamma prior on it.",
  "WORK_DIR=s","working directory."
)
i=SEED
if (lambda==0){
  lambda='hp'
}
filenam=paste0('i',i,'lambda',lambda,'.RData')
#source(paste0(WORK_DIR,"/src/utility/utility.R"))
#source(paste0(WORK_DIR,"/src/experiments/covariance_estimation/gibbs.R"))
result_dir=paste0(WORK_DIR,"/cache/covariance_estimation/dtm/ltn/")
system(paste0('mkdir -p ',result_dir))
datadir=paste0(WORK_DIR,'/cache/covariance_estimation/dtm/')
if (!file.exists(paste0(result_dir,filenam))){
  input_data=readRDS(paste0(WORK_DIR,"/cache/ps_sim.RData"))
  tree=input_data$tree
  dat_i=readRDS(paste0(datadir,'sim',i,'.RData'))
  yyl=dat_i[1:2]
  Y=yyl$Y
  YL=yyl$YL
  N=nrow(Y)
  p=ncol(Y)
  K=p+1
  S=1
  st1<-system.time(t<-try(gibbs1<-gibbs_ltn(niter=niter,YL=YL,Y=Y,S=1,lambda=lambda)))
  while("try-error" %in% class(t)) {
    S=S+1
    warning('error')
    t<-try(gibbs1<-gibbs_ltn(niter=niter,YL=YL,Y=Y,SEED=S,lambda=lambda))
  }
  samp_seq=ceiling(niter/2):niter
  MU=gibbs1$MU
  OMEGA=gibbs1$OMEGA
  mu=apply(MU[,samp_seq],1,mean)
  omega=Reduce('+',OMEGA[samp_seq])/length(OMEGA[samp_seq])
  sigma=solve(omega)
  rm(gibbs1)
  st2<-system.time(clrcov_ltn<-clrcov_sim_log(mu,sigma,tree,nmc,F,NULL))
  if (sum(is.na(clrcov_ltn))+sum(is.infinite(clrcov_ltn))==0){
    saveRDS(clrcov_ltn,paste0(result_dir,filenam))
  } else {
    warning('NA or Inf in clrcov')
  }
}


