### Terrence D. Jorgensen & Yves Rosseel
### Last updated: 5 May 2018
### classic score test (= Lagrange Multiplier test)
### borrowed source code from lavaan/R/lav_test_score.R

## this function can run two modes:
## MODE 1: 'add'
##   add new parameters that are currently not included in de model
##   (aka fixed to zero), but should be released
## MODE 2: 'release' (the default)
##   release existing "==" constraints



#' Score Test for Multiple Imputations
#'
#' Score test (or Lagrange multiplier test) for lavaan models fitted to
#' multiple imputed data sets. Statistics for releasing one or more
#' fixed or constrained parameters in model can be calculated by pooling
#' the gradient and information matrices pooled across imputed data sets
#' using Rubin's (1987) rules, or by pooling the score test statistics
#' across imputed data sets (Li, Meng, Raghunathan, & Rubin, 1991).
#'
#' @aliases lavTestScore.mi
#' @importFrom lavaan lavListInspect parTable
#' @importFrom stats cov pchisq pf
#' @importFrom methods getMethod
#'
#' @param object An object of class \code{\linkS4class{lavaan}}.
#' @param add Either a \code{character} string (typically between single
#'  quotes) or a parameter table containing additional (currently fixed-to-zero)
#'  parameters for which the score test must be computed.
#' @param release Vector of \code{integer}s. The indices of the \emph{equality}
#'  constraints that should be released. The indices correspond to the order of
#'  the equality constraints as they appear in the parameter table.
#' @param type \code{character} indicating which pooling method to use.
#' \code{"Rubin"} indicates Rubin's (1987) rules will be applied to the
#'  gradient and information, and those pooled values will be used to
#'  calculate modification indices in the usual manner. \code{"D2"} (default),
#' \code{"LMRR"}, or \code{"Li.et.al"} indicate that modification indices
#'  calculated from each imputed data set will be pooled across imputations,
#'  as described in Li, Meng, Raghunathan, & Rubin (1991) and Enders (2010).
#' @param scale.W \code{logical}. If \code{FALSE} (default), the pooled
#'  information matrix is calculated as the weighted sum of the
#'  within-imputation and between-imputation components. Otherwise, the pooled
#'  information is calculated by scaling the within-imputation component by the
#'  average relative increase in variance (ARIV; see Enders, 2010, p. 235).
#'  Not recommended, and ignored (irrelevant) if \code{type = "D2"}.
#' @param asymptotic \code{logical}. If \code{FALSE} (default when using
#'  \code{add} to test adding fixed parameters to the model), the pooled test
#'  will be returned as an \emph{F}-distributed variable with numerator
#'  (\code{df1}) and denominator (\code{df2}) degrees of freedom.
#'  If \code{TRUE}, the pooled \emph{F} statistic will be multiplied by its
#'  \code{df1} on the assumption that its \code{df2} is sufficiently large
#'  enough that the statistic will be asymptotically \eqn{\chi^2} distributed
#'  with \code{df1}. When using the \code{release} argument, \code{asymptotic}
#'  will be set to \code{TRUE} because (A)RIV can only be calculated for
#'  \code{add}ed parameters.
#' @param univariate \code{logical}. If \code{TRUE}, compute the univariate
#'  score statistics, one for each constraint.
#' @param cumulative \code{logical}. If \code{TRUE}, order the univariate score
#'  statistics from large to small, and compute a series of multivariate
#'  score statistics, each time including an additional constraint in the test.
#' @param epc \code{logical}. If \code{TRUE}, and we are releasing existing
#'  constraints, compute the expected parameter changes for the existing (free)
#'  parameters (and any specified with \code{add}), if all constraints
#'  were released. For EPCs associated with a particular (1-\emph{df})
#'  constraint, only specify one parameter in \code{add} or one constraint in
#'  \code{release}.
#' @param verbose \code{logical}. Not used for now.
#' @param warn \code{logical}. If \code{TRUE}, print out warnings if they occur.
#'
#' @return
#'  A list containing at least one \code{data.frame}:
#'  \itemize{
#'    \item{\code{$test}: The total score test, with columns for the score
#'      test statistic (\code{X2}), the degrees of freedom (\code{df}), and
#'      a \emph{p} value under the \eqn{\chi^2} distribution (\code{p.value}).}
#'    \item{\code{$uni}: Optional (if \code{univariate=TRUE}).
#'      Each 1-\emph{df} score test, equivalent to modification indices.}
#'    \item{\code{$cumulative}: Optional (if \code{cumulative=TRUE}).
#'      Cumulative score tests.}
#'    \item{\code{$epc}: Optional (if \code{epc=TRUE}). Parameter estimates,
#'      expected parameter changes, and expected parameter values if all
#'      the tested constraints were freed.}
#'  }
#' See \code{\link[lavaan]{lavTestScore}} for details.
#'
#' @author
#'   Terrence D. Jorgensen (University of Amsterdam; \email{TJorgensen314@@gmail.com})
#'
#' Adapted from \pkg{lavaan} source code, written by
#'   Yves Rosseel (Ghent University; \email{Yves.Rosseel@@UGent.be})
#'
#' \code{type = "Rubin"} method proposed by
#'   Maxwell Mansolf (University of California, Los Angeles;
#'   \email{mamansolf@@gmail.com})
#'
#' @references
#' Bentler, P. M., & Chou, C.-P. (1992). Some new covariance structure model
#' improvement statistics. \emph{Sociological Methods & Research, 21}(2),
#' 259--282. doi:10.1177/0049124192021002006
#'
#' Enders, C. K. (2010). \emph{Applied missing data analysis}.
#' New York, NY: Guilford.
#'
#' Li, K.-H., Meng, X.-L., Raghunathan, T. E., & Rubin, D. B. (1991).
#' Significance levels from repeated \emph{p}-values with multiply-imputed data.
#' \emph{Statistica Sinica, 1}(1), 65--92. Retrieved from
#' \url{http://www.jstor.org/stable/24303994}
#'
#' Rubin, D. B. (1987). \emph{Multiple imputation for nonresponse in surveys}.
#' New York, NY: Wiley.
#'
#' @examples
#'  \dontrun{
#' ## impose missing data for example
#' HSMiss <- HolzingerSwineford1939[ , c(paste("x", 1:9, sep = ""),
#'                                       "ageyr","agemo","school")]
#' set.seed(12345)
#' HSMiss$x5 <- ifelse(HSMiss$x5 <= quantile(HSMiss$x5, .3), NA, HSMiss$x5)
#' age <- HSMiss$ageyr + HSMiss$agemo/12
#' HSMiss$x9 <- ifelse(age <= quantile(age, .3), NA, HSMiss$x9)
#'
#' ## impute missing data
#' library(Amelia)
#' set.seed(12345)
#' HS.amelia <- amelia(HSMiss, m = 20, noms = "school", p2s = FALSE)
#' imps <- HS.amelia$imputations
#'
#' ## specify CFA model from lavaan's ?cfa help page
#' HS.model <- '
#'   speed =~ c(L1, L1)*x7 + c(L1, L1)*x8 + c(L1, L1)*x9
#' '
#'
#' out <- cfa.mi(HS.model, data = imps, group = "school", std.lv = TRUE)
#'
#' ## Mode 1: Score test for releasing equality constraints
#'
#' ## default type: Li et al.'s (1991) "D2" method
#' lavTestScore.mi(out, cumulative = TRUE)
#' ## Rubin's rules
#' lavTestScore.mi(out, type = "Rubin")
#'
#' ## Mode 2: Score test for adding currently fixed-to-zero parameters
#' lavTestScore.mi(out, add = 'x7 ~~ x8 + x9')
#'
#' }
#'
#' @export
lavTestScore.mi <- function(object, add = NULL, release = NULL,
                            type = c("D2","Rubin"), scale.W = FALSE,
                            asymptotic = !is.null(add), # as F or chi-squared
                            univariate = TRUE, cumulative = FALSE,
                            #standardized = TRUE, #FIXME: add std.lv and std.all if(epc)?
                            epc = FALSE, verbose = FALSE, warn = TRUE) {
  stopifnot(inherits(object, "lavaan.mi"))
  lavoptions <- object@Options

  useSE <- sapply(object@convergence, "[[", i = "SE")
  useSE[is.na(useSE)] <- FALSE
  useImps <- useSE & sapply(object@convergence, "[[", i = "converged")
  m <- sum(useImps)
  type <- tolower(type[1])

  ## check if model has converged
  if (m == 0L) stop("No models converged. Score tests unavailable.")

  # check for inequality constraints
  PT <- parTable(object)
  if (any(PT$op == ">" | PT$op == "<")) {
    stop("lavTestScore.mi() does not handle inequality constraints (yet)")
  }

  # check arguments
  if (cumulative) univariate <- TRUE
  if (sum(is.null(release), is.null(add)) == 0) {
    stop("`add' and `release' arguments cannot be used together.\n",
         "Fixed parameters can instead be labeled in the model syntax ",
         "and those labels can be constrained to fixed values, so that ",
         "the constraints can be tested using the `release' argument along ",
         "with other released constraints.")
  }

  oldCall <- object@lavListCall
  #oldCall$model <- parTable(object) # FIXME: necessary?

  if (type == "d2") {
    if (!is.null(oldCall$parallel)) {
      if (oldCall$parallel == "snow") {
        oldCall$parallel <- "no"
        oldCall$ncpus <- 1L
        if (warn) warning("Unable to pass lavaan::lavTestScore() arguments ",
                          "when parallel='snow'. Switching to parallel='no'.",
                          " Unless using Windows, parallel='multicore' works.")
      }
    }

    ## call lavaanList() again to run lavTestScore() on each imputation
    oldCall$FUN <- function(obj) {
      out <- try(lavaan::lavTestScore(obj, add = add, release = release,
                                      cumulative = cumulative,
                                      univariate = univariate, epc = epc,
                                      warn = FALSE), silent = TRUE)
      if (inherits(out, "try-error")) return(NULL)
      out
    }
    FIT <- eval(as.call(oldCall))
    ## check if there are any results
    noScores <- sapply(FIT@funList, is.null)
    if (all(noScores)) stop("No success using lavTestScore() on any imputations.")

    ## template to fill in pooled values
    OUT <- FIT@funList[[ which(useImps & !noScores)[1] ]]

    ## at a minimum, pool the total score test
    chiList <- sapply(FIT@funList[useImps & !noScores], function(x) x$test$X2)
    chiPooled <- calculate.D2(chiList, DF = OUT$test$df, asymptotic)
    OUT$test$X2 <- chiPooled[1]
    if (!asymptotic) {
      names(OUT$test)[names(OUT$test) == "X2"] <- "F"
      names(OUT$test)[names(OUT$test) == "df"] <- "df1"
      OUT$test$df2 <- chiPooled[["df2"]]
      OUT$test$p.value <- NULL # so it appears after "df2" column
    }
    OUT$test$p.value <- chiPooled[["pvalue"]]

    ## univariate?
    if (univariate) {
      if (!asymptotic) {
        names(OUT$uni)[names(OUT$uni) == "X2"] <- "F"
        OUT$uni$p.value <- NULL # so it appears after "df2" column
        OUT$uni$df2 <- NA
        OUT$uni$p.value <- NA
      }
      for (i in 1:nrow(OUT$uni)) {
        chiList <- sapply(FIT@funList[useImps & !noScores],
                          function(x) x$uni$X2[i] )
        chiPooled <- calculate.D2(chiList, DF = OUT$uni$df[i], asymptotic)
        if (!asymptotic) {
          OUT$uni$F[i] <- chiPooled[[1]]
          OUT$uni$df2[i] <- chiPooled[["df2"]]
        } else OUT$uni$X2[i] <- chiPooled[[1]]
        OUT$uni$p.value[i] <- chiPooled[["pvalue"]]
      }
      if (!asymptotic) names(OUT$uni)[names(OUT$uni) == "df"] <- "df1"
    }

    ## cumulative?
    if (cumulative) {
      if (!asymptotic) {
        names(OUT$cumulative)[names(OUT$cumulative) == "X2"] <- "F"
        OUT$cumulative$p.value <- NULL # so it appears after "df2" column
        OUT$cumulative$df2 <- NA
        OUT$cumulative$p.value <- NA
      }
      for (i in 1:nrow(OUT$cumulative)) {
        chiList <- sapply(FIT@funList[useImps & !noScores],
                          function(x) x$cumulative$X2[i] )
        chiPooled <- calculate.D2(chiList, DF = OUT$cumulative$df[i], asymptotic)
        if (!asymptotic) {
          OUT$cumulative$F[i] <- chiPooled[[1]]
          OUT$cumulative$df2[i] <- chiPooled[["df2"]]
        } else OUT$cumulative$X2[i] <- chiPooled[[1]]
        OUT$cumulative$p.value[i] <- chiPooled[["pvalue"]]
      }
      if (!asymptotic) names(OUT$cumulative)[names(OUT$cumulative) == "df"] <- "df1"
    }

    ## EPCs?
    if (epc) {
      estList <- lapply(FIT@funList[useImps & !noScores],
                        function(x) x$epc$est)
      OUT$epc$est <- rowMeans(do.call(cbind, estList))

      epcList <- lapply(FIT@funList[useImps & !noScores],
                        function(x) x$epc$epc)
      OUT$epc$epc <- rowMeans(do.call(cbind, epcList))

      OUT$epc$epv <- OUT$epc$est + OUT$epc$epc
      #FIXME: if (standardized) repeat for std.lv and std.all
    }

    return(OUT)
  } # else type == "Rubin", making 'scale.W=' relevant

  ## number of free parameters (regardless of whether they are constrained)
  npar <- object@Model@nx.free
  ## sample size
  N <- lavListInspect(object, "ntotal")
  if (lavoptions$mimic == "EQS") N <- N - 1

  # Mode 1: ADDING new parameters
  if (!is.null(add) && nchar(add) > 0L) {
    ## turn off SNOW cluster (can't past arguments)
    if (!is.null(oldCall$parallel)) {
      if (oldCall$parallel == "snow") {
        oldCall$parallel <- "no"
        oldCall$ncpus <- 1L
        if (warn) warning("Unable to pass lavaan::lavTestScore() arguments ",
                          "when parallel='snow'. Switching to parallel='no'.",
                          " Unless using Windows, parallel='multicore' works.")
      }
    }

    ## call lavaanList() to fit augmented model (do.fit = FALSE)
    oldCall$FUN <- function(obj) {
      ngroups <- lavaan::lavInspect(obj, "ngroups")

      ## --------------------------------------
      ## borrowed code from lav_object_extend()
      ## --------------------------------------

      # partable original model
      oldPT <- lavaan::parTable(obj)[c("lhs","op","rhs","block","group",
                                       "free","label","plabel")]
      # replace 'start' column, since lav_model will fill these in in GLIST
      oldPT$start <- lavaan::parameterEstimates(obj, remove.system.eq = FALSE,
                                                remove.def = FALSE,
                                                remove.eq = FALSE,
                                                remove.ineq = FALSE)$est

      # add new parameters, extend model
      myCols <- c("lhs","op","rhs")
      if (ngroups > 1L) myCols <- c(myCols,"block","group")
      # ADD <- lavaan::modindices(obj, standardized = FALSE)[myCols]
      if (is.list(add)) {
        stopifnot(!is.null(add$lhs),
                  !is.null(add$op),
                  !is.null(add$rhs))
        ADD <- as.data.frame(add)
      } else if (is.character(add)) {
        ADD <- lavaan::lavaanify(add, ngroups = ngroups)
        ADD <- ADD[,c("lhs","op","rhs","block","user","label")]
        remove.idx <- which(ADD$user == 0)
        if (length(remove.idx) > 0L) {
          ADD <- ADD[-remove.idx,]
        }
        ADD$start <- rep( 0, nrow(ADD))
        ADD$free  <- rep( 1, nrow(ADD))
        ADD$user  <- rep(10, nrow(ADD))
      } else stop("'add' must be lavaan model syntax or a parameter table.")
      # nR <- try(nrow(ADD), silent = TRUE)
      # if (class(nR) == "try-error" || is.null(nR)) return(list(gradient = NULL,
      #                                                          information = NULL))
      # ADD$free <- rep(1L, nR)
      # ADD$user <- rep(10L, nR)

      # merge
      LIST <- lavaan::lav_partable_merge(oldPT, ADD, remove.duplicated = TRUE, warn = FALSE)
      # redo 'free'
      free.idx <- which(LIST$free > 0)
      LIST$free[free.idx] <- 1:length(free.idx)
      # adapt options
      lavoptions <- obj@Options
      if (any(LIST$op == "~1")) lavoptions$meanstructure <- TRUE
      lavoptions$do.fit <- FALSE

      obj2 <- lavaan::lavaan(LIST,
                             slotOptions     = lavoptions,
                             slotSampleStats = obj@SampleStats,
                             slotData        = obj@Data,
                             slotCache       = obj@Cache,
                             sloth1          = obj@h1)
      ## ---------------------------------
      list(gradient = lavaan::lavInspect(obj2, "gradient"),
           information = lavaan::lavInspect(obj2, "information"),
           nadd = nrow(ADD), parTable = lavaan::parTable(obj2))
    }
    FIT <- eval(as.call(oldCall))

    ## pool gradients and information matrices
    gradList <- lapply(FIT@funList[useImps], "[[", i = "gradient")
    infoList <- lapply(FIT@funList[useImps], "[[", i = "information")
    score <- colMeans(do.call(rbind, gradList))  # pooled point estimates
    B <- cov(do.call(rbind, gradList) * sqrt(N)) # between-imputation UNIT information
    W <- Reduce("+", infoList) / m               # within-imputation UNIT information
    inv.W <- try(solve(W), silent = TRUE)
    if (inherits(inv.W, "try-error")) {
      if (warn && scale.W) warning("Could not invert W for total score test, ",
                                   "perhaps due to constraints on estimated ",
                                   "parameters. Generalized inverse used instead.\n",
                                   "If the model does not have equality constraints, ",
                                   "it may be safer to set `scale.W = FALSE'.")
      inv.W <- MASS::ginv(W)
    }
    ## relative increase in variance due to missing data
    ariv <- (1 + 1/m)/nrow(B) * sum(diag(B %*% inv.W))

    if (scale.W) {
      information <- (1 + ariv) * W  # Enders (2010, p. 235) eqs. 8.20-21
    } else {
      ## less reliable, but constraints prevent inversion of W
      information <- W + B + (1/m)*B  # Enders (2010, p. 235) eq. 8.19
    }

    ## obtain list of inverted Jacobians: within-impuation covariance matrices
    R.model <- object@Model@con.jac[,,drop = FALSE]
    nadd <- FIT@funList[[ which(useImps)[1] ]]$nadd
    if (nrow(R.model) > 0L) {
      R.model <- cbind(R.model, matrix(0, nrow(R.model), ncol = nadd))
      R.add   <- cbind(matrix(0, nrow = nadd, ncol = npar), diag(nadd))
      R       <- rbind(R.model, R.add)

      Z <- cbind(rbind(information, R.model),
                 rbind(t(R.model),matrix(0,nrow(R.model),nrow(R.model))))
      Z.plus <- MASS::ginv(Z)
      J.inv  <- Z.plus[ 1:nrow(information), 1:nrow(information) ]

      r.idx <- seq_len(nadd) + nrow(R.model)
    } else {
      R <- cbind(matrix(0, nrow = nadd, ncol = npar), diag(nadd))
      J.inv <- MASS::ginv(information)

      r.idx <- seq_len(nadd)
    }

    PT <- FIT@funList[[ which(useImps)[1] ]]$parTable
    PT$group <- PT$block
    # lhs/rhs
    lhs <- lavaan::lav_partable_labels(PT)[ PT$user == 10L ]
    op <- rep("==", nadd)
    rhs <- rep("0", nadd)
    Table <- data.frame(lhs = lhs, op = op, rhs = rhs)
    class(Table) <- c("lavaan.data.frame", "data.frame")
  } else {
    # MODE 2: releasing constraints
    if (!asymptotic) {
      message('The average relative increase in variance (ARIV) cannot be ',
              'calculated for releasing estimated constraints, preventing the ',
              'denominator degrees of freedom from being calculated for the F ',
              'test, so the "asymptotic" argument was switched to TRUE.' )
      asymptotic <- TRUE
    }
    if (is.character(release)) stop("not implemented yet") #FIXME: moved up to save time
    R <- object@Model@con.jac[,,drop = FALSE]
    if (nrow(R) == 0L) stop("No equality constraints found in the model.")


    ## use lavaanList() to get gradient/information from each imputation
    oldCall$FUN <- function(obj) {
      list(gradient = lavaan::lavInspect(obj, "gradient"),
           information = lavaan::lavInspect(obj, "information"))
    }
    FIT <- eval(as.call(oldCall))
    ## pool gradients and information matrices
    gradList <- lapply(FIT@funList[useImps], "[[", i = "gradient")
    infoList <- lapply(FIT@funList[useImps], "[[", i = "information")
    score <- colMeans(do.call(rbind, gradList))  # pooled point estimates
    B <- cov(do.call(rbind, gradList) * sqrt(N)) # between-imputation UNIT information
    W <- Reduce("+", infoList) / m               # within-imputation UNIT information
    inv.W <- try(solve(W), silent = TRUE)
    if (inherits(inv.W, "try-error")) {
      if (warn && scale.W) warning("Could not invert W for total score test, ",
                                   "perhaps due to constraints on estimated ",
                                   "parameters. Generalized inverse used instead.\n",
                                   "If the model does not have equality constraints, ",
                                   "it may be safer to set `scale.W = FALSE'.")
      inv.W <- MASS::ginv(W)
    }
    ## relative increase in variance due to missing data
    ariv <- (1 + 1/m)/nrow(B) * sum(diag(B %*% inv.W))
    if (scale.W) {
      information <- (1 + ariv) * W  # Enders (2010, p. 235) eqs. 8.20-21
    } else {
      ## less reliable, but constraints prevent inversion of W
      information <- W + B + (1/m)*B  # Enders (2010, p. 235) eq. 8.19
    }

    if (is.null(release)) {
      # ALL constraints
      r.idx <- seq_len( nrow(R) )
      J.inv <- MASS::ginv(information) #FIXME? Yves has this above if(is.null(release))
    } else if (is.numeric(release)) {
      r.idx <- release
      if(max(r.idx) > nrow(R)) {
        stop("lavaan ERROR: maximum constraint number (", max(r.idx),
             ") is larger than number of constraints (", nrow(R), ")")
      }

      # neutralize the non-needed constraints
      R1 <- R[-r.idx, , drop = FALSE]
      Z1 <- cbind( rbind(information, R1),
                   rbind(t(R1), matrix(0, nrow(R1), nrow(R1))) )
      Z1.plus <- MASS::ginv(Z1)
      J.inv <- Z1.plus[ 1:nrow(information), 1:nrow(information) ]
    } else if (is.character(release)) {
      stop("not implemented yet")
    }


    # lhs/rhs
    eq.idx <- which(object@ParTable$op == "==")
    if (length(eq.idx) > 0L) {
      lhs <- object@ParTable$lhs[eq.idx][r.idx]
      op <- rep("==", length(r.idx))
      rhs <- object@ParTable$rhs[eq.idx][r.idx]
    }
    Table <- data.frame(lhs = lhs, op = op, rhs = rhs)
    class(Table) <- c("lavaan.data.frame", "data.frame")
  }

  if (lavoptions$se == "standard") {
    stat <- as.numeric(N * score %*% J.inv %*% score)
  } else {
    # generalized score test
    if (warn) warning("se is not `standard'. Robust test not implemented yet. ",
                      "Falling back to ordinary score test.")
    # NOTE!!!
    # we can NOT use VCOV here, because it reflects the constraints,
    # and the whole point is to test for these constraints...

    stat <- as.numeric(N * score %*% J.inv %*% score)
  }

  # compute df, taking into account that some of the constraints may
  # be needed to identify the model (and hence information is singular)
  # information.plus <- information + crossprod(R)
  #df <- qr(R[r.idx,,drop = FALSE])$rank +
  #          ( qr(information)$rank - qr(information.plus)$rank )
  DF <- nrow( R[r.idx, , drop = FALSE] )
  if (asymptotic) {
    TEST <- data.frame(test = "score", X2 = stat*DF, df = DF,
                       p.value = pchisq(stat*DF, df = DF, lower.tail = FALSE))
  } else {
    ## calculate denominator DF for F statistic
    myDims <- 1:nadd + npar
    ARIV <- (1 + 1/m)/nadd * sum(diag(B[myDims, myDims, drop = FALSE] %*% inv.W[myDims, myDims, drop = FALSE]))
    a <- DF*(m - 1)
    if (a > 4) {
      df2 <- 4 + (a - 4) * (1 + (1 - 2/a)*(1 / ARIV))^2 # Enders (eq. 8.24)
    } else {
      df2 <- a*(1 + 1/DF) * (1 + 1/ARIV)^2 / 2 # Enders (eq. 8.25)
    }
    TEST <- data.frame(test = "score", "F" = stat, df1 = DF, df2 = df2,
                       p.value = pf(stat, df1 = DF, df2 = df2, lower.tail = FALSE))
  }
  class(TEST) <- c("lavaan.data.frame", "data.frame")
  attr(TEST, "header") <- "total score test:"
  OUT <- list(test = TEST)

  if (univariate) {
    TS <- numeric( nrow(R) )
    for (r in r.idx) {
      R1 <- R[-r, , drop = FALSE]
      Z1 <- cbind( rbind(information, R1),
                   rbind(t(R1), matrix(0, nrow(R1), nrow(R1))) )
      Z1.plus <- MASS::ginv(Z1)
      Z1.plus1 <- Z1.plus[ 1:nrow(information), 1:nrow(information) ]
      TS[r] <- as.numeric(N * t(score) %*%  Z1.plus1 %*% score)
    }

    Table2 <- Table
    DF <- rep(1, length(r.idx))

    if (asymptotic) {
      Table2$X2 <- TS[r.idx] * DF
      Table2$df <- DF
      Table2$p.value <- pchisq(Table2$X2, df = DF, lower.tail = FALSE)
    } else {
      Table2$F <- TS[r.idx]
      Table2$df1 <- DF
      ## calculate denominator DF for F statistic using RIV per 1-df test (Enders eq. 8.10)
      myDims <- 1:nadd + npar
      RIVs <- diag((1 + 1/m) * B[myDims, myDims, drop = FALSE]) / diag(W[myDims, myDims, drop = FALSE])
      Table2$df2 <- sapply(RIVs, function(riv) {
        DF1 <- 1L # Univariate tests
        a <- DF1*(m - 1)
        DF2 <- if (a > 4) {
          4 + (a - 4) * (1 + (1 - 2/a)*(1 / riv))^2 # Enders (eq. 8.24)
        } else a*(1 + 1/DF1) * (1 + 1/riv)^2 / 2 # Enders (eq. 8.25)
        DF2
      })
      Table2$p.value = pf(Table2$F, df1 = DF, df2 = Table2$df2, lower.tail = FALSE)
    }
    attr(Table2, "header") <- "univariate score tests:"
    OUT$uni <- Table2
  }

  if (cumulative) {
    TS.order <- sort.int(TS, index.return = TRUE, decreasing = TRUE)$ix
    TS <- numeric( length(r.idx) )
    if (!asymptotic) ARIVs <- numeric( length(r.idx) )
    for (r in 1:length(r.idx)) {
      rcumul.idx <- TS.order[1:r]

      R1 <- R[-rcumul.idx, , drop = FALSE]
      Z1 <- cbind( rbind(information, R1),
                   rbind(t(R1), matrix(0, nrow(R1), nrow(R1))) )
      Z1.plus <- MASS::ginv(Z1)
      Z1.plus1 <- Z1.plus[ 1:nrow(information), 1:nrow(information) ]
      TS[r] <- as.numeric(N * t(score) %*%  Z1.plus1 %*% score)
      if (!asymptotic) {
        myDims <- rcumul.idx + npar
        ARIVs[r] <- (1 + 1/m)/length(myDims) * sum(diag(B[myDims, myDims, drop = FALSE] %*% inv.W[myDims, myDims, drop = FALSE]))
      }
    }

    Table3 <- Table
    DF <- seq_len( length(TS) )
    if (asymptotic) {
      Table3$X2 <- TS * DF
      Table3$df <- DF
      Table3$p.value <- pchisq(Table3$X2, df = DF, lower.tail = FALSE)
    } else {
      Table3$F <- TS
      Table3$df1 <- DF
      ## calculate denominator DF for F statistic
      Table3$df2 <- mapply(FUN = function(DF1, ariv) {
        a <- DF1*(m - 1)
        DF2 <- if (a > 4) {
          4 + (a - 4) * (1 + (1 - 2/a)*(1 / ariv))^2 # Enders (eq. 8.24)
        } else a*(1 + 1/DF1) * (1 + 1/ariv)^2 / 2 # Enders (eq. 8.25)
        DF2
      }, DF1 = DF, ariv = ARIVs)
      Table3$p.value = pf(Table3$F, df1 = DF, df2 = Table3$df2, lower.tail = FALSE)
    }
    attr(Table3, "header") <- "cumulative score tests:"
    OUT$cumulative <- Table3
  }

  if (epc) {
    ################# source code Yves commented out.
    ################# Calculates 1 EPC-vector per constraint.
    ################# Better to call lavTestScore() multiple times?  Ugh...
    # EPC <- vector("list", length = length(r.idx))
    # for (i in 1:length(r.idx)) {
    #     r <- r.idx[i]
    #     R1 <- R[-r,,drop = FALSE]
    #     Z1 <- cbind( rbind(information, R1),
    #                  rbind(t(R1), matrix(0,nrow(R1),nrow(R1))) )
    #     Z1.plus <- MASS::ginv(Z1)
    #     Z1.plus1 <- Z1.plus[ 1:nrow(information), 1:nrow(information) ]
    #     EPC[[i]] <- -1 * as.numeric(score %*%  Z1.plus1)
    # }
    # OUT$EPC <- EPC

    # EPCs when freeing all constraints together (total test)
    R1 <- R[-r.idx, , drop = FALSE]
    Z1 <- cbind( rbind(information, R1),
                 rbind(t(R1), matrix(0, nrow(R1), nrow(R1))) )
    Z1.plus <- MASS::ginv(Z1)
    Z1.plus1 <- Z1.plus[ 1:nrow(information), 1:nrow(information) ]
    EPC.all <- -1 * as.numeric(score %*%  Z1.plus1)

    # create epc table for the 'free' parameters
    myCoefs <- getMethod("coef","lavaan.mi")(object)
    myCols <- c("lhs","op","rhs","group","user","free","label","plabel")
    LIST <- if (!is.null(add) && nchar(add) > 0L) {
      PT[ , myCols]
    } else parTable(object)[ , myCols]

    if (lavListInspect(object, "ngroups") == 1L) LIST$group <- NULL
    nonpar.idx <- which(LIST$op %in% c("==", ":=", "<", ">"))
    if (length(nonpar.idx) > 0L) LIST <- LIST[ -nonpar.idx , ]

    LIST$est[ LIST$free > 0 & LIST$user != 10 ] <- myCoefs
    LIST$est[ LIST$user == 10L ] <- 0
    LIST$epc <- rep(as.numeric(NA), length(LIST$lhs))
    LIST$epc[ LIST$free > 0 ] <- EPC.all
    LIST$epv <- LIST$est + LIST$epc
    LIST$free[ LIST$user == 10L ] <- 0
    LIST$user <- NULL

    DF <- if (asymptotic) OUT$test$df else OUT$test$df1
    attr(LIST, "header") <- paste0("expected parameter changes (epc) and ",
                                   "expected parameter values (epv)",
                                   if (DF < 2) ":" else {
                  " if ALL constraints in 'add' or 'release' were freed:" })

    OUT$epc <- LIST
  }

  OUT
}
