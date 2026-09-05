## Solver parameters, status codes and diagnostics.

#' Optimization direction
#'
#' Clp stores the direction as a number: 1 to minimise, -1 to maximise and 0
#' to ignore the objective.  \code{clp_obj_sense()} is Clp's OSI-style
#' spelling of the same setting.
#'
#' @param model A \code{"clp_model"} object.
#' @param value 1 (minimise), -1 (maximise) or 0 (ignore the objective).
#' @return The getters return a number; the setters \code{NULL} invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_set_optimization_direction(model, -1)
#' clp_optimization_direction(model)
#' clp_free(model)
clp_optimization_direction <- function(model)
    .Call(C_coinclp_optimization_direction, clp_ptr(model))

#' @rdname clp_optimization_direction
#' @export
clp_set_optimization_direction <- function(model, value) {
    invisible(.Call(C_coinclp_set_optimization_direction, clp_ptr(model),
                    as.numeric(value)))
}

#' @rdname clp_optimization_direction
#' @export
clp_obj_sense <- function(model) .Call(C_coinclp_obj_sense, clp_ptr(model))

#' @rdname clp_optimization_direction
#' @export
clp_set_obj_sense <- function(model, value) {
    invisible(.Call(C_coinclp_set_obj_sense, clp_ptr(model), as.numeric(value)))
}

#' Objective value and offset
#'
#' @param model A \code{"clp_model"} object.
#' @param value A constant added to the objective.
#' @return A number, or \code{NULL} invisibly for the setter.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, obj = -1, rowub = 2)
#' clp_initial_solve(model)
#' clp_objective_value(model)
#' clp_free(model)
clp_objective_value <- function(model)
    .Call(C_coinclp_objective_value, clp_ptr(model))

#' @rdname clp_objective_value
#' @export
clp_objective_offset <- function(model)
    .Call(C_coinclp_objective_offset, clp_ptr(model))

#' @rdname clp_objective_value
#' @export
clp_set_objective_offset <- function(model, value) {
    invisible(.Call(C_coinclp_set_objective_offset, clp_ptr(model),
                    as.numeric(value)))
}

#' Numerical tolerances and limits
#'
#' Getters and setters for the simplex tolerances and the stopping criteria.
#'
#' \code{clp_set_max_seconds()} takes a number of seconds from now, and a
#' negative value removes the limit.  Clp turns that into an absolute
#' deadline by adding the processor time already used, so
#' \code{clp_max_seconds()} reads back the deadline rather than the number
#' that was set.
#'
#' @param model A \code{"clp_model"} object.
#' @param value The new value.
#' @return The getters return a number; the setters \code{NULL} invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_set_primal_tolerance(model, 1e-8)
#' clp_primal_tolerance(model)
#' clp_set_max_iterations(model, 1000L)
#' clp_max_iterations(model)
#' clp_free(model)
clp_primal_tolerance <- function(model)
    .Call(C_coinclp_primal_tolerance, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_primal_tolerance <- function(model, value) {
    invisible(.Call(C_coinclp_set_primal_tolerance, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_primal_tolerance
#' @export
clp_dual_tolerance <- function(model) .Call(C_coinclp_dual_tolerance, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_dual_tolerance <- function(model, value) {
    invisible(.Call(C_coinclp_set_dual_tolerance, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_primal_tolerance
#' @export
clp_dual_objective_limit <- function(model)
    .Call(C_coinclp_dual_objective_limit, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_dual_objective_limit <- function(model, value) {
    invisible(.Call(C_coinclp_set_dual_objective_limit, clp_ptr(model),
                    as.numeric(value)))
}

#' @rdname clp_primal_tolerance
#' @export
clp_dual_bound <- function(model) .Call(C_coinclp_dual_bound, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_dual_bound <- function(model, value) {
    invisible(.Call(C_coinclp_set_dual_bound, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_primal_tolerance
#' @export
clp_infeasibility_cost <- function(model)
    .Call(C_coinclp_infeasibility_cost, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_infeasibility_cost <- function(model, value) {
    invisible(.Call(C_coinclp_set_infeasibility_cost, clp_ptr(model),
                    as.numeric(value)))
}

#' @rdname clp_primal_tolerance
#' @export
clp_max_seconds <- function(model) .Call(C_coinclp_maximum_seconds, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_max_seconds <- function(model, value) {
    invisible(.Call(C_coinclp_set_maximum_seconds, clp_ptr(model), as.numeric(value)))
}

#' @rdname clp_primal_tolerance
#' @export
clp_max_iterations <- function(model)
    .Call(C_coinclp_maximum_iterations, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_max_iterations <- function(model, value) {
    invisible(.Call(C_coinclp_set_maximum_iterations, clp_ptr(model),
                    as.integer(value)))
}

#' @rdname clp_primal_tolerance
#' @export
clp_hit_max_iterations <- function(model)
    .Call(C_coinclp_hit_maximum_iterations, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_small_element_value <- function(model)
    .Call(C_coinclp_small_element_value, clp_ptr(model))

#' @rdname clp_primal_tolerance
#' @export
clp_set_small_element_value <- function(model, value) {
    invisible(.Call(C_coinclp_set_small_element_value, clp_ptr(model),
                    as.numeric(value)))
}

#' Algorithm settings
#'
#' \code{clp_log_level()} controls how much Clp prints: 0 silent, 1 just the
#' final line, 2 factorizations, 3 more, 4 verbose.  \code{clp_scaling()}
#' selects the scaling mode (0 off, 1 equilibrium, 2 geometric, 3 auto,
#' 4 dynamic).  \code{clp_perturbation()} and \code{clp_algorithm()} expose
#' the corresponding simplex settings.
#'
#' @param model A \code{"clp_model"} object.
#' @param value The new value.
#' @return The getters return an integer; the setters \code{NULL} invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_set_log_level(model, 0L)
#' clp_log_level(model)
#' clp_free(model)
clp_log_level <- function(model) .Call(C_coinclp_log_level, clp_ptr(model))

#' @rdname clp_log_level
#' @export
clp_set_log_level <- function(model, value) {
    invisible(.Call(C_coinclp_set_log_level, clp_ptr(model), as.integer(value)))
}

#' @rdname clp_log_level
#' @export
clp_scaling <- function(model) .Call(C_coinclp_scaling_flag, clp_ptr(model))

#' @rdname clp_log_level
#' @export
clp_set_scaling <- function(model, value) {
    invisible(.Call(C_coinclp_set_scaling, clp_ptr(model), as.integer(value)))
}

#' @rdname clp_log_level
#' @export
clp_perturbation <- function(model) .Call(C_coinclp_perturbation, clp_ptr(model))

#' @rdname clp_log_level
#' @export
clp_set_perturbation <- function(model, value) {
    invisible(.Call(C_coinclp_set_perturbation, clp_ptr(model), as.integer(value)))
}

#' @rdname clp_log_level
#' @export
clp_algorithm <- function(model) .Call(C_coinclp_algorithm, clp_ptr(model))

#' @rdname clp_log_level
#' @export
clp_set_algorithm <- function(model, value) {
    invisible(.Call(C_coinclp_set_algorithm, clp_ptr(model), as.integer(value)))
}

#' @rdname clp_log_level
#' @export
clp_iterations <- function(model) .Call(C_coinclp_number_iterations, clp_ptr(model))

#' @rdname clp_log_level
#' @export
clp_set_iterations <- function(model, value) {
    invisible(.Call(C_coinclp_set_number_iterations, clp_ptr(model),
                    as.integer(value)))
}

# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------

#' Solution status
#'
#' \code{clp_status()} returns Clp's problem status: 0 optimal, 1 primal
#' infeasible, 2 dual infeasible (unbounded), 3 stopped on a limit,
#' 4 stopped because of errors, and -1 when the problem has not been solved.
#' \code{clp_status_message()} turns such a code into a short description.
#'
#' @param model A \code{"clp_model"} object.
#' @param status An integer status code.
#' @param value A new status code.
#' @return \code{clp_status()} and \code{clp_secondary_status()} return an
#'   integer, \code{clp_status_message()} a character string, the setters
#'   \code{NULL} invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, obj = 1, rowlb = 1)
#' clp_initial_solve(model)
#' clp_status_message(clp_status(model))
#' clp_free(model)
clp_status <- function(model) .Call(C_coinclp_status, clp_ptr(model))

#' @rdname clp_status
#' @export
clp_set_status <- function(model, value) {
    invisible(.Call(C_coinclp_set_problem_status, clp_ptr(model), as.integer(value)))
}

#' @rdname clp_status
#' @export
clp_secondary_status <- function(model)
    .Call(C_coinclp_secondary_status, clp_ptr(model))

#' @rdname clp_status
#' @export
clp_set_secondary_status <- function(model, value) {
    invisible(.Call(C_coinclp_set_secondary_status, clp_ptr(model),
                    as.integer(value)))
}

#' @rdname clp_status
#' @export
clp_status_message <- function(status) {
    messages <- c("optimal",
                  "primal infeasible",
                  "dual infeasible (unbounded)",
                  "stopped on iterations or time",
                  "stopped because of errors",
                  "stopped by an event handler")
    status <- as.integer(status)
    out <- rep("unknown", length(status))
    out[status == -1L] <- "not solved"
    known <- !is.na(status) & status >= 0L & status <= 5L
    out[known] <- messages[status[known] + 1L]
    out
}

#' Feasibility and optimality flags
#'
#' Convenience predicates over the last solve, mirroring the OSI-style
#' queries in the Clp callable library.
#'
#' @param model A \code{"clp_model"} object.
#' @return A single logical value.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, obj = 1, rowlb = 1)
#' clp_initial_solve(model)
#' clp_is_proven_optimal(model)
#' clp_free(model)
clp_is_proven_optimal <- function(model)
    .Call(C_coinclp_is_proven_optimal, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_is_proven_primal_infeasible <- function(model)
    .Call(C_coinclp_is_proven_primal_infeasible, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_is_proven_dual_infeasible <- function(model)
    .Call(C_coinclp_is_proven_dual_infeasible, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_is_abandoned <- function(model) .Call(C_coinclp_is_abandoned, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_is_primal_objective_limit_reached <- function(model)
    .Call(C_coinclp_is_primal_objective_limit_reached, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_is_dual_objective_limit_reached <- function(model)
    .Call(C_coinclp_is_dual_objective_limit_reached, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_is_iteration_limit_reached <- function(model)
    .Call(C_coinclp_is_iteration_limit_reached, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_primal_feasible <- function(model)
    .Call(C_coinclp_primal_feasible, clp_ptr(model))

#' @rdname clp_is_proven_optimal
#' @export
clp_dual_feasible <- function(model) .Call(C_coinclp_dual_feasible, clp_ptr(model))

#' Infeasibility measures
#'
#' @param model A \code{"clp_model"} object.
#' @return A number of violations, or the sum of their sizes.
#' @export
#' @examples
#' model <- clp_model()
#' clp_load_problem(model, 1, 1, c(0L, 1L), 0L, 1, obj = 1, rowlb = 1)
#' clp_initial_solve(model)
#' clp_sum_primal_infeasibilities(model)
#' clp_free(model)
clp_sum_primal_infeasibilities <- function(model)
    .Call(C_coinclp_sum_primal_infeasibilities, clp_ptr(model))

#' @rdname clp_sum_primal_infeasibilities
#' @export
clp_sum_dual_infeasibilities <- function(model)
    .Call(C_coinclp_sum_dual_infeasibilities, clp_ptr(model))

#' @rdname clp_sum_primal_infeasibilities
#' @export
clp_num_primal_infeasibilities <- function(model)
    .Call(C_coinclp_number_primal_infeasibilities, clp_ptr(model))

#' @rdname clp_sum_primal_infeasibilities
#' @export
clp_num_dual_infeasibilities <- function(model)
    .Call(C_coinclp_number_dual_infeasibilities, clp_ptr(model))

#' @rdname clp_sum_primal_infeasibilities
#' @export
clp_check_solution <- function(model) {
    invisible(.Call(C_coinclp_check_solution, clp_ptr(model)))
}
