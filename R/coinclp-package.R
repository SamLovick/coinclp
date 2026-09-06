#' coinclp: an R interface to the COIN-OR Clp linear programming solver
#'
#' Clp is the simplex and barrier code of the COIN-OR project.  This package
#' binds its callable library and offers two ways in:
#'
#' \describe{
#'   \item{One call}{\code{\link{clp_solve}()} takes an objective, a
#'     constraint matrix and bounds and returns the solution.}
#'   \item{A model you keep}{\code{\link{clp_model}()} creates a solver
#'     object that you fill with \code{\link{clp_load_problem}()}, adjust
#'     with the \code{clp_set_*} functions, solve with
#'     \code{\link{clp_initial_solve}()} and re-solve from a warm start.}
#' }
#'
#' Functions ending in \code{CLP} mirror the interface of the archived
#' \pkg{clpAPI} package, so that code written against it runs unchanged; see
#' \code{\link{initProbCLP}}.
#'
#' Clp itself is not bundled: the package links against an installed Clp
#' (1.16 or later).  On Windows the Rtools toolchain provides it, from
#' Rtools 4.3 on; a binary package from CRAN needs nothing installed at all.
#' A Clp that pkg-config cannot find is pointed at with the \code{CLP_CFLAGS}
#' and \code{CLP_LIBS} environment variables, on any platform.
#'
#' @section Index conventions:
#' The \code{clp_*} bindings follow the C API and use 0-based row and column
#' positions, as the Clp documentation does.  \code{\link{clp_solve}()},
#' \code{\link{clp_matrix}()} and the name accessors use ordinary 1-based R
#' positions.
#'
#' @keywords internal
#' @import methods
#' @useDynLib coinclp, .registration = TRUE, .fixes = "C_"
"_PACKAGE"
