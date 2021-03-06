% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/runMI-modification.R
\name{modindices.mi}
\alias{modindices.mi}
\alias{modificationIndices.mi}
\alias{modificationindices.mi}
\title{Modification Indices for Multiple Imputations}
\usage{
modindices.mi(object, type = c("D2", "Rubin"), standardized = TRUE,
  cov.std = TRUE, power = FALSE, delta = 0.1, alpha = 0.05,
  high.power = 0.75, sort. = FALSE, minimum.value = 0,
  maximum.number = nrow(LIST), na.remove = TRUE, op = NULL)
}
\arguments{
\item{object}{An object of class \code{\linkS4class{lavaan.mi}}}

\item{type}{\code{character} indicating which pooling method to use.
\code{type = "Rubin"} currently unavailable. \code{type = "D2"} (default),
\code{"LMRR"}, or \code{"Li.et.al"} indicate that modification indices
calculated from each imputed data set will be pooled across imputations,
as described in Li, Meng, Raghunathan, & Rubin (1991) and Enders (2010).}

\item{standardized}{\code{logical}. If \code{TRUE}, two extra columns
(\code{$sepc.lv} and \code{$sepc.all}) will contain standardized values for
the EPCs. In the first column (\code{$sepc.lv}), standardizization is based
on the variances of the (continuous) latent variables. In the second column
(\code{$sepc.all}), standardization is based on both the variances of both
(continuous) observed and latent variables. (Residual) covariances are
standardized using (residual) variances.}

\item{cov.std}{\code{logical}. \code{TRUE} if \code{type == "D2"}.
If \code{TRUE} (default), the (residual)
observed covariances are scaled by the square-root of the diagonal elements
of the \eqn{\Theta} matrix, and the (residual) latent covariances are
scaled by the square-root of the diagonal elements of the \eqn{\Psi}
matrix. If \code{FALSE}, the (residual) observed covariances are scaled by
the square-root of the diagonal elements of the model-implied covariance
matrix of observed variables (\eqn{\Sigma}), and the (residual) latent
covariances are scaled by the square-root of the diagonal elements of the
model-implied covariance matrix of the latent variables.}

\item{power}{\code{logical}. If \code{TRUE}, the (post-hoc) power is
computed for each modification index, using the values of \code{delta}
and \code{alpha}.}

\item{delta}{The value of the effect size, as used in the post-hoc power
computation, currently using the unstandardized metric of the \code{$epc}
column.}

\item{alpha}{The significance level used for deciding if the modification
index is statistically significant or not.}

\item{high.power}{If the computed power is higher than this cutoff value,
the power is considered 'high'. If not, the power is considered 'low'.
This affects the values in the \code{$decision} column in the output.}

\item{sort.}{\code{logical}. If \code{TRUE}, sort the output using the
values of the modification index values. Higher values appear first.}

\item{minimum.value}{\code{numeric}. Filter output and only show rows with a
modification index value equal or higher than this minimum value.}

\item{maximum.number}{\code{integer}. Filter output and only show the first
maximum number rows. Most useful when combined with the \code{sort.} option.}

\item{na.remove}{\code{logical}. If \code{TRUE} (default), filter output by
removing all rows with \code{NA} values for the modification indices.}

\item{op}{\code{character} string. Filter the output by selecting only those
rows with operator \code{op}.}
}
\value{
A \code{data.frame} containing modification indices and (S)EPCs.
}
\description{
Modification indices (1-\emph{df} Lagrange multiplier tests) from a
latent variable model fitted to multiple imputed data sets. Statistics
for releasing one or more fixed or constrained parameters in model can
be calculated by pooling the gradient and information matrices
across imputed data sets using Rubin's (1987) rules, or by pooling the
test statistics across imputed data sets (Li, Meng, Raghunathan, &
Rubin, 1991).
}
\note{
When \code{type = "D2"}, each (S)EPC will be pooled by taking its
 average across imputations. When \code{type = "Rubin"}, EPCs will be
 calculated in the standard way using the pooled gradient and information,
 and SEPCs will be calculated by standardizing the EPCs using model-implied
 (residual) variances.
}
\examples{
 \dontrun{
## impose missing data for example
HSMiss <- HolzingerSwineford1939[ , c(paste("x", 1:9, sep = ""),
                                      "ageyr","agemo","school")]
set.seed(12345)
HSMiss$x5 <- ifelse(HSMiss$x5 <= quantile(HSMiss$x5, .3), NA, HSMiss$x5)
age <- HSMiss$ageyr + HSMiss$agemo/12
HSMiss$x9 <- ifelse(age <= quantile(age, .3), NA, HSMiss$x9)

## impute missing data
library(Amelia)
set.seed(12345)
HS.amelia <- amelia(HSMiss, m = 20, noms = "school", p2s = FALSE)
imps <- HS.amelia$imputations

## specify CFA model from lavaan's ?cfa help page
HS.model <- '
  visual  =~ x1 + x2 + x3
  textual =~ x4 + x5 + x6
  speed   =~ x7 + x8 + x9
'

out <- cfa.mi(HS.model, data = imps)

modindices.mi(out) # default: Li et al.'s (1991) "D2" method
modindices.mi(out, type = "Rubin") # Rubin's rules

}

}
\references{
Enders, C. K. (2010). \emph{Applied missing data analysis}.
New York, NY: Guilford.

Li, K.-H., Meng, X.-L., Raghunathan, T. E., & Rubin, D. B. (1991).
Significance levels from repeated \emph{p}-values with multiply-imputed data.
\emph{Statistica Sinica, 1}(1), 65--92. Retrieved from
\url{http://www.jstor.org/stable/24303994}

Rubin, D. B. (1987). \emph{Multiple imputation for nonresponse in surveys}.
New York, NY: Wiley.
}
\author{
Terrence D. Jorgensen (University of Amsterdam; \email{TJorgensen314@gmail.com})

Adapted from \pkg{lavaan} source code, written by
  Yves Rosseel (Ghent University; \email{Yves.Rosseel@UGent.be})

\code{type = "Rubin"} method proposed by
  Maxwell Mansolf (University of California, Los Angeles;
  \email{mamansolf@gmail.com})
}
