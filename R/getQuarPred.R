## This program includes two methods for 10-day ahead predictions of on-campus quarantine counts 

#' --------------------------------------------------------------------
#' Data needed for method (i): the daily counts of the newly quarantined on-campus students and an indication of whether the diagnosed close contact(s) was living on-campus or off-campus,
#' and the daily counts of newly diagnosed on-campus and off-campus individuals.
#' 
#' @param quar_past - data frame with quar_past$oncampus contains the total number of on-campus quarantined students who had on-campus index cases in the past,
#'  and quar_past$offcampus contains the total number of on-campus quarantined students who had off-campus index cases in the past.
#' @param diagnosed_past - data frame with diagnosed_past$oncampus contains the total number of on-campus diagnosed students in the past,
#' and diagnosed_past$offcampus contains the total number of off-campus diagnosed students in the past.
#' @param diagnosed_pred - data frame with diagnosed_pred$oncampus contains the predicted number of on-campus diagnosed students in the next 10 days,
#' and diagnosed_pred$offcampus contains the predicted number of off-campus diagnosed students in the next 10 days.
#' @param ci_levl - a  number between 0 and 1 giving confidence level for the prediction of on-campus quarantine counts.
#' @param n_samp  - an integer giving the number of random values generated for calculation of confidence interval of quarantine prediction.  
#' @return quar_pred - a vector which contains the predicted number of on-campus quarantine counts in 10 days, and its estimated confidence interval.

getQuarPred_v1 <- function(quar_past,diagnosed_past,diagnosed_pred,ci_level,n_samp)
{
  ratio <- c(quar_past$oncampus/diagnosed_past$oncampus,quar_past$offcampus/diagnosed_past$offcampus)
  quar_pred_oncampus <- sum(ratio*c( diagnosed_pred$oncampus, diagnosed_pred$offcampus))
  samp_oncampus <- replicate(n_samp,sum(rpois(rpois(1,diagnosed_pred$oncampus) ,ratio[1])) ) +replicate(n_samp,sum(rpois(rpois(1,diagnosed_pred$offcampus),ratio[2])) )
  ci_oncampus <- quantile(samp_oncampus,prob=c((1-ci_level)/2, 1-(1-ci_level)/2))
  quar_pred <- c( quar_pred_oncampus,ci_oncampus )
  return(quar_pred)
}

#' --------------------------------------------------------------------
#' Data needed for method (ii): the daily counts of the newly quarantined on-campus students, newly diagnosed on-campus and off-campus individuals.
#' 
#' @param quar_past - data frame with quar_past$oncampus contains daily counts of the newly quarantined on-campus students in the past.
#' @param diagnosed_past - data frame with diagnosed_past$oncampus contains daily counts of the newly diagnosed on-campus students in the past,
#' and diagnosed_past$offcampus contains daily counts of the newly diagnosed off-campus students in the past.
#' @param diagnosed_pred - data frame with diagnosed_pred$oncampus contains the predicted number of diagnosed on-campus students in the next 10 days,
#' and diagnosed_pred$offcampus contains the predicted number of diagnosed off-campus students in the next 10 days.
#' @param ci_levl - a  number between 0 and 1 giving confidence level for the prediction of on-campus quarantine counts.
#' @param n_samp  - an integer giving the number of random values generated for calculation of confidence interval of quarantine prediction.  
#' @return quar_pred - a vector which contains the predicted number of on-campus quarantine counts in 10 days, and its estimated confidence interval.

getQuarPred_v2 <- function(quar_past,diagnosed_past,diagnosed_pred,ci_level,n_samp)
{
  ratio <- chol2inv(chol( t(as.matrix(diagnosed_past)) %*% as.matrix(diagnosed_past) )) %*% t(as.matrix(diagnosed_past)) %*% as.matrix(quar_past)
  quar_pred_oncampus <- sum(ratio*c( diagnosed_pred$oncampus, diagnosed_pred$offcampus))
  samp_oncampus <- replicate(n_samp,sum(rpois(rpois(1,diagnosed_pred$oncampus) ,ratio[1])) ) +replicate(n_samp,sum(rpois(rpois(1,diagnosed_pred$offcampus),ratio[2])) )
  ci_oncampus <- quantile(samp_oncampus,prob=c((1-ci_level)/2, 1-(1-ci_level)/2))
  quar_pred <- c( quar_pred_oncampus,ci_oncampus )
  return(quar_pred)
}