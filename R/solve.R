## The one-call interface: build a model from R objects, solve it, hand back
## an ordinary list.

#' Control parameters for clp_solve()
#'
#' @param log_level How much Clp prints: 0 silent (the default), up to 4.
#' @param algorithm One of \code{"auto"}, \code{"primal"}, \code{"dual"},
#'   \code{"barrier"} or \code{"barrier_nocross"}.
#' @param presolve Run Clp's presolve.  Ignored when \code{algorithm} is
#'   \code{"auto"} and \code{presolve} is \code{TRUE}, which is Clp's own
#'   default path.
#' @param max_iterations Iteration limit, or \code{NULL} for Clp's default.
#' @param max_seconds Time limit in seconds, or \code{NULL} for no limit.
#' @param primal_tolerance,dual_tolerance Simplex tolerances, or \code{NULL}
#'   for Clp's defaults.
#' @param scaling Scaling mode: 0 off, 1 equilibrium, 2 geometric, 3 auto,
#'   4 dynamic, or \code{NULL} for Clp's default.
#' @return A list of control settings for \code{\link{clp_solve}}.
#' @export
#' @examples
#' clp_control(algorithm = "dual", max_seconds = 10)
clp_control <- function(log_level = 0L,
                        algorithm = c("auto", "primal", "dual",
                                      "barrier", "barrier_nocross"),
                        presolve = TRUE,
                        max_iterations = NULL,
                        max_seconds = NULL,
                        primal_tolerance = NULL,
                        dual_tolerance = NULL,
                        scaling = NULL) {
    algorithm <- match.arg(algorithm)
    structure(list(log_level = as.integer(log_level),
                   algorithm = algorithm,
                   presolve = isTRUE(presolve),
                   max_iterations = max_iterations,
                   max_seconds = max_seconds,
                   primal_tolerance = primal_tolerance,
                   dual_tolerance = dual_tolerance,
                   scaling = scaling),
              class = "clp_control")
}

#' Solve a linear program
#'
#' Builds a Clp model from ordinary R objects, solves it and returns the
#' solution.  The model is freed before the function returns.
#'
#' Constraints are given either by \code{dir} and \code{rhs}, the usual
#' one-sided form, or by \code{row_lower} and \code{row_upper}, which also
#' covers ranged constraints (\code{2 <= x + y <= 5}).  Infinite bounds are
#' written as \code{Inf} and \code{-Inf}.
#'
#' \code{constraints} may be a dense matrix, a sparse matrix from the
#' \pkg{Matrix} package, a \code{simple_triplet_matrix} from \pkg{slam}, or a
#' list of triplets with components \code{i}, \code{j}, \code{v} plus
#' \code{nrow} and \code{ncol}.
#'
#' @param objective Numeric vector of objective coefficients, one per variable.
#' @param constraints Constraint matrix, or \code{NULL} for a problem with
#'   only variable bounds.
#' @param dir Character vector of constraint directions, recycled over the
#'   rows: \code{"<="}, \code{">="} or \code{"=="}.
#' @param rhs Numeric right hand side, one entry per row.
#' @param row_lower,row_upper Row bounds, as an alternative to
#'   \code{dir}/\code{rhs}.
#' @param lower,upper Variable bounds, scalars or one entry per variable.
#'   The default lower bound is 0, as in most LP formulations.
#' @param max Maximise instead of minimise.
#' @param control A list from \code{\link{clp_control}}.
#' @param col_names,row_names Optional names, used for the returned vectors.
#' @return An object of class \code{"clp_solution"}: a list with
#'   \describe{
#'     \item{\code{objval}}{the objective value at the solution}
#'     \item{\code{solution}}{the primal solution}
#'     \item{\code{status}}{Clp's status code, see \code{\link{clp_status}}}
#'     \item{\code{status_message}}{that code as text}
#'     \item{\code{optimal}}{\code{TRUE} when Clp proved optimality}
#'     \item{\code{duals}}{dual values (shadow prices) for the rows}
#'     \item{\code{reduced_costs}}{reduced costs for the columns}
#'     \item{\code{row_activity}}{the value of each row at the solution}
#'     \item{\code{iterations}}{simplex iterations used}
#'   }
#' @seealso \code{\link{clp_model}} and \code{\link{clp_load_problem}} for
#'   building a model that you keep, modify and re-solve.
#' @export
#' @examples
#' # maximise 143x + 60y subject to
#' #   120x +  210y <= 15000
#' #   110x +   30y <=  4000
#' #      x +     y <=    75
#' A <- rbind(c(120, 210), c(110, 30), c(1, 1))
#' res <- clp_solve(c(143, 60), A, "<=", c(15000, 4000, 75), max = TRUE)
#' res$objval
#' res$solution
clp_solve <- function(objective, constraints = NULL, dir = "<=", rhs = NULL,
                      row_lower = NULL, row_upper = NULL,
                      lower = 0, upper = Inf, max = FALSE,
                      control = clp_control(),
                      col_names = NULL, row_names = NULL) {

    objective <- as.numeric(objective)
    ncols <- length(objective)
    if (ncols == 0L) stop("'objective' must have at least one entry", call. = FALSE)
    if (anyNA(objective)) stop("'objective' must not contain NA", call. = FALSE)
    if (!inherits(control, "clp_control"))
        control <- do.call(clp_control, as.list(control))

    mat <- as_clp_matrix(constraints, ncols)
    nrows <- mat$nrow

    bounds <- row_bounds(dir, rhs, row_lower, row_upper, nrows)

    lower <- recycle_bound(lower, ncols, "lower")
    upper <- recycle_bound(upper, ncols, "upper")
    if (any(lower > upper))
        stop("some variables have a lower bound above their upper bound",
             call. = FALSE)

    model <- clp_model()
    on.exit(clp_free(model), add = TRUE)

    clp_set_log_level(model, control$log_level)
    clp_load_problem(model, ncols = ncols, nrows = nrows,
                     start = mat$start, index = mat$index, value = mat$value,
                     collb = finite_bound(lower), colub = finite_bound(upper),
                     obj = objective,
                     rowlb = finite_bound(bounds$lower),
                     rowub = finite_bound(bounds$upper))
    clp_set_optimization_direction(model, if (isTRUE(max)) -1 else 1)
    apply_control(model, control)

    if (!is.null(col_names) || !is.null(row_names)) {
        cn <- if (is.null(col_names)) clp_col_names(model) else as.character(col_names)
        rn <- if (is.null(row_names)) clp_row_names(model) else as.character(row_names)
        if (length(cn) == ncols && length(rn) == nrows)
            clp_set_names(model, rn, cn)
    }

    run_solver(model, control)

    status <- clp_status(model)
    solution <- clp_col_solution(model)
    if (!is.null(col_names) && length(col_names) == ncols)
        names(solution) <- col_names
    duals <- clp_row_price(model)
    activity <- clp_row_activity(model)
    if (!is.null(row_names) && length(row_names) == nrows) {
        names(duals) <- row_names
        names(activity) <- row_names
    }

    structure(list(objval = sum(objective * solution) + clp_objective_offset(model),
                   solution = solution,
                   status = status,
                   status_message = clp_status_message(status),
                   optimal = clp_is_proven_optimal(model),
                   duals = duals,
                   reduced_costs = clp_reduced_costs(model),
                   row_activity = activity,
                   iterations = clp_iterations(model),
                   direction = if (isTRUE(max)) "max" else "min"),
              class = "clp_solution")
}

#' @export
print.clp_solution <- function(x, ...) {
    cat("<clp_solution>\n")
    cat("  status:    ", x$status, " (", x$status_message, ")\n", sep = "")
    cat("  objective: ", format(x$objval), " [", x$direction, "]\n", sep = "")
    n <- length(x$solution)
    show <- min(n, 10L)
    cat("  solution:  ", paste(format(x$solution[seq_len(show)]), collapse = " "),
        if (show < n) sprintf(" ... (%d values)", n) else "", "\n", sep = "")
    cat("  iterations:", x$iterations, "\n")
    invisible(x)
}

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

apply_control <- function(model, control) {
    if (!is.null(control$max_iterations))
        clp_set_max_iterations(model, control$max_iterations)
    if (!is.null(control$max_seconds))
        clp_set_max_seconds(model, control$max_seconds)
    if (!is.null(control$primal_tolerance))
        clp_set_primal_tolerance(model, control$primal_tolerance)
    if (!is.null(control$dual_tolerance))
        clp_set_dual_tolerance(model, control$dual_tolerance)
    if (!is.null(control$scaling))
        clp_set_scaling(model, control$scaling)
    invisible(NULL)
}

## Clp exposes presolve only through the ClpSolve options object, so anything
## other than the default path goes through clp_initial_solve_with_options().
run_solver <- function(model, control) {
    if (control$presolve) {
        switch(control$algorithm,
               auto            = clp_initial_solve(model),
               primal          = clp_initial_primal_solve(model),
               dual            = clp_initial_dual_solve(model),
               barrier         = clp_initial_barrier_solve(model),
               barrier_nocross = clp_initial_barrier_no_cross_solve(model))
    } else {
        opts <- clp_options()
        on.exit(clp_options_free(opts), add = TRUE)
        solve_type <- switch(control$algorithm,
                             auto = 5L, primal = 1L, dual = 0L,
                             barrier = 3L, barrier_nocross = 4L)
        clp_options_set_solve_type(opts, solve_type)
        clp_options_set_presolve_type(opts, 1L)   # presolve off
        clp_initial_solve_with_options(model, opts)
    }
}

recycle_bound <- function(x, n, what) {
    x <- as.numeric(x)
    if (length(x) == 1L) x <- rep(x, n)
    if (length(x) != n)
        stop("'", what, "' must have length 1 or ", n, call. = FALSE)
    if (anyNA(x)) stop("'", what, "' must not contain NA", call. = FALSE)
    x
}

row_bounds <- function(dir, rhs, row_lower, row_upper, nrows) {
    if (!is.null(row_lower) || !is.null(row_upper)) {
        lower <- if (is.null(row_lower)) rep(-Inf, nrows) else recycle_bound(row_lower, nrows, "row_lower")
        upper <- if (is.null(row_upper)) rep(Inf, nrows) else recycle_bound(row_upper, nrows, "row_upper")
        if (any(lower > upper))
            stop("some rows have 'row_lower' above 'row_upper'", call. = FALSE)
        return(list(lower = lower, upper = upper))
    }

    if (nrows == 0L) return(list(lower = numeric(0), upper = numeric(0)))
    if (is.null(rhs))
        stop("give either 'rhs' (with 'dir') or 'row_lower'/'row_upper'",
             call. = FALSE)

    rhs <- recycle_bound(rhs, nrows, "rhs")
    dir <- as.character(dir)
    if (length(dir) == 1L) dir <- rep(dir, nrows)
    if (length(dir) != nrows)
        stop("'dir' must have length 1 or ", nrows, call. = FALSE)

    dir <- sub("^=$", "==", trimws(dir))
    dir[dir == "<"] <- "<="
    dir[dir == ">"] <- ">="
    bad <- !dir %in% c("<=", ">=", "==")
    if (any(bad))
        stop("unsupported constraint direction: ",
             paste(unique(dir[bad]), collapse = ", "), call. = FALSE)

    lower <- ifelse(dir == "<=", -Inf, rhs)
    upper <- ifelse(dir == ">=", Inf, rhs)
    list(lower = lower, upper = upper)
}

## Convert the supported matrix representations into 0-based CSC arrays.
as_clp_matrix <- function(x, ncols) {
    if (is.null(x))
        return(list(nrow = 0L, ncol = ncols, start = rep(0L, ncols + 1L),
                    index = integer(0), value = numeric(0)))

    if (is.list(x) && all(c("i", "j", "v") %in% names(x))) {
        nrow <- if (!is.null(x$nrow)) as.integer(x$nrow) else max(0L, as.integer(x$i))
        ncol <- if (!is.null(x$ncol)) as.integer(x$ncol) else ncols
        return(triplet_to_csc(as.integer(x$i), as.integer(x$j), as.numeric(x$v),
                              nrow, ncol, ncols))
    }

    if (inherits(x, "simple_triplet_matrix"))
        return(triplet_to_csc(as.integer(x$i), as.integer(x$j), as.numeric(x$v),
                              as.integer(x$nrow), as.integer(x$ncol), ncols))

    if (isS4(x) && methods::is(x, "Matrix")) {
        x <- methods::as(methods::as(x, "CsparseMatrix"), "generalMatrix")
        nrow <- nrow(x); ncol <- ncol(x)
        check_ncols(ncol, ncols)
        return(list(nrow = nrow, ncol = ncol,
                    start = as.integer(x@p), index = as.integer(x@i),
                    value = as.numeric(x@x)))
    }

    if (is.vector(x) && !is.list(x)) x <- matrix(x, nrow = 1L)
    if (!is.matrix(x)) x <- as.matrix(x)
    storage.mode(x) <- "double"
    nrow <- nrow(x); ncol <- ncol(x)
    check_ncols(ncol, ncols)
    if (anyNA(x)) stop("'constraints' must not contain NA", call. = FALSE)

    pos <- which(x != 0)
    i <- (pos - 1L) %% nrow
    j <- (pos - 1L) %/% nrow
    list(nrow = nrow, ncol = ncol,
         start = c(0L, cumsum(tabulate(j + 1L, nbins = ncol))),
         index = as.integer(i), value = as.numeric(x[pos]))
}

triplet_to_csc <- function(i, j, v, nrow, ncol, ncols) {
    check_ncols(ncol, ncols)
    keep <- v != 0 & !is.na(v)
    i <- i[keep]; j <- j[keep]; v <- v[keep]
    if (length(i) && (min(i) < 1L || max(i) > nrow))
        stop("row indices in 'constraints' are out of range", call. = FALSE)
    if (length(j) && (min(j) < 1L || max(j) > ncol))
        stop("column indices in 'constraints' are out of range", call. = FALSE)
    ord <- order(j, i)
    i <- i[ord]; j <- j[ord]; v <- v[ord]
    list(nrow = nrow, ncol = ncol,
         start = c(0L, cumsum(tabulate(j, nbins = ncol))),
         index = as.integer(i - 1L), value = as.numeric(v))
}

check_ncols <- function(ncol, ncols) {
    if (ncol != ncols)
        stop("'constraints' has ", ncol, " columns but 'objective' has ",
             ncols, " entries", call. = FALSE)
    invisible(NULL)
}
