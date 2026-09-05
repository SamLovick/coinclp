## Model objects: creation, identity and printing.

#' The value Clp treats as infinite
#'
#' Clp represents an infinite bound by 1e30 rather than by \code{Inf}.
#' \code{clp_inf()} returns that value, and the high level interface
#' translates \code{Inf} and \code{-Inf} to it automatically.
#'
#' @return A single number, 1e30.
#' @export
#' @examples
#' clp_inf()
clp_inf <- function() 1e30

## Bounds coming from R may be infinite; Clp wants its own sentinel.
finite_bound <- function(x) {
    x[is.infinite(x) & x > 0] <- clp_inf()
    x[is.infinite(x) & x < 0] <- -clp_inf()
    x
}

## Bounds coming back from Clp use the sentinel; R users expect Inf.
infinite_bound <- function(x) {
    x[x >= clp_inf()] <- Inf
    x[x <= -clp_inf()] <- -Inf
    x
}

#' Create a Clp model
#'
#' Creates an empty problem in the COIN-OR Clp callable library.  The result
#' is an external pointer with class \code{"clp_model"}; the underlying
#' solver object is released when the model is garbage collected, or
#' immediately by \code{\link{clp_free}}.
#'
#' New models start silent, unlike Clp's own default: raise the message level
#' with \code{\link{clp_set_log_level}} to see the solver's reporting.
#'
#' @return An object of class \code{"clp_model"}.
#' @seealso \code{\link{clp_solve}} for a one-call interface that builds and
#'   solves a model for you, \code{\link{clp_load_problem}} for filling a
#'   model in yourself.
#' @export
#' @examples
#' model <- clp_model()
#' clp_num_cols(model)
#' clp_free(model)
clp_model <- function() {
    ptr <- .Call(C_coinclp_new_model)
    class(ptr) <- "clp_model"
    ptr
}

#' Release a Clp model
#'
#' Frees the solver memory behind a model.  This happens automatically when
#' the model is garbage collected; call it explicitly when working with many
#' or large models.  Calling it twice is harmless, but using the model
#' afterwards is an error.
#'
#' @param model A \code{"clp_model"} object.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' model <- clp_model()
#' clp_free(model)
#' clp_is_open(model)
clp_free <- function(model) {
    invisible(.Call(C_coinclp_delete_model, clp_ptr(model)))
}

#' Is a model still usable?
#'
#' @param model A \code{"clp_model"} object.
#' @return \code{TRUE} if the model still holds a live Clp problem.
#' @export
#' @examples
#' model <- clp_model()
#' clp_is_open(model)
clp_is_open <- function(model) {
    .Call(C_coinclp_model_is_open, clp_ptr(model))
}

## Accept either a clp_model or a clpAPI-style clpPtr object.
clp_ptr <- function(model) {
    if (typeof(model) == "externalptr") return(model)
    if (isS4(model) && methods::is(model, "clpPtr")) return(model@clpPointer)
    stop("'model' must be a Clp model created by clp_model()", call. = FALSE)
}

#' @export
print.clp_model <- function(x, ...) {
    if (!clp_is_open(x)) {
        cat("<clp_model: deleted>\n")
        return(invisible(x))
    }
    direction <- if (clp_optimization_direction(x) < 0) "maximise" else "minimise"
    cat("<clp_model>\n")
    cat("  rows:      ", clp_num_rows(x), "\n", sep = "")
    cat("  columns:   ", clp_num_cols(x), "\n", sep = "")
    cat("  nonzeros:  ", clp_num_elements(x), "\n", sep = "")
    cat("  direction: ", direction, "\n", sep = "")
    st <- clp_status(x)
    cat("  status:    ", st, " (", clp_status_message(st), ")\n", sep = "")
    invisible(x)
}

#' @export
format.clp_model <- function(x, ...) {
    if (!clp_is_open(x)) return("<clp_model: deleted>")
    sprintf("<clp_model: %d rows, %d columns, %.0f nonzeros>",
            clp_num_rows(x), clp_num_cols(x), clp_num_elements(x))
}

#' Options for Clp's presolve and algorithm choice
#'
#' Creates a \code{ClpSolve} options object, the structure Clp uses to steer
#' \code{\link{clp_initial_solve_with_options}}.  Options are set with the
#' \code{clp_options_*} functions.
#'
#' @return An external pointer with class \code{"clp_options"}.
#' @export
#' @examples
#' opts <- clp_options()
#' clp_options_set_solve_type(opts, 1L)   # primal simplex
#' clp_options_get_solve_type(opts)
clp_options <- function() {
    ptr <- .Call(C_coinclp_new_options)
    class(ptr) <- "clp_options"
    ptr
}

#' Release a Clp options object
#'
#' @param options A \code{"clp_options"} object.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' opts <- clp_options()
#' clp_options_free(opts)
clp_options_free <- function(options) {
    invisible(.Call(C_coinclp_delete_options, options))
}

#' @export
print.clp_options <- function(x, ...) {
    cat("<clp_options>\n")
    cat("  solve type:    ", clp_options_get_solve_type(x), "\n", sep = "")
    cat("  presolve type: ", clp_options_get_presolve_type(x), "\n", sep = "")
    invisible(x)
}
