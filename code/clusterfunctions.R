#' Parallel wrappers for Bayesian Additive Regression Trees (BART)
#'
#' These functions provide parallel implementations of the `lbart()` and
#' `wbart()` functions from the BART package. The original BART functions
#' generate posterior samples from a single MCMC chain. These wrappers allow
#' multiple independent MCMC chains to be run simultaneously on different CPU
#' cores and combine the posterior draws across chains.
#'
#' The `lbart` wrappers are designed for binary outcomes using latent-probit
#' BART models, while the `wbart` wrappers are designed for continuous outcomes
#' using Gaussian BART models.
#'
#' The returned posterior predictions are stored as three-dimensional arrays:
#'
#' \describe{
#'   \item{Dimension 1}{retained posterior draw after burn-in}
#'   \item{Dimension 2}{training or test observation}
#'   \item{Dimension 3}{MCMC chain}
#' }

## ---------------------------------------------------------------------------
## Binary outcome (logit link)
## ---------------------------------------------------------------------------

# Run one probit/logistic BART chain (lbart) with a specified random seed
lbart.clusterseed <- function(seed = NULL, x.train, y.train, x.test=matrix(0.0,0,0),
                              sparse=FALSE, a=0.5, b=1, augment=FALSE, rho=NULL,
                              xinfo=matrix(0.0,0,0), usequants=FALSE,
                              cont=FALSE, rm.const=TRUE, tau.interval=0.95,
                              k=2.0, power=2.0, base=.95,
                              binaryOffset=NULL,
                              ntree=200L, numcut=100L,
                              ndpost=1000L, nskip=100L,
                              keepevery=1L,
                              # nkeeptrain=ndpost, nkeeptest=ndpost,
                              # nkeeptestmean=ndpost, nkeeptreedraws=ndpost,
                              printevery=100, transposed=FALSE) {
  # set random seed
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  # run one BART chain
  BART::lbart(x.train=x.train, y.train=y.train, x.test=x.test,
        sparse=sparse, a=a, b=b, augment=augment, rho=rho,
        xinfo=xinfo, tau.interval=tau.interval,
        k=k, power=power, base=base,
        binaryOffset=binaryOffset,
        ntree=ntree, numcut=numcut,
        ndpost=ndpost, nskip=nskip, keepevery=keepevery,
        ## nkeeptrain=mc.nkeep, nkeeptest=mc.nkeep,
        ## nkeeptestmean=mc.nkeep, nkeeptreedraws=mc.nkeep,
        printevery=printevery, transposed=transposed)
}

#' Run multiple independent lbart MCMC chains in parallel.
#'
#' Each chain is assigned a different random seed and executed on a separate
#' CPU core. Posterior predictions from all chains are returned together.
lbart.cluster <- function(x.train, y.train, x.test=matrix(0.0,0,0),
                          sparse=FALSE, a=0.5, b=1, augment=FALSE, rho=NULL,
                          xinfo=matrix(0.0,0,0), usequants=FALSE,
                          cont=FALSE, rm.const=TRUE, tau.interval=0.95,
                          k=2.0, power=2.0, base=.95,
                          binaryOffset=NULL,
                          ntree=200L, numcut=100L,
                          ndpost=1000L, nskip=100L,
                          keepevery=1L,
                          ## Memory-management parameters: how many posterior draws to save 
                          # nkeeptrain=ndpost, nkeeptest=ndpost, nkeeptestmean=ndpost, nkeeptreedraws=ndpost,
                          printevery=100, transposed=FALSE, 
                          nchains = 2, # Number of independent MCMC chains to run in parallel
                          seed = NULL
                          ) {
  
  # Posterior fitted values for training observations (Dimension: ndpost × n_train × nchains)
  yhat.train.mat <- array(NA, dim = c(ndpost,
                                      dim(x.train)[transposed + 1], 
                                      nchains))
  # Posterior predictions for test observations (Dimension: ndpost × n_test × nchains)
  yhat.test.mat <- array(NA, dim = c(ndpost,
                                     dim(x.test)[transposed + 1], 
                                     nchains))
  
  cl <- parallel::makeCluster(nchains)
  on.exit(parallel::stopCluster(cl), add = TRUE, after = FALSE)
  
  # Set the seed before generating chain seeds
  if (!is.null(seed)) {
    set.seed(seed)
  }
  
  # Generate a seed for each chain
  seeds <- sample(1:10000, size = nchains) 
  print(seeds)
  
  # Run chains simultaneously
  res <- do.call(parallel::parLapply, list(X = seeds, cl = cl, fun = lbart.clusterseed,
                                        x.train=x.train, y.train=y.train, x.test=x.test,
                                        sparse=sparse, a=a, b=b, augment=augment, rho=rho,
                                        xinfo=xinfo, tau.interval=tau.interval,
                                        k=k, power=power, base=base,
                                        binaryOffset=binaryOffset,
                                        ntree=ntree, numcut=numcut,
                                        ndpost=ndpost, nskip=nskip, keepevery=keepevery,
                                        ## nkeeptrain=mc.nkeep, nkeeptest=mc.nkeep,
                                        ## nkeeptestmean=mc.nkeep, nkeeptreedraws=mc.nkeep,
                                        printevery=printevery, transposed=transposed))
  # Unpack
  for (i in 1:nchains) {
    currentchain <- res[[i]]
    yhat.train.mat[, , i] <- currentchain$yhat.train
    yhat.test.mat[, , i] <- currentchain$yhat.test
  }
  
  return(list("yhat.train" = yhat.train.mat, 
              "yhat.test" = yhat.test.mat))
  
}


## ---------------------------------------------------------------------------
## Continuous outcome (Gaussian)
## ---------------------------------------------------------------------------

# Run one Gaussian BART chain (wbart) with a specified random seed
wbart.clusterseed <- function(seed = NULL, x.train, y.train, x.test=matrix(0.0,0,0),
                              sparse=FALSE, theta=0, omega=1,
                              a=0.5, b=1, augment=FALSE, rho=NULL,
                              xinfo=matrix(0.0,0,0), usequants=FALSE,
                              cont=FALSE, rm.const=TRUE,
                              sigest=NA, sigdf=3, sigquant=.90,
                              k=2.0, power=2.0, base=.95,
                              sigmaf=NA, lambda=NA,
                              fmean=mean(y.train),
                              w=rep(1,length(y.train)),
                              ntree=200L, numcut=100L,
                              ndpost=1000L, nskip=100L, keepevery=1L,
                              # nkeeptrain=ndpost, nkeeptest=ndpost,
                              # nkeeptestmean=ndpost, nkeeptreedraws=ndpost,
                              printevery=100L, transposed=FALSE) {
  if (!is.null(seed)) {
    set.seed(seed)
  }
  BART::wbart(x.train=x.train, y.train=y.train, x.test=x.test,
        sparse=sparse, theta=theta, omega=omega,
        a=a, b=b, augment=augment, rho=rho,
        xinfo=xinfo,
        sigest=sigest, sigdf=sigdf, sigquant=sigquant,
        k=k, power=power, base=base,
        sigmaf=sigmaf, lambda=lambda, fmean=fmean, w=w,
        ntree=ntree, numcut=numcut,
        ndpost=ndpost, nskip=nskip, keepevery=keepevery,
        printevery=printevery, transposed=transposed)
}

#' Run multiple independent wbart MCMC chains in parallel.
#'
#' Posterior samples of predictions and residual standard deviations are
#' collected across chains and returned in array format.
wbart.cluster <- function(x.train, y.train, x.test=matrix(0.0,0,0),
                          sparse=FALSE, theta=0, omega=1,
                          a=0.5, b=1, augment=FALSE, rho=NULL,
                          xinfo=matrix(0.0,0,0), usequants=FALSE,
                          cont=FALSE, rm.const=TRUE,
                          sigest=NA, sigdf=3, sigquant=.90,
                          k=2.0, power=2.0, base=.95,
                          sigmaf=NA, lambda=NA,
                          fmean=mean(y.train),
                          w=rep(1,length(y.train)),
                          ntree=200L, numcut=100L,
                          ndpost=1000L, nskip=100L, keepevery=1L,
                          # nkeeptrain=ndpost, nkeeptest=ndpost,
                          # nkeeptestmean=ndpost, nkeeptreedraws=ndpost,
                          printevery=100L, transposed=FALSE, nchains = 2,
                          seed = NULL) {
  
  # For `wbart.cluster()`, posterior draws of the residual standard deviation
  # parameter `sigma` are also returned for all MCMC iterations. 
  # The dimension of `sigma` is:
  # MCMC iteration (including burn-in and intermediate iterations controlled by keepevery) X MCMC chain
  sigma.mat <- array(NA, dim = c(nskip + ndpost * keepevery, # all MCMC iterations
                                 nchains))
  
  yhat.train.mat <- array(NA, dim = c(ndpost, # retained posterior draws only
                                      dim(x.train)[transposed + 1], 
                                      nchains))
  yhat.test.mat <- array(NA, dim = c(ndpost,
                                     dim(x.test)[transposed + 1], 
                                     nchains))
  
  cl <- parallel::makeCluster(nchains)
  on.exit(parallel::stopCluster(cl), add = TRUE, after = FALSE)
  
  # Set the seed before generating chain seeds
  if (!is.null(seed)) {
    set.seed(seed)
  }
  seeds <- sample(1:10000, size = nchains)
  
  res <- do.call(parallel::parLapply, list(X = seeds, cl = cl, fun = wbart.clusterseed,
                                           x.train=x.train, y.train=y.train, x.test=x.test,
                                           sparse=sparse, theta=theta, omega=omega,
                                           a=a, b=b, augment=augment, rho=rho,
                                           xinfo=xinfo,
                                           sigest=sigest, sigdf=sigdf, sigquant=sigquant,
                                           k=k, power=power, base=base,
                                           sigmaf=sigmaf, lambda=lambda, fmean=fmean, w=w,
                                           ntree=ntree, numcut=numcut,
                                           ndpost=ndpost, nskip=nskip, keepevery=keepevery,
                                           printevery=printevery, transposed=transposed))
  # Unpack
  for (i in 1:nchains) {
    currentchain <- res[[i]]
    sigma.mat[, i] <- currentchain$sigma
    yhat.train.mat[, , i] <- currentchain$yhat.train
    yhat.test.mat[, , i] <- currentchain$yhat.test
  }

  
  return(list("sigma" = sigma.mat, 
              "yhat.train" = yhat.train.mat,
              "yhat.test" = yhat.test.mat))
  
}
