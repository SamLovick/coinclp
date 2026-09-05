## Drop-in replacements for the interface of the archived clpAPI package.
##
## Same function names, same argument names, same 0-based indexing, so that
## code written against clpAPI - including ROI.plugin.clp - runs unchanged.
## New code should prefer the clp_* interface.

#' A pointer to a Clp problem, clpAPI style
#'
#' An S4 class with the same shape as the \code{clpPtr} class of the archived
#' \pkg{clpAPI} package, so that code written against that package keeps
#' working.  \code{\link{initProbCLP}} creates one.
#'
#' @slot clpPtrType A string describing the pointer, \code{"clp_prob"}.
#' @slot clpPointer The external pointer to the Clp model.
#' @name clpPtr-class
#' @exportClass clpPtr
#' @examples
#' lp <- initProbCLP()
#' isCLPpointer(lp)
#' delProbCLP(lp)
methods::setClass("clpPtr",
                  methods::representation(clpPtrType = "character",
                                          clpPointer = "externalptr"))

#' Accessors for clpPtr objects
#'
#' @param object A \code{\linkS4class{clpPtr}} object.
#' @param value A replacement value.
#' @return \code{clpPointer()} the external pointer, \code{clpPtrType()} a
#'   string, \code{isNULLpointerCLP()} and \code{isCLPpointer()} a logical.
#' @name clpPtr-accessors
#' @aliases clpPointer,clpPtr-method clpPtrType,clpPtr-method
#'   clpPtrType<-,clpPtr,character-method isNULLpointerCLP,clpPtr-method
#'   isCLPpointer,clpPtr-method show,clpPtr-method
#' @examples
#' lp <- initProbCLP()
#' clpPtrType(lp)
#' delProbCLP(lp)
NULL

#' @rdname clpPtr-accessors
#' @export
methods::setGeneric("clpPointer", function(object) standardGeneric("clpPointer"))

#' @rdname clpPtr-accessors
#' @export
methods::setGeneric("clpPtrType", function(object) standardGeneric("clpPtrType"))

#' @rdname clpPtr-accessors
#' @export
methods::setGeneric("clpPtrType<-",
                    function(object, value) standardGeneric("clpPtrType<-"))

#' @rdname clpPtr-accessors
#' @export
methods::setGeneric("isNULLpointerCLP",
                    function(object) standardGeneric("isNULLpointerCLP"))

#' @rdname clpPtr-accessors
#' @export
methods::setGeneric("isCLPpointer", function(object) standardGeneric("isCLPpointer"))

methods::setMethod("clpPointer", signature(object = "clpPtr"),
                   function(object) object@clpPointer)

methods::setMethod("clpPtrType", signature(object = "clpPtr"),
                   function(object) object@clpPtrType)

methods::setMethod("clpPtrType<-", signature(object = "clpPtr", value = "character"),
                   function(object, value) {
                       object@clpPtrType <- value
                       object
                   })

methods::setMethod("isNULLpointerCLP", signature(object = "clpPtr"),
                   function(object) !.Call(C_coinclp_model_is_open,
                                           object@clpPointer))

methods::setMethod("isCLPpointer", signature(object = "clpPtr"),
                   function(object) methods::is(object, "clpPtr"))

methods::setMethod("show", signature(object = "clpPtr"), function(object) {
    cat("object of class ", dQuote("clpPtr"), ": ", object@clpPtrType, "\n",
        sep = "")
    invisible(object)
})

#' Create and delete a problem, clpAPI style
#'
#' As in \code{\link{clp_model}}, a new problem starts with Clp's message
#' level at 0; \code{setLogLevelCLP()} turns the solver's reporting on.
#'
#' @param ptrtype A string stored in the returned object.
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @return \code{initProbCLP()} returns a \code{\linkS4class{clpPtr}};
#'   \code{delProbCLP()} returns \code{NULL} invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' setLogLevelCLP(lp, 0)
#' delProbCLP(lp)
initProbCLP <- function(ptrtype = "clp_prob") {
    methods::new("clpPtr", clpPtrType = as.character(ptrtype),
                 clpPointer = .Call(C_coinclp_new_model))
}

#' @rdname initProbCLP
#' @export
delProbCLP <- function(lp) {
    invisible(.Call(C_coinclp_delete_model, clp_ptr(lp)))
}

#' Build a problem, clpAPI style
#'
#' Column-major, 0-based arguments, exactly as in \pkg{clpAPI}:
#' \code{ia} holds the column starts, \code{ja} the row indices and
#' \code{ra} the matrix entries.
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param ncols,nrows Problem dimensions.
#' @param ia Integer vector of column starts, length \code{ncols + 1}.
#' @param ja Integer vector of 0-based row indices.
#' @param ra Numeric vector of matrix entries.
#' @param lb,ub Column bounds, or \code{NULL}.
#' @param obj_coef Objective coefficients, or \code{NULL}.
#' @param rlb,rub Row bounds, or \code{NULL}.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' loadProblemCLP(lp, 2, 1, c(0, 1, 2), c(0, 0), c(1, 1),
#'                lb = c(0, 0), ub = c(1e30, 1e30), obj_coef = c(-1, -2),
#'                rlb = -1e30, rub = 3)
#' solveInitialCLP(lp)
#' getObjValCLP(lp)
#' delProbCLP(lp)
loadProblemCLP <- function(lp, ncols, nrows, ia, ja, ra,
                           lb = NULL, ub = NULL, obj_coef = NULL,
                           rlb = NULL, rub = NULL) {
    clp_load_problem(lp, ncols, nrows, ia, ja, ra,
                     collb = lb, colub = ub, obj = obj_coef,
                     rowlb = rlb, rowub = rub)
}

#' @rdname loadProblemCLP
#' @export
loadMatrixCLP <- function(lp, ncols, nrows, ia, ja, ra) {
    clp_load_problem(lp, ncols, nrows, ia, ja, ra)
}

#' Change the size of a problem, clpAPI style
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param nrows,ncols New dimensions.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' resizeCLP(lp, 2, 2)
#' getNumRowsCLP(lp)
#' delProbCLP(lp)
resizeCLP <- function(lp, nrows, ncols) clp_resize(lp, nrows, ncols)

#' Add and delete rows and columns, clpAPI style
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param nrows,ncols Number of rows or columns to add.
#' @param lb,ub Bounds for the new rows or columns.
#' @param obj Objective coefficients for the new columns.
#' @param rowst,colst Integer vectors of starts, length \code{n + 1}.
#' @param cols,rows 0-based indices of the new entries.
#' @param val Numeric vector of the new entries.
#' @param num Number of rows or columns to delete.
#' @param i,j 0-based positions to delete.
#' @return \code{NULL}, invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' loadMatrixCLP(lp, 2, 0, c(0, 0, 0), integer(0), numeric(0))
#' addRowsCLP(lp, 1, -1e30, 4, c(0, 2), c(0, 1), c(1, 1))
#' getNumRowsCLP(lp)
#' delProbCLP(lp)
addRowsCLP <- function(lp, nrows, lb, ub, rowst, cols, val) {
    clp_add_rows(lp, nrows, rowlb = lb, rowub = ub,
                 rowstarts = rowst, columns = cols, elements = val)
}

#' @rdname addRowsCLP
#' @export
addColsCLP <- function(lp, ncols, lb, ub, obj, colst, rows, val) {
    clp_add_columns(lp, ncols, collb = lb, colub = ub, obj = obj,
                    colstarts = colst, rows = rows, elements = val)
}

#' @rdname addRowsCLP
#' @export
delRowsCLP <- function(lp, num, i) {
    clp_delete_rows(lp, utils::head(as.integer(i), as.integer(num)))
}

#' @rdname addRowsCLP
#' @export
delColsCLP <- function(lp, num, j) {
    clp_delete_columns(lp, utils::head(as.integer(j), as.integer(num)))
}

#' Problem data, clpAPI style
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param objCoef Objective coefficients.
#' @param lb,ub Column bounds.
#' @param rlb,rub Row bounds.
#' @return The getters return numeric or integer vectors; the setters
#'   \code{NULL} invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' loadMatrixCLP(lp, 2, 0, c(0, 0, 0), integer(0), numeric(0))
#' chgObjCoefsCLP(lp, c(1, 2))
#' getObjCoefsCLP(lp)
#' delProbCLP(lp)
getNumRowsCLP <- function(lp) clp_num_rows(lp)

#' @rdname getNumRowsCLP
#' @export
getNumColsCLP <- function(lp) clp_num_cols(lp)

#' @rdname getNumRowsCLP
#' @export
getNumNnzCLP <- function(lp) clp_num_elements(lp)

#' @rdname getNumRowsCLP
#' @export
getObjCoefsCLP <- function(lp) clp_objective(lp)

#' @rdname getNumRowsCLP
#' @export
chgObjCoefsCLP <- function(lp, objCoef) clp_set_objective(lp, objCoef)

#' @rdname getNumRowsCLP
#' @export
getColLowerCLP <- function(lp) clp_col_lower(lp)

#' @rdname getNumRowsCLP
#' @export
chgColLowerCLP <- function(lp, lb) clp_set_col_lower(lp, lb)

#' @rdname getNumRowsCLP
#' @export
getColUpperCLP <- function(lp) clp_col_upper(lp)

#' @rdname getNumRowsCLP
#' @export
chgColUpperCLP <- function(lp, ub) clp_set_col_upper(lp, ub)

#' @rdname getNumRowsCLP
#' @export
getRowLowerCLP <- function(lp) clp_row_lower(lp)

#' @rdname getNumRowsCLP
#' @export
chgRowLowerCLP <- function(lp, rlb) clp_set_row_lower(lp, rlb)

#' @rdname getNumRowsCLP
#' @export
getRowUpperCLP <- function(lp) clp_row_upper(lp)

#' @rdname getNumRowsCLP
#' @export
chgRowUpperCLP <- function(lp, rub) clp_set_row_upper(lp, rub)

#' @rdname getNumRowsCLP
#' @export
getVecStartCLP <- function(lp) clp_vector_starts(lp)

#' @rdname getNumRowsCLP
#' @export
getVecLenCLP <- function(lp) clp_vector_lengths(lp)

#' @rdname getNumRowsCLP
#' @export
getIndCLP <- function(lp) clp_indices(lp)

#' @rdname getNumRowsCLP
#' @export
getNnzCLP <- function(lp) clp_elements(lp)

#' Solver settings, clpAPI style
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param lpdir 1 to minimise, -1 to maximise.
#' @param amount Log level, 0 to 4.
#' @param mode Scaling mode.
#' @param iterations Iteration count or limit.
#' @param seconds Time limit in seconds.
#' @return The getters return a number; the setters \code{NULL} invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' setObjDirCLP(lp, -1)
#' getObjDirCLP(lp)
#' delProbCLP(lp)
setObjDirCLP <- function(lp, lpdir) clp_set_optimization_direction(lp, lpdir)

#' @rdname setObjDirCLP
#' @export
getObjDirCLP <- function(lp) clp_optimization_direction(lp)

#' @rdname setObjDirCLP
#' @export
setLogLevelCLP <- function(lp, amount) clp_set_log_level(lp, amount)

#' @rdname setObjDirCLP
#' @export
getLogLevelCLP <- function(lp) clp_log_level(lp)

#' @rdname setObjDirCLP
#' @export
scaleModelCLP <- function(lp, mode) clp_set_scaling(lp, mode)

#' @rdname setObjDirCLP
#' @export
getScaleFlagCLP <- function(lp) clp_scaling(lp)

#' @rdname setObjDirCLP
#' @export
setNumberIterationsCLP <- function(lp, iterations) clp_set_iterations(lp, iterations)

#' @rdname setObjDirCLP
#' @export
setMaximumIterationsCLP <- function(lp, iterations)
    clp_set_max_iterations(lp, iterations)

#' @rdname setObjDirCLP
#' @export
getMaximumIterationsCLP <- function(lp) clp_max_iterations(lp)

#' @rdname setObjDirCLP
#' @export
getHitMaximumIterationsCLP <- function(lp) clp_hit_max_iterations(lp)

#' @rdname setObjDirCLP
#' @export
setMaximumSecondsCLP <- function(lp, seconds) clp_set_max_seconds(lp, seconds)

#' @rdname setObjDirCLP
#' @export
getMaximumSecondsCLP <- function(lp) clp_max_seconds(lp)

#' Solve a problem, clpAPI style
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param ifValP Pass 1 for a values pass, 0 otherwise.
#' @param thd Effort level for the idiot crash.
#' @return An integer return code from Clp; \code{idiotCLP()} returns
#'   \code{NULL} invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' loadProblemCLP(lp, 1, 1, c(0, 1), 0, 1, obj_coef = -1, rlb = -1e30, rub = 2)
#' setLogLevelCLP(lp, 0)
#' solveInitialCLP(lp)
#' getColPrimCLP(lp)
#' delProbCLP(lp)
solveInitialCLP <- function(lp) clp_initial_solve(lp)

#' @rdname solveInitialCLP
#' @export
solveInitialDualCLP <- function(lp) clp_initial_dual_solve(lp)

#' @rdname solveInitialCLP
#' @export
solveInitialPrimalCLP <- function(lp) clp_initial_primal_solve(lp)

#' @rdname solveInitialCLP
#' @export
solveInitialBarrierCLP <- function(lp) clp_initial_barrier_solve(lp)

#' @rdname solveInitialCLP
#' @export
solveInitialBarrierNoCrossCLP <- function(lp)
    clp_initial_barrier_no_cross_solve(lp)

#' @rdname solveInitialCLP
#' @export
primalCLP <- function(lp, ifValP = 0) clp_primal_simplex(lp, ifValP)

#' @rdname solveInitialCLP
#' @export
dualCLP <- function(lp, ifValP = 0) clp_dual_simplex(lp, ifValP)

#' @rdname solveInitialCLP
#' @export
idiotCLP <- function(lp, thd = 0) clp_idiot(lp, thd)

#' Solutions and status, clpAPI style
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param code A status or return code.
#' @return Numeric vectors for the solution accessors, an integer for
#'   \code{getSolStatusCLP()}, a string for the code descriptions.
#' @export
#' @examples
#' lp <- initProbCLP()
#' loadProblemCLP(lp, 1, 1, c(0, 1), 0, 1, obj_coef = -1, rlb = -1e30, rub = 2)
#' setLogLevelCLP(lp, 0)
#' solveInitialCLP(lp)
#' status_codeCLP(getSolStatusCLP(lp))
#' delProbCLP(lp)
getSolStatusCLP <- function(lp) clp_status(lp)

#' @rdname getSolStatusCLP
#' @export
getObjValCLP <- function(lp) clp_objective_value(lp)

#' @rdname getSolStatusCLP
#' @export
getColPrimCLP <- function(lp) clp_col_solution(lp)

#' @rdname getSolStatusCLP
#' @export
getColDualCLP <- function(lp) clp_reduced_costs(lp)

#' @rdname getSolStatusCLP
#' @export
getRowPrimCLP <- function(lp) clp_row_activity(lp)

#' @rdname getSolStatusCLP
#' @export
getRowDualCLP <- function(lp) clp_row_price(lp)

#' @rdname getSolStatusCLP
#' @export
status_codeCLP <- function(code) {
    code <- as.integer(code)
    if (is.na(code)) return("unknown status code: NA")
    switch(as.character(code),
           "0" = "solution is optimal",
           "1" = "solution is primal infeasible",
           "2" = "solution is dual infeasible",
           "3" = "stopped on iterations etc",
           "4" = "stopped due to errors",
           paste("unknown status code:", code))
}

#' @rdname getSolStatusCLP
#' @export
return_codeCLP <- function(code) {
    code <- as.integer(code)
    if (!is.na(code) && code == 0L) "solution process was successful"
    else paste("Failed to obtain solution, unknown error code:", code)
}

#' Names and files, clpAPI style
#'
#' @param lp A \code{\linkS4class{clpPtr}} object.
#' @param cnames,rnames Character vectors of column and row names.
#' @param pname A problem name.
#' @param i,j 0-based row and column positions.
#' @param rname,cname A single name.
#' @param fname A file name.
#' @param keepNames Keep the names found in an MPS file.
#' @param ignoreErrors Carry on after errors in an MPS file.
#' @param formatType,numberAcross,objSense Passed on to the MPS writer.
#' @param prefix A prefix for \code{printModelCLP()}.
#' @param el A new matrix coefficient.
#' @param keepZero Keep zero entries in the sparse structure.
#' @param funcname Name of an optional Clp entry point.
#' @return Character or integer values as in \pkg{clpAPI}; the setters return
#'   \code{NULL} invisibly.
#' @export
#' @examples
#' lp <- initProbCLP()
#' loadMatrixCLP(lp, 2, 1, c(0, 1, 2), c(0, 0), c(1, 1))
#' copyNamesCLP(lp, c("x", "y"), "budget")
#' lengthNamesCLP(lp)
#' delProbCLP(lp)
copyNamesCLP <- function(lp, cnames, rnames) clp_set_names(lp, rnames, cnames)

#' @rdname copyNamesCLP
#' @export
dropNamesCLP <- function(lp) clp_drop_names(lp)

#' @rdname copyNamesCLP
#' @export
lengthNamesCLP <- function(lp) clp_length_names(lp)

#' @rdname copyNamesCLP
#' @export
probNameCLP <- function(lp, pname) clp_set_problem_name(lp, pname)

#' @rdname copyNamesCLP
#' @export
setRowNameCLP <- function(lp, i, rname) clp_set_row_name(lp, i, rname)

#' @rdname copyNamesCLP
#' @export
setColNameCLP <- function(lp, j, cname) clp_set_col_name(lp, j, cname)

#' @rdname copyNamesCLP
#' @export
printModelCLP <- function(lp, prefix = "CLPmodel") clp_print_model(lp, prefix)

#' @rdname copyNamesCLP
#' @export
readMPSCLP <- function(lp, fname, keepNames = TRUE, ignoreErrors = FALSE)
    clp_read_mps(lp, fname, keepNames, ignoreErrors)

#' @rdname copyNamesCLP
#' @export
writeMPSCLP <- function(lp, fname, formatType = 0, numberAcross = 1,
                        objSense = 1) {
    clp_write_mps(lp, fname, format_type = formatType,
                  number_across = numberAcross, obj_sense = objSense)
}

#' @rdname copyNamesCLP
#' @export
saveModelCLP <- function(lp, fname) clp_save_model(lp, fname)

#' @rdname copyNamesCLP
#' @export
restoreModelCLP <- function(lp, fname) clp_restore_model(lp, fname)

#' @rdname copyNamesCLP
#' @export
modifyCoefficientCLP <- function(lp, i, j, el, keepZero = TRUE)
    clp_modify_coefficient(lp, i, j, el, keepZero)

#' @rdname copyNamesCLP
#' @export
isAvailableFuncCLP <- function(funcname) {
    features <- clp_features()
    known <- c(Clp_writeMps = "write_mps",
               writeMPS = "write_mps",
               Clp_modifyCoefficient = "modify_coefficient",
               modifyCoefficient = "modify_coefficient",
               Clp_setRowName = "set_names",
               Clp_setColumnName = "set_names",
               setRowName = "set_names",
               setColumnName = "set_names")
    key <- known[as.character(funcname)]
    out <- ifelse(is.na(key), FALSE, features[key])
    stats::setNames(as.logical(out), as.character(funcname))
}

#' The Clp version, clpAPI style
#'
#' @return The version of the Clp library as a string.
#' @export
#' @examples
#' versionCLP()
versionCLP <- function() clp_version()$version
