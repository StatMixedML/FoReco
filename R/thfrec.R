#' @title Forecast reconciliation through temporal hierarchies (temporal reconciliation)
#'
#' @description
#' Forecast reconciliation of one time series through temporal hierarchies
#' (Athanasopoulos et al., 2017). The reconciled forecasts are calculated
#' either through a projection approach (Byron, 1978), or the equivalent
#' structural approach by Hyndman et al. (2011). Moreover, the classic
#' bottom-up approach is available.
#'
#' @usage thfrec(basef, m, comb, res, mse = TRUE, corpcor = FALSE, Omega,
#'        type = "M", sol = "direct", nn = FALSE, keep = "list",
#'        settings = osqpSettings(verbose = FALSE, eps_abs = 1e-5,
#'        eps_rel = 1e-5, polish_refine_iter = 100, polish=TRUE))
#'
#' @param basef Vector of base forecasts to be reconciled, containing the forecasts
#' at all the needed temporal frequencies ordered as [lowest_freq' ...  highest_freq']'.
#' @param m Highest available sampling frequency per seasonal cycle (max. order of temporal aggregation).
#' @param comb Type of the reconciliation. Except for bottom up, all other options
#' correspond to a different (\code{(k* + m) x (k* + m)}) covariance matrix,
#' \code{k*} is the sum of (\code{p-1}) factors of \code{m} (excluding \code{m}):
#' \itemize{
#'   \item \bold{bu} (Bottom-up);
#'   \item \bold{ols} (Identity);
#'   \item \bold{struc} (Structural variances);
#'   \item \bold{wlsv} (Series variances);
#'   \item \bold{wlsh} (Hierarchy variances);
#'   \item \bold{acov} (Auto-covariance matrix);
#'   \item \bold{strar1} (Structural Markov);
#'   \item \bold{sar1} (Series Markov);
#'   \item \bold{har1} (Hierarchy Markov);
#'   \item \bold{shr} (Shrunk cross-covariance matrix);
#'   \item \bold{sam} (Sample cross-covariance matrix);
#'   \item \bold{omega} use your personal matrix Omega in param \code{Omega}.
#' }
#' @param res vector containing the in-sample residuals at all the temporal frequencies
#' ordered as \code{basef}, i.e. [lowest_freq' ...  highest_freq']', needed to
#' estimate the covariance matrix when \code{comb =} \code{\{"wlsv",} \code{"wlsh",}
#' \code{"acov",} \code{"strar1",} \code{"sar1",} \code{"har1",}
#' \code{"shr",} \code{"sam"\}}.
#' @param Omega This option permits to directly enter the covariance matrix:
#' \enumerate{
#'   \item \code{Omega} must be a p.d. (\code{(k* + m) x (k* + m)}) matrix;
#'   \item if \code{comb} is different from "\code{omega}", \code{Omega} is not used.
#' }
#' @param mse Logical value: \code{TRUE} (\emph{default}) calculates the
#' covariance matrix of the in-sample residuals (when necessary) according to the original
#' \pkg{hts} and \pkg{thief} formulation: no mean correction, T as denominator.
#' @param corpcor Logical value: \code{TRUE} if \pkg{corpcor} (\enc{Schäfer}{Schafer} et
#' al., 2017) must be used to shrink the sample covariance matrix according to
#' \enc{Schäfer}{Schafer} and Strimmer (2005), otherwise the function uses the same
#' implementation as package \pkg{hts}.
#' @param type Approach used to compute the reconciled forecasts: \code{"M"} for
#' the projection approach with matrix M (\emph{default}), or \code{"S"} for the
#' structural approach with summing matrix S.
#' @param keep Return a list object of the reconciled forecasts at all levels.
#' @param sol Solution technique for the reconciliation problem: either \code{"direct"} (\emph{default}) for the direct
#' solution or \code{"osqp"} for the numerical solution (solving a linearly constrained quadratic
#' program using \code{\link[osqp]{solve_osqp}}).
#' @param nn Logical value: \code{TRUE} if non-negative reconciled forecasts are wished.
#' @param settings Settings for \pkg{osqp} (object \code{\link[osqp]{osqpSettings}}). The default options
#' are: \code{verbose = FALSE}, \code{eps_abs = 1e-5}, \code{eps_rel = 1e-5},
#' \code{polish_refine_iter = 100} and \code{polish = TRUE}. For details, see the
#' \href{https://osqp.org/}{\pkg{osqp} documentation} (Stellato et al., 2019).
#'
#' @details
#' In case of non-negativity constraints, there are two ways:
#' \enumerate{
#'   \item \code{sol = "direct"} and \code{nn = TRUE}: the base forecasts
#'   will be reconciled at first without non-negativity constraints, then, if negative reconciled
#'   values are present, the \code{"osqp"} solver is used.
#'   \item \code{sol = "osqp"} and \code{nn = TRUE}: the base forecasts will be
#'   reconciled through the \code{"osqp"} solver.
#' }
#'
#' @return
#' If the parameter \code{keep} is equal to \code{"recf"}, then the function
#' returns only the reconciled forecasts vector, otherwise (\code{keep="all"})
#' it returns a list that mainly depends on what type of representation (\code{type})
#' and methodology (\code{sol}) have been used:
#' \item{\code{recf}}{(\code{h(k* + m) x 1}) reconciled forecasts vector.}
#' \item{\code{Omega}}{Covariance matrix used for forecast reconciliation.}
#' \item{\code{nn_check}}{Number of negative values (if zero, there are no values below zero).}
#' \item{\code{rec_check}}{Logical value: has the hierarchy been respected?}
#' \item{\code{M} (\code{type="M"} and \code{type="direct"})}{Projection matrix (projection approach)}
#' \item{\code{G} (\code{type="S"} and \code{type="direct"})}{Projection matrix (structural approach).}
#' \item{\code{S} (\code{type="S"} and \code{type="direct"})}{Temporal summing matrix, \strong{R}.}
#' \item{\code{info} (\code{type="osqp"})}{matrix with some useful indicators (columns)
#' for each forecast horizon \code{h} (rows): run time (\code{run_time}) number of iteration,
#' norm of primal residual (\code{pri_res}), status of osqp's solution (\code{status}) and
#' polish's status (\code{status_polish}).}
#'
#' Only if \code{comb = "bu"}, the function returns \code{recf}, \code{S} and \code{M}.
#'
#' @references
#' Athanasopoulos, G., Hyndman, R.J., Kourentzes, N., Petropoulos, F. (2017),
#' Forecasting with Temporal Hierarchies, \emph{European Journal of Operational
#' Research}, 262, 1, 60-74.
#'
#' Byron, R.P. (1978), The estimation of large social accounts matrices,
#' \emph{Journal of the Royal Statistical Society A}, 141, 3, 359-367.
#'
#' Di Fonzo, T., Girolimetto, D. (2020), Cross-Temporal Forecast Reconciliation:
#' Optimal Combination Method and Heuristic Alternatives, Department of Statistical
#' Sciences, University of Padua, \href{https://arxiv.org/abs/2006.08570}{arXiv:2006.08570}.
#'
#' Hyndman, R.J., Ahmed, R.A., Athanasopoulos, G., Shang, H.L. (2011), Optimal combination
#' forecasts for hierarchical time series, \emph{Computational Statistics & Data
#' Analysis}, 55, 9, 2579-2589.
#'
#' Nystrup, P.,  \enc{Lindström}{Lindstrom}, E., Pinson, P., Madsen, H. (2020),
#' Temporal hierarchies with autocorrelation for load forecasting,
#' \emph{European Journal of Operational Research}, 280, 1, 876-888.
#'
#' \enc{Schäfer}{Schafer}, J.L., Opgen-Rhein, R., Zuber, V., Ahdesmaki, M.,
#' Duarte Silva, A.P., Strimmer, K. (2017), Package `corpcor', R
#' package version 1.6.9 (April 1, 2017), \href{https://CRAN.R-project.org/package=corpcor}{https://CRAN.R-project.org/package= corpcor}.
#'
#' \enc{Schäfer}{Schafer}, J.L., Strimmer, K. (2005), A Shrinkage Approach to Large-Scale Covariance
#' Matrix Estimation and Implications for Functional Genomics, \emph{Statistical
#' Applications in Genetics and Molecular Biology}, 4, 1.
#'
#' Stellato, B., Banjac, G., Goulart, P., Bemporad, A., Boyd, S. (2018). OSQP:
#' An Operator Splitting Solver for Quadratic Programs, \href{https://arxiv.org/abs/1711.08013}{arXiv:1711.08013}.
#'
#' Stellato, B., Banjac, G., Goulart, P., Boyd, S., Anderson, E. (2019), OSQP:
#' Quadratic Programming Solver using the 'OSQP' Library, R package version 0.6.0.3
#' (October 10, 2019), \href{https://CRAN.R-project.org/package=osqp}{https://CRAN.R-project.org/package=osqp}.
#'
#' @keywords reconciliation
#' @examples
#' data(FoReco_data)
#' # top ts base forecasts ([lowest_freq' ...  highest_freq']')
#' topbase <- FoReco_data$base[1, ]
#'  # top ts residuals ([lowest_freq' ...  highest_freq']')
#' topres <- FoReco_data$res[1, ]
#' obj <- thfrec(topbase, m = 12, comb = "acov", res = topres)
#'
#' @export
#'
#' @import Matrix osqp
#'
thfrec <- function(basef, m, comb, res, mse = TRUE, corpcor = FALSE, Omega,
                   type = "M", sol = "direct", nn = FALSE, keep = "list",
                   settings = osqpSettings(
                     verbose = FALSE, eps_abs = 1e-5, eps_rel = 1e-5,
                     polish_refine_iter = 100, polish = TRUE
                   )) {
  # m condition
  if (missing(m)) {
    stop("The argument m is not specified")
  }
  tools <- thf_tools(m)
  kset <- tools$kset
  p <- tools$p
  kt <- tools$kt
  ks <- tools$ks

  # matrix
  K <- tools$K
  R <- tools$R
  Zt <- tools$Zt

  if (missing(comb)) {
    stop("The argument comb is not specified")
  }
  comb <- match.arg(comb, c(
    "bu", "ols", "struc", "wlsv", "wlsh", "acov",
    "strar1", "sar1", "har1", "shr", "sam", "omega"
  ))
  type <- match.arg(type, c("M", "S"))
  keep <- match.arg(keep, c("list", "recf"))

  # base forecasts condition
  if (missing(basef)) {
    stop("The argument basef is not specified")
  }

  if (NCOL(basef) != 1) {
    stop("basef must be a vector", call. = FALSE)
  }

  # Base Forecasts matrix
  if (comb == "bu" & length(basef) %% m == 0) {
    h <- length(basef) / m
    Dh <- Dmat(h = h, kset = kset, n = 1)
    BASEF <- matrix(basef, h, m, byrow = T)
  } else if (length(basef) %% kt != 0) {
    stop("basef vector has a number of elemnts not in line with the frequency of the series", call. = FALSE)
  } else {
    h <- length(basef) / kt
    Dh <- Dmat(h = h, kset = kset, n = 1)
    BASEF <- matrix(Dh %*% basef, nrow = h, byrow = T)
  }

  # Residuals Matrix
  if (any(comb == c("wlsv", "wlsh", "acov", "strar1", "sar1", "har1", "sGlasso", "hGlasso", "shr", "sam"))) {
    # residual condition
    if (missing(res)) {
      stop("Don't forget residuals!", call. = FALSE)
    }
    if (NCOL(res) != 1) {
      stop("res must be a vector", call. = FALSE)
    }
    if (length(res) %% kt != 0) {
      stop("res vector has a number of row not in line with frequency of the series", call. = FALSE)
    }

    N <- length(res) / kt
    DN <- Dmat(h = N, kset = kset, n = 1)
    RES <- matrix(DN %*% res, nrow = N, byrow = T)

    # OLD style:
    # index_r <- cumsum(rev(kset*N))
    # INDEX_r <- cbind(c(1,index_r[1:length(kset[-1])]+1),index_r)

    # singularity problems
    if (comb == "sam" & N < kt) {
      stop("N < (k* + m): it could lead to singularity problems if comb == sam", call. = FALSE)
    }

    if (comb == "acov" & N < m) {
      stop("N < m: it could lead to singularity problems if comb == acov", call. = FALSE)
    }
  }

  if (mse) {
    cov_mod <- function(x, ...) crossprod(stats::na.omit(x), ...) / NROW(stats::na.omit(x))
  } else {
    cov_mod <- function(x, ...) stats::var(x, na.rm = TRUE, ...)
  }

  if (corpcor) {
    shr_mod <- function(x, ...) corpcor::cov.shrink(x, verbose = FALSE, ...)
  } else {
    shr_mod <- function(x, ...) shrink_estim(x, minT = mse)[[1]]
  }

  # Reconciliation

  switch(comb,
    bu = {
      if (NCOL(BASEF) == m) {
        OUTF <- BASEF %*% t(R)
      } else {
        OUTF <- BASEF[, (ks + 1):kt] %*% t(R)
      }

      outf <- as.vector(t(Dh) %*% as.vector(t(OUTF)))

      outf <- stats::setNames(outf, paste("k", rep(kset, h * rev(kset)), "h",
        do.call("c", as.list(sapply(
          rev(kset) * h,
          function(x) seq(1:x)
        ))),
        sep = ""
      ))
      if (keep == "list") {
        return(list(
          recf = outf, S = R,
          M = R %*% cbind(matrix(0, m, ks), diag(m))
        ))
      } else {
        return(outf)
      }
    },
    ols =
      Omega <- .sparseDiagonal(kt),
    struc =
      Omega <- .sparseDiagonal(x = rowSums(R)),
    wlsv = {
      var_freq <- sapply(kset, function(x) cov_mod(res[rep(kset, rev(kset) * N) == x]))
      Omega <- .sparseDiagonal(x = rep(var_freq, rev(kset)))
    },
    wlsh = {
      diagO <- diag(cov_mod(RES))
      Omega <- .sparseDiagonal(x = diagO)
    },
    acov = {
      Omega <- Matrix::bdiag(lapply(kset, function(x) cov_mod(RES[, rep(kset, rev(kset)) == x])))
    },
    strar1 = {
      rho <- lapply(kset, function(x) stats::acf(stats::na.omit(res[rep(kset, rev(kset) * N) == x]),
                                                 1, plot = F)$acf[2, 1, 1])
      expo <- lapply(rev(kset), function(x) toeplitz(1:x) - 1)

      Gam <- Matrix::bdiag(Map(function(x, y) x^y, x = rho, y = expo))
      Ostr2 <- .sparseDiagonal(x = apply(R, 1, sum))^0.5
      Omega <- Ostr2 %*% Gam %*% Ostr2
    },
    sar1 = {
      rho <- lapply(kset, function(x) stats::acf(stats::na.omit(res[rep(kset, rev(kset) * N) == x]),
                                                 1, plot = F)$acf[2, 1, 1])
      expo <- lapply(rev(kset), function(x) toeplitz(1:x) - 1)

      Gam <- Matrix::bdiag(Map(function(x, y) x^y, x = rho, y = expo))
      var_freq <- sapply(kset, function(x) cov_mod(res[rep(kset, rev(kset) * N) == x]))
      Os2 <- .sparseDiagonal(x = rep(var_freq, rev(kset)))^0.5
      Omega <- Os2 %*% Gam %*% Os2
    },
    har1 = {
      rho <- lapply(kset, function(x) stats::acf(stats::na.omit(res[rep(kset, rev(kset) * N) == x]),
                                                 1, plot = F)$acf[2, 1, 1])
      expo <- lapply(rev(kset), function(x) toeplitz(1:x) - 1)

      Gam <- Matrix::bdiag(Map(function(x, y) x^y, x = rho, y = expo))
      diagO <- diag(cov_mod(RES))
      Oh2 <- .sparseDiagonal(x = diagO)^0.5
      Omega <- Matrix::Matrix(Oh2 %*% Gam %*% Oh2)
    },
    shr = {
      Omega <- shr_mod(RES)
    },
    sam = {
      Omega <- cov_mod(RES)
    },
    omega = {
      if (missing(Omega)) {
        stop("Please, put in option Omega your covariance matrix", call. = FALSE)
      }
      Omega <- Omega
    }
  )

  b_pos <- c(rep(0, kt - m), rep(1, m))

  if (type == "S") {
    rec_sol <- recoS(
      basef = BASEF, W = Omega, S = R, sol = sol, nn = nn, keep = keep,
      settings = settings, b_pos = b_pos
    )
  } else {
    rec_sol <- recoM(
      basef = BASEF, W = Omega, H = Zt, sol = sol, nn = nn, keep = keep,
      settings = settings, b_pos = b_pos
    )
  }

  if (keep == "list") {
    rec_sol$nn_check <- sum(rec_sol$recf < 0)
    rec_sol$rec_check <- all(rec_sol$recf %*% t(Zt) < 1e-6)

    rec_sol$recf <- as.vector(t(Dh) %*% as.vector(t(rec_sol$recf)))
    names(rec_sol)[names(rec_sol) == "W"] <- "Omega"
    rec_sol$Omega <- as.matrix(rec_sol$Omega)
    dimnames(rec_sol$Omega) <- NULL

    names_all_list <- c("recf", "W", "Omega", "nn_check", "rec_check", "varf", "M", "G", "S", "info")
    names_list <- names(rec_sol)
    rec_sol <- rec_sol[names_list[order(match(names_list, names_all_list))]]

    rec_sol$recf <- stats::setNames(rec_sol$recf, paste("k", rep(kset, h * rev(kset)), "h",
      do.call("c", as.list(sapply(
        rev(kset) * h,
        function(x) seq(1:x)
      ))),
      sep = ""
    ))
    return(rec_sol)
  } else {
    if (length(rec_sol) == 1) {
      rec_sol$recf <- as.vector(t(Dh) %*% as.vector(t(rec_sol$recf)))
      rec_sol$recf <- stats::setNames(rec_sol$recf, paste("k", rep(kset, h * rev(kset)), "h",
        do.call("c", as.list(sapply(
          rev(kset) * h,
          function(x) seq(1:x)
        ))),
        sep = ""
      ))
      return(rec_sol$recf)
    } else {
      rec_sol$recf <- as.vector(t(Dh) %*% as.vector(t(rec_sol$recf)))
      rec_sol$recf <- stats::setNames(rec_sol$recf, paste("k", rep(kset, h * rev(kset)), "h",
        do.call("c", as.list(sapply(
          rev(kset) * h,
          function(x) seq(1:x)
        ))),
        sep = ""
      ))
      return(rec_sol)
    }
  }
}

# # outM is matrix of reconcile forecasts
# # m is the frequency of disagregate serie
# # k is the factors of m (excluding m)
# # return a vector [lowest_freq' ...  highest_freq']'
# matrix_out <- function(outM, kset){
#   index <- cumsum(rev(kset))
#   INDEX <- cbind(c(1,index[1:length(kset[-1])]+1),index)
#   out <- apply(INDEX,1,function(x) as.vector(t(outM[,x[1]:x[2]])))
#   out <- do.call("c",out)
#   return(out)
# }
