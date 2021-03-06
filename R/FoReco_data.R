#' Forecast reconciliation for a simulated hierarchical time series
#'
#' A two-level hierarchy with \code{n = 8} monthly time series. In the cross-sectional framework,
#' at any time it is \code{Tot = A + B + C}, \code{A = AA + AB} and \code{B = BA + BB} (\code{nb = 5}  at the
#' bottom level). For monthly data, the observations are aggregated to annual (\code{k = 12}),
#' semi-annual (\code{k = 6}), four-monthly (\code{k = 4}), quarterly (\code{k = 3}), and
#' bi-monthly (\code{k = 2}) observations. The monthly bottom time series are simulated
#' from five different SARIMA models (see
#' \href{https://danigiro.github.io/FoReco/articles/FoReco_package.html}{\code{Using the `FoReco` package}}).
#' There are 180 (15 years) monthly observations: the first 168 values (14 years) are used as
#' training set, and the last 12 form the test set.
#'
#' @docType data
#'
#' @usage data(FoReco_data)
#'
#' @format An object of class \code{"list"}:
#' \describe{
#'   \item{base}{(\code{8 x 28}) matrix of base forecasts. Each row identifies a time series and the forecasts
#' are ordered as [lowest_freq' ...  highest_freq']'.}
#'   \item{test}{(\code{8 x 28}) matrix of test set. Each row identifies a time series and the observed values
#' are ordered as [lowest_freq' ...  highest_freq']'.}
#'   \item{res}{(\code{8 x 392}) matrix of in-sample residuals. Each row identifies a time series and the in-sample residuals
#' are ordered as [lowest_freq' ...  highest_freq']'.}
#'   \item{C}{(\code{3 x 5}) cross-sectional (contemporaneous) aggregation matrix.}
#'   \item{obs}{List of the observations at any levels and temporal frequencies.}
#' }
#'
#' @examples
#' \donttest{
#' data(FoReco_data)
#' # Cross-sectional reconciliation for all temporal aggregation levels
#' # (monthly, bi-monthly, ..., annual)
#' K <- c(1,2,3,4,6,12)
#' hts_recf <- NULL
#' for(i in 1:length(K)){
#'   # base forecasts
#'   id <- which(simplify2array(strsplit(colnames(FoReco_data$base),
#'                                       split = "_"))[1, ] == paste("k", K[i], sep=""))
#'   mbase <- t(FoReco_data$base[, id])
#'   # residuals
#'   id <- which(simplify2array(strsplit(colnames(FoReco_data$res),
#'                                       split = "_"))[1, ] == "k1")
#'   mres <- t(FoReco_data$res[, id])
#'   hts_recf[[i]] <- htsrec(mbase, C = FoReco_data$C, comb = "shr",
#'                           res = mres, keep = "recf")
#' }
#' names(hts_recf) <- paste("k", K, sep="")
#'
#' # Forecast reconciliation through temporal hierarchies for all time series
#' n <- NROW(FoReco_data$base)
#' thf_recf <- matrix(NA, n, NCOL(FoReco_data$base))
#' dimnames(thf_recf) <- dimnames(FoReco_data$base)
#' for(i in 1:n){
#'   # ts base forecasts ([lowest_freq' ...  highest_freq']')
#'   tsbase <- FoReco_data$base[i, ]
#'   # ts residuals ([lowest_freq' ...  highest_freq']')
#'   tsres <- FoReco_data$res[i, ]
#'   thf_recf[i,] <- thfrec(tsbase, m = 12, comb = "acov",
#'                          res = tsres, keep = "recf")
#' }
#'
#' # Iterative cross-temporal reconciliation
#' ite_recf <- iterec(FoReco_data$base, note=FALSE,
#'                    m = 12, C = FoReco_data$C,
#'                    thf_comb = "acov", hts_comb = "shr",
#'                    res = FoReco_data$res, start_rec = "thf")$recf
#'
#' # Heuristic first-cross-sectional-then-temporal cross-temporal reconciliation
#' cst_recf <- cstrec(FoReco_data$base, m = 12, C = FoReco_data$C,
#'                    thf_comb = "acov", hts_comb = "shr",
#'                    res = FoReco_data$res)$recf
#'
#' # Heuristic first-temporal-then-cross-sectional cross-temporal reconciliation
#' tcs_recf <- tcsrec(FoReco_data$base, m = 12, C = FoReco_data$C,
#'                    thf_comb = "acov", hts_comb = "shr",
#'                    res = FoReco_data$res)$recf
#'
#' # Optimal cross-temporal reconciliation
#' oct_recf <- octrec(FoReco_data$base, m = 12, C = FoReco_data$C,
#'                    comb = "bdshr", res = FoReco_data$res, keep = "recf")
#' }
"FoReco_data"
