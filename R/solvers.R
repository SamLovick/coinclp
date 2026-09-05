## The solve entry points and the ClpSolve options object.

#' Solve a loaded model
#'
#' The entry points of the Clp callable library.  \code{clp_initial_solve()}
#' lets Clp choose the algorithm and applies presolve, which is the right
#' default for most problems; the others force a particular method.
#' \code{clp_primal_simplex()} and \code{clp_dual_simplex()} run the simplex
#' without presolve, which is what you want when re-solving a modified model
#' from a warm start.
#'
#' @param model A \code{"clp_model"} object.
#' @param options A \code{"clp_options"} object from \code{\link{clp_options}}.
#' @param if_values_pass Pass 1 to start from the values in
#'   \code{\link{clp_set_col_solution}}, 0 otherwise.
#' @param try_hard Effort level for the idiot crash.
#' @param gap Bound gap below which variables may be flipped by the crash.
#' @param pivot Crash pivoting rule: 0 none, 1 simple, 2 mini iterations.
#' @return An integer return code from Clp: 0 if it solved the problem,
#'   1 if the problem is primal infeasible, 2 if dual infeasible, and other
#'   values if it stopped early.  \code{clp_idiot()} returns \code{NULL}
#'   invisibly.  Use \code{\link{clp_status}} for the status of the model
#'   itself.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 2, 1, c(0L, 1L, 2L), c(0L, 0L), c(1, 1),
#'                  obj = c(-1, -2), rowub = 3)
#' clp_set_log_level(model, 0L)
#' clp_initial_solve(model)
#' clp_objective_value(model)
#' clp_free(model)
clp_initial_solve <- function(model)
    .Call(C_coinclp_initial_solve, clp_ptr(model))

#' @rdname clp_initial_solve
#' @export
clp_initial_dual_solve <- function(model)
    .Call(C_coinclp_initial_dual_solve, clp_ptr(model))

#' @rdname clp_initial_solve
#' @export
clp_initial_primal_solve <- function(model)
    .Call(C_coinclp_initial_primal_solve, clp_ptr(model))

#' @rdname clp_initial_solve
#' @export
clp_initial_barrier_solve <- function(model)
    .Call(C_coinclp_initial_barrier_solve, clp_ptr(model))

#' @rdname clp_initial_solve
#' @export
clp_initial_barrier_no_cross_solve <- function(model)
    .Call(C_coinclp_initial_barrier_no_cross_solve, clp_ptr(model))

#' @rdname clp_initial_solve
#' @export
clp_initial_solve_with_options <- function(model, options)
    .Call(C_coinclp_initial_solve_with_options, clp_ptr(model), options)

#' @rdname clp_initial_solve
#' @export
clp_primal_simplex <- function(model, if_values_pass = 0L)
    .Call(C_coinclp_primal, clp_ptr(model), as.integer(if_values_pass))

#' @rdname clp_initial_solve
#' @export
clp_dual_simplex <- function(model, if_values_pass = 0L)
    .Call(C_coinclp_dual, clp_ptr(model), as.integer(if_values_pass))

#' @rdname clp_initial_solve
#' @export
clp_idiot <- function(model, try_hard = 0L) {
    invisible(.Call(C_coinclp_idiot, clp_ptr(model), as.integer(try_hard)))
}

#' @rdname clp_initial_solve
#' @export
clp_crash <- function(model, gap = 0, pivot = 0L)
    .Call(C_coinclp_crash, clp_ptr(model), as.numeric(gap), as.integer(pivot))

# ---------------------------------------------------------------------------
# ClpSolve options
# ---------------------------------------------------------------------------

#' Presolve and algorithm options
#'
#' Settings on a \code{\link{clp_options}} object, passed to
#' \code{\link{clp_initial_solve_with_options}}.
#'
#' The solve type selects the algorithm: 0 dual simplex, 1 primal simplex,
#' 2 primal or sprint, 3 barrier, 4 barrier without crossover, 5 automatic.
#' The presolve type is 0 presolve on, 1 presolve off, 2 a fixed number of
#' passes, 3 number and cost.
#'
#' @param options A \code{"clp_options"} object.
#' @param method Algorithm code, see Details.
#' @param amount Presolve code, see Details.
#' @param which Index of the special option or extra information slot.
#' @param extra Extra information for the setting; -1 selects Clp's default.
#' @param value The new value.
#' @return The getters return an integer; the setters \code{NULL} invisibly.
#' @export
#' @examples
#' opts <- clp_options()
#' clp_options_set_solve_type(opts, 0L)      # dual simplex
#' clp_options_set_presolve_type(opts, 1L)   # presolve off
#' clp_options_get_solve_type(opts)
#' clp_options_free(opts)
clp_options_set_solve_type <- function(options, method, extra = -1L) {
    invisible(.Call(C_coinclp_options_set_solve_type, options,
                    as.integer(method), as.integer(extra)))
}

#' @rdname clp_options_set_solve_type
#' @export
clp_options_get_solve_type <- function(options)
    .Call(C_coinclp_options_get_solve_type, options)

#' @rdname clp_options_set_solve_type
#' @export
clp_options_set_presolve_type <- function(options, amount, extra = -1L) {
    invisible(.Call(C_coinclp_options_set_presolve_type, options,
                    as.integer(amount), as.integer(extra)))
}

#' @rdname clp_options_set_solve_type
#' @export
clp_options_get_presolve_type <- function(options)
    .Call(C_coinclp_options_get_presolve_type, options)

#' @rdname clp_options_set_solve_type
#' @export
clp_options_get_presolve_passes <- function(options)
    .Call(C_coinclp_options_get_presolve_passes, options)

#' @rdname clp_options_set_solve_type
#' @export
clp_options_set_special_option <- function(options, which, value, extra = -1L) {
    invisible(.Call(C_coinclp_options_set_special_option, options,
                    as.integer(which), as.integer(value), as.integer(extra)))
}

#' @rdname clp_options_set_solve_type
#' @export
clp_options_get_special_option <- function(options, which)
    .Call(C_coinclp_options_get_special_option, options, as.integer(which))

#' @rdname clp_options_set_solve_type
#' @export
clp_options_get_extra_info <- function(options, which)
    .Call(C_coinclp_options_get_extra_info, options, as.integer(which))

#' Individual presolve transformations
#'
#' Switch single presolve transformations on or off in a
#' \code{\link{clp_options}} object.  Each getter returns Clp's current
#' setting for that transformation.
#'
#' @param options A \code{"clp_options"} object.
#' @param value The new value; 0 or 1 for the switches.
#' @return The getters return an integer; the setters \code{NULL} invisibly.
#' @export
#' @examples
#' opts <- clp_options()
#' clp_options_set_do_dual(opts, 1L)
#' clp_options_do_dual(opts)
#' clp_options_free(opts)
clp_options_do_dual <- function(options)
    .Call(C_coinclp_options_do_dual, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_dual <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_dual, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_singleton <- function(options)
    .Call(C_coinclp_options_do_singleton, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_singleton <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_singleton, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_doubleton <- function(options)
    .Call(C_coinclp_options_do_doubleton, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_doubleton <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_doubleton, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_tripleton <- function(options)
    .Call(C_coinclp_options_do_tripleton, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_tripleton <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_tripleton, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_tighten <- function(options)
    .Call(C_coinclp_options_do_tighten, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_tighten <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_tighten, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_forcing <- function(options)
    .Call(C_coinclp_options_do_forcing, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_forcing <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_forcing, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_implied_free <- function(options)
    .Call(C_coinclp_options_do_implied_free, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_implied_free <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_implied_free, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_dupcol <- function(options)
    .Call(C_coinclp_options_do_dupcol, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_dupcol <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_dupcol, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_duprow <- function(options)
    .Call(C_coinclp_options_do_duprow, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_duprow <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_duprow, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_do_singleton_column <- function(options)
    .Call(C_coinclp_options_do_singleton_column, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_do_singleton_column <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_do_singleton_column, options,
                    as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_presolve_actions <- function(options)
    .Call(C_coinclp_options_presolve_actions, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_presolve_actions <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_presolve_actions, options,
                    as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_substitution <- function(options)
    .Call(C_coinclp_options_substitution, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_substitution <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_substitution, options, as.integer(value)))
}

#' @rdname clp_options_do_dual
#' @export
clp_options_infeasible_return <- function(options)
    .Call(C_coinclp_options_infeasible_return, options)

#' @rdname clp_options_do_dual
#' @export
clp_options_set_infeasible_return <- function(options, value) {
    invisible(.Call(C_coinclp_options_set_infeasible_return, options,
                    as.integer(value)))
}
