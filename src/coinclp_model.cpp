/* coinclp: model life cycle, problem construction and data access.
 *
 * Temporary buffers use R_alloc() rather than C++ containers: Rf_error()
 * unwinds by longjmp and would skip destructors.
 */

#include "coinclp.h"
#include <limits.h>
#include <string.h>

static SEXP model_tag(void)   { return Rf_install("coinclp_model");   }
static SEXP options_tag(void) { return Rf_install("coinclp_options"); }

extern "C" Clp_Simplex *coinclp_model(SEXP ptr)
{
    if (TYPEOF(ptr) != EXTPTRSXP || R_ExternalPtrTag(ptr) != model_tag())
        Rf_error("not a Clp model object");
    Clp_Simplex *model = (Clp_Simplex *) R_ExternalPtrAddr(ptr);
    if (model == NULL)
        Rf_error("this Clp model has been deleted; create a new one with clp_model()");
    return model;
}

extern "C" Clp_Solve *coinclp_options(SEXP ptr)
{
    if (TYPEOF(ptr) != EXTPTRSXP || R_ExternalPtrTag(ptr) != options_tag())
        Rf_error("not a Clp options object");
    Clp_Solve *opt = (Clp_Solve *) R_ExternalPtrAddr(ptr);
    if (opt == NULL)
        Rf_error("this Clp options object has been deleted");
    return opt;
}

/* ------------------------------------------------------------------ */
/* small helpers                                                       */
/* ------------------------------------------------------------------ */

static int checked_count(R_xlen_t n, const char *what)
{
    if (n > INT_MAX)
        Rf_error("'%s' is too long for the Clp interface (%.0f elements)",
                 what, (double) n);
    return (int) n;
}

/* A REAL vector of the expected length, or NULL for R's NULL (Clp then
   applies its own defaults). */
static const double *real_or_null(SEXP x, int expected, const char *what)
{
    if (x == R_NilValue) return NULL;
    if (TYPEOF(x) != REALSXP)
        Rf_error("'%s' must be a numeric vector or NULL", what);
    if (expected >= 0 && XLENGTH(x) != expected)
        Rf_error("'%s' has length %.0f, expected %d",
                 what, (double) XLENGTH(x), expected);
    return REAL(x);
}

/* Copy an R integer vector into a CoinBigIndex buffer.  CoinBigIndex is int
   in a default Clp build but may be long or long long. */
static const CoinBigIndex *as_big_index(SEXP x, const char *what)
{
    if (x == R_NilValue) return NULL;
    if (TYPEOF(x) != INTSXP)
        Rf_error("'%s' must be an integer vector", what);
    R_xlen_t n = XLENGTH(x);
    CoinBigIndex *out = (CoinBigIndex *) R_alloc(n > 0 ? n : 1,
                                                 sizeof(CoinBigIndex));
    const int *src = INTEGER(x);
    for (R_xlen_t k = 0; k < n; k++) {
        if (src[k] == NA_INTEGER)
            Rf_error("'%s' must not contain missing values", what);
        out[k] = (CoinBigIndex) src[k];
    }
    return out;
}

/* Copy n doubles out of the solver.  A NULL source becomes numeric(0), which
   is what Clp hands back before a problem has been loaded. */
static SEXP copy_reals(const double *src, int n)
{
    if (src == NULL || n <= 0) return Rf_allocVector(REALSXP, 0);
    SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
    memcpy(REAL(out), src, (size_t) n * sizeof(double));
    UNPROTECT(1);
    return out;
}

static SEXP copy_ints(const int *src, int n)
{
    if (src == NULL || n <= 0) return Rf_allocVector(INTSXP, 0);
    SEXP out = PROTECT(Rf_allocVector(INTSXP, n));
    memcpy(INTEGER(out), src, (size_t) n * sizeof(int));
    UNPROTECT(1);
    return out;
}

/* ------------------------------------------------------------------ */
/* life cycle                                                          */
/* ------------------------------------------------------------------ */

static void model_finalizer(SEXP ptr)
{
    if (TYPEOF(ptr) != EXTPTRSXP) return;
    Clp_Simplex *model = (Clp_Simplex *) R_ExternalPtrAddr(ptr);
    if (model != NULL) {
        Clp_deleteModel(model);
        R_ClearExternalPtr(ptr);
    }
}

static void options_finalizer(SEXP ptr)
{
    if (TYPEOF(ptr) != EXTPTRSXP) return;
    Clp_Solve *opt = (Clp_Solve *) R_ExternalPtrAddr(ptr);
    if (opt != NULL) {
        ClpSolve_delete(opt);
        R_ClearExternalPtr(ptr);
    }
}

extern "C" SEXP coinclp_new_model(void)
{
    Clp_Simplex *model = Clp_newModel();
    if (model == NULL) Rf_error("Clp_newModel() failed to allocate a model");
    /* Clp reports to the console by default; an R package should not.
       clp_set_log_level() turns it back on. */
    Clp_setLogLevel(model, 0);
    /* A model straight out of Clp_newModel() has no matrix at all, and the
       matrix accessors dereference it without checking.  Loading an empty
       problem gives every accessor something valid to look at. */
    {
        CoinBigIndex start[1];
        int index[1];
        double value[1];
        start[0] = 0;
        index[0] = 0;
        value[0] = 0.0;
        Clp_loadProblem(model, 0, 0, start, index, value,
                        NULL, NULL, NULL, NULL, NULL);
    }
    SEXP ptr = PROTECT(R_MakeExternalPtr(model, model_tag(), R_NilValue));
    R_RegisterCFinalizerEx(ptr, model_finalizer, TRUE);
    UNPROTECT(1);
    return ptr;
}

extern "C" SEXP coinclp_delete_model(SEXP ptr)
{
    if (TYPEOF(ptr) != EXTPTRSXP || R_ExternalPtrTag(ptr) != model_tag())
        Rf_error("not a Clp model object");
    Clp_Simplex *model = (Clp_Simplex *) R_ExternalPtrAddr(ptr);
    if (model != NULL) {
        Clp_deleteModel(model);
        R_ClearExternalPtr(ptr);
    }
    return R_NilValue;
}

extern "C" SEXP coinclp_model_is_open(SEXP ptr)
{
    int open = (TYPEOF(ptr) == EXTPTRSXP &&
                R_ExternalPtrTag(ptr) == model_tag() &&
                R_ExternalPtrAddr(ptr) != NULL);
    return Rf_ScalarLogical(open);
}

extern "C" SEXP coinclp_new_options(void)
{
    Clp_Solve *opt = ClpSolve_new();
    if (opt == NULL) Rf_error("ClpSolve_new() failed to allocate options");
    SEXP ptr = PROTECT(R_MakeExternalPtr(opt, options_tag(), R_NilValue));
    R_RegisterCFinalizerEx(ptr, options_finalizer, TRUE);
    UNPROTECT(1);
    return ptr;
}

extern "C" SEXP coinclp_delete_options(SEXP ptr)
{
    if (TYPEOF(ptr) != EXTPTRSXP || R_ExternalPtrTag(ptr) != options_tag())
        Rf_error("not a Clp options object");
    Clp_Solve *opt = (Clp_Solve *) R_ExternalPtrAddr(ptr);
    if (opt != NULL) {
        ClpSolve_delete(opt);
        R_ClearExternalPtr(ptr);
    }
    return R_NilValue;
}

/* ------------------------------------------------------------------ */
/* library information                                                 */
/* ------------------------------------------------------------------ */

extern "C" SEXP coinclp_version(void)
{
    const char *ver = Clp_Version();
    SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, 4));
    SET_VECTOR_ELT(out, 0, Rf_mkString(ver == NULL ? "" : ver));
    SET_VECTOR_ELT(out, 1, Rf_ScalarInteger(Clp_VersionMajor()));
    SET_VECTOR_ELT(out, 2, Rf_ScalarInteger(Clp_VersionMinor()));
    SET_VECTOR_ELT(out, 3, Rf_ScalarInteger(Clp_VersionRelease()));
    SET_STRING_ELT(nms, 0, Rf_mkChar("version"));
    SET_STRING_ELT(nms, 1, Rf_mkChar("major"));
    SET_STRING_ELT(nms, 2, Rf_mkChar("minor"));
    SET_STRING_ELT(nms, 3, Rf_mkChar("release"));
    Rf_setAttrib(out, R_NamesSymbol, nms);
    UNPROTECT(2);
    return out;
}

extern "C" SEXP coinclp_features(void)
{
    const char *names[] = { "write_mps", "modify_coefficient",
                            "set_names", "maximum_iterations" };
    int have[] = { COINCLP_HAVE_WRITEMPS, COINCLP_HAVE_MODIFYCOEFFICIENT,
                   COINCLP_HAVE_SETNAMES, 1 };
    SEXP out = PROTECT(Rf_allocVector(LGLSXP, 4));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, 4));
    for (int i = 0; i < 4; i++) {
        LOGICAL(out)[i] = have[i] ? TRUE : FALSE;
        SET_STRING_ELT(nms, i, Rf_mkChar(names[i]));
    }
    Rf_setAttrib(out, R_NamesSymbol, nms);
    UNPROTECT(2);
    return out;
}

/* ------------------------------------------------------------------ */
/* building a problem                                                  */
/* ------------------------------------------------------------------ */

extern "C" SEXP coinclp_load_problem(SEXP ptr, SEXP ncols_, SEXP nrows_,
                                     SEXP start, SEXP index, SEXP value,
                                     SEXP collb, SEXP colub, SEXP obj,
                                     SEXP rowlb, SEXP rowub)
{
    Clp_Simplex *model = coinclp_model(ptr);
    int ncols = Rf_asInteger(ncols_);
    int nrows = Rf_asInteger(nrows_);
    if (ncols == NA_INTEGER || ncols < 0) Rf_error("'ncols' must be a non-negative integer");
    if (nrows == NA_INTEGER || nrows < 0) Rf_error("'nrows' must be a non-negative integer");

    if (TYPEOF(start) != INTSXP)
        Rf_error("'start' must be an integer vector of column starts");
    if (XLENGTH(start) != (R_xlen_t) ncols + 1)
        Rf_error("'start' must have length ncols + 1 (%d), not %.0f",
                 ncols + 1, (double) XLENGTH(start));
    if (TYPEOF(index) != INTSXP)
        Rf_error("'index' must be an integer vector of row indices");
    if (TYPEOF(value) != REALSXP)
        Rf_error("'value' must be a numeric vector of matrix entries");
    if (XLENGTH(index) != XLENGTH(value))
        Rf_error("'index' and 'value' must have the same length");
    checked_count(XLENGTH(value), "value");

    const CoinBigIndex *st = as_big_index(start, "start");

    Clp_loadProblem(model, ncols, nrows, st, INTEGER(index), REAL(value),
                    real_or_null(collb, ncols, "collb"),
                    real_or_null(colub, ncols, "colub"),
                    real_or_null(obj,   ncols, "obj"),
                    real_or_null(rowlb, nrows, "rowlb"),
                    real_or_null(rowub, nrows, "rowub"));
    return R_NilValue;
}

extern "C" SEXP coinclp_load_quadratic(SEXP ptr, SEXP ncols_, SEXP start,
                                       SEXP column, SEXP element)
{
    Clp_Simplex *model = coinclp_model(ptr);
    int ncols = Rf_asInteger(ncols_);
    if (ncols == NA_INTEGER || ncols < 0) Rf_error("'ncols' must be a non-negative integer");
    if (TYPEOF(column) != INTSXP) Rf_error("'column' must be an integer vector");
    if (TYPEOF(element) != REALSXP) Rf_error("'element' must be a numeric vector");
    if (XLENGTH(column) != XLENGTH(element))
        Rf_error("'column' and 'element' must have the same length");
    Clp_loadQuadraticObjective(model, ncols, as_big_index(start, "start"),
                               INTEGER(column), REAL(element));
    return R_NilValue;
}

extern "C" SEXP coinclp_resize(SEXP ptr, SEXP nrows_, SEXP ncols_)
{
    Clp_resize(coinclp_model(ptr), Rf_asInteger(nrows_), Rf_asInteger(ncols_));
    return R_NilValue;
}

extern "C" SEXP coinclp_add_rows(SEXP ptr, SEXP number_, SEXP rowlb, SEXP rowub,
                                 SEXP rowstarts, SEXP columns, SEXP elements)
{
    Clp_Simplex *model = coinclp_model(ptr);
    int number = Rf_asInteger(number_);
    if (number == NA_INTEGER || number < 0)
        Rf_error("'number' must be a non-negative integer");
    if (number == 0) return R_NilValue;
    if (TYPEOF(rowstarts) != INTSXP || XLENGTH(rowstarts) != (R_xlen_t) number + 1)
        Rf_error("'rowstarts' must be an integer vector of length number + 1 (%d)",
                 number + 1);
    if (TYPEOF(columns) != INTSXP) Rf_error("'columns' must be an integer vector");
    if (TYPEOF(elements) != REALSXP) Rf_error("'elements' must be a numeric vector");
    if (XLENGTH(columns) != XLENGTH(elements))
        Rf_error("'columns' and 'elements' must have the same length");

    Clp_addRows(model, number,
                real_or_null(rowlb, number, "rowlb"),
                real_or_null(rowub, number, "rowub"),
                as_big_index(rowstarts, "rowstarts"),
                INTEGER(columns), REAL(elements));
    return R_NilValue;
}

extern "C" SEXP coinclp_add_columns(SEXP ptr, SEXP number_, SEXP collb, SEXP colub,
                                    SEXP obj, SEXP colstarts, SEXP rows, SEXP elements)
{
    Clp_Simplex *model = coinclp_model(ptr);
    int number = Rf_asInteger(number_);
    if (number == NA_INTEGER || number < 0)
        Rf_error("'number' must be a non-negative integer");
    if (number == 0) return R_NilValue;
    if (TYPEOF(colstarts) != INTSXP || XLENGTH(colstarts) != (R_xlen_t) number + 1)
        Rf_error("'colstarts' must be an integer vector of length number + 1 (%d)",
                 number + 1);
    if (TYPEOF(rows) != INTSXP) Rf_error("'rows' must be an integer vector");
    if (TYPEOF(elements) != REALSXP) Rf_error("'elements' must be a numeric vector");
    if (XLENGTH(rows) != XLENGTH(elements))
        Rf_error("'rows' and 'elements' must have the same length");

    Clp_addColumns(model, number,
                   real_or_null(collb, number, "collb"),
                   real_or_null(colub, number, "colub"),
                   real_or_null(obj,   number, "obj"),
                   as_big_index(colstarts, "colstarts"),
                   INTEGER(rows), REAL(elements));
    return R_NilValue;
}

extern "C" SEXP coinclp_delete_rows(SEXP ptr, SEXP which)
{
    Clp_Simplex *model = coinclp_model(ptr);
    if (TYPEOF(which) != INTSXP) Rf_error("'which' must be an integer vector");
    int n = checked_count(XLENGTH(which), "which");
    if (n > 0) Clp_deleteRows(model, n, INTEGER(which));
    return R_NilValue;
}

extern "C" SEXP coinclp_delete_columns(SEXP ptr, SEXP which)
{
    Clp_Simplex *model = coinclp_model(ptr);
    if (TYPEOF(which) != INTSXP) Rf_error("'which' must be an integer vector");
    int n = checked_count(XLENGTH(which), "which");
    if (n > 0) Clp_deleteColumns(model, n, INTEGER(which));
    return R_NilValue;
}

/* ------------------------------------------------------------------ */
/* dimensions and problem data                                         */
/* ------------------------------------------------------------------ */

extern "C" SEXP coinclp_number_rows(SEXP ptr)
{ return Rf_ScalarInteger(Clp_numberRows(coinclp_model(ptr))); }

extern "C" SEXP coinclp_number_columns(SEXP ptr)
{ return Rf_ScalarInteger(Clp_numberColumns(coinclp_model(ptr))); }

extern "C" SEXP coinclp_number_elements(SEXP ptr)
{ return Rf_ScalarReal((double) Clp_getNumElements(coinclp_model(ptr))); }

extern "C" SEXP coinclp_objective(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_objective(m), Clp_numberColumns(m));
}

extern "C" SEXP coinclp_column_lower(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_columnLower(m), Clp_numberColumns(m));
}

extern "C" SEXP coinclp_column_upper(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_columnUpper(m), Clp_numberColumns(m));
}

extern "C" SEXP coinclp_row_lower(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_rowLower(m), Clp_numberRows(m));
}

extern "C" SEXP coinclp_row_upper(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_rowUpper(m), Clp_numberRows(m));
}

extern "C" SEXP coinclp_chg_objective(SEXP ptr, SEXP value)
{
    Clp_Simplex *m = coinclp_model(ptr);
    Clp_chgObjCoefficients(m, real_or_null(value, Clp_numberColumns(m), "value"));
    return R_NilValue;
}

extern "C" SEXP coinclp_chg_column_lower(SEXP ptr, SEXP value)
{
    Clp_Simplex *m = coinclp_model(ptr);
    Clp_chgColumnLower(m, real_or_null(value, Clp_numberColumns(m), "value"));
    return R_NilValue;
}

extern "C" SEXP coinclp_chg_column_upper(SEXP ptr, SEXP value)
{
    Clp_Simplex *m = coinclp_model(ptr);
    Clp_chgColumnUpper(m, real_or_null(value, Clp_numberColumns(m), "value"));
    return R_NilValue;
}

extern "C" SEXP coinclp_chg_row_lower(SEXP ptr, SEXP value)
{
    Clp_Simplex *m = coinclp_model(ptr);
    Clp_chgRowLower(m, real_or_null(value, Clp_numberRows(m), "value"));
    return R_NilValue;
}

extern "C" SEXP coinclp_chg_row_upper(SEXP ptr, SEXP value)
{
    Clp_Simplex *m = coinclp_model(ptr);
    Clp_chgRowUpper(m, real_or_null(value, Clp_numberRows(m), "value"));
    return R_NilValue;
}

extern "C" SEXP coinclp_modify_coefficient(SEXP ptr, SEXP row, SEXP col,
                                           SEXP value, SEXP keep_zero)
{
#if COINCLP_HAVE_MODIFYCOEFFICIENT
    Clp_modifyCoefficient(coinclp_model(ptr), Rf_asInteger(row), Rf_asInteger(col),
                          Rf_asReal(value), Rf_asLogical(keep_zero) == TRUE);
    return R_NilValue;
#else
    (void) ptr; (void) row; (void) col; (void) value; (void) keep_zero;
    Rf_error("this Clp build has no Clp_modifyCoefficient(); "
             "it needs COIN-OR Clp >= 1.18");
    return R_NilValue;
#endif
}

/* ------------------------------------------------------------------ */
/* constraint matrix                                                   */
/* ------------------------------------------------------------------ */

extern "C" SEXP coinclp_vector_starts(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    const CoinBigIndex *st = Clp_getVectorStarts(m);
    int n = Clp_numberColumns(m);
    if (st == NULL || n < 0) return Rf_allocVector(INTSXP, 0);
    SEXP out = PROTECT(Rf_allocVector(INTSXP, (R_xlen_t) n + 1));
    for (int j = 0; j <= n; j++) INTEGER(out)[j] = (int) st[j];
    UNPROTECT(1);
    return out;
}

extern "C" SEXP coinclp_vector_lengths(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_ints(Clp_getVectorLengths(m), Clp_numberColumns(m));
}

extern "C" SEXP coinclp_indices(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_ints(Clp_getIndices(m), (int) Clp_getNumElements(m));
}

extern "C" SEXP coinclp_elements(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_getElements(m), (int) Clp_getNumElements(m));
}

/* The packed matrix may carry gaps, so walk it by starts and lengths rather
   than assuming the physical arrays are contiguous.  Returns 1-based (i, j)
   triplets ready for R. */
extern "C" SEXP coinclp_matrix_triplets(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    int ncols = Clp_numberColumns(m);
    const CoinBigIndex *starts = Clp_getVectorStarts(m);
    const int *lengths = Clp_getVectorLengths(m);
    const int *indices = Clp_getIndices(m);
    const double *elements = Clp_getElements(m);

    R_xlen_t nnz = 0;
    if (starts != NULL && indices != NULL && elements != NULL) {
        for (int j = 0; j < ncols; j++)
            nnz += (lengths != NULL) ? lengths[j] : (R_xlen_t)(starts[j + 1] - starts[j]);
    }

    SEXP i_out = PROTECT(Rf_allocVector(INTSXP, nnz));
    SEXP j_out = PROTECT(Rf_allocVector(INTSXP, nnz));
    SEXP v_out = PROTECT(Rf_allocVector(REALSXP, nnz));

    R_xlen_t k = 0;
    for (int j = 0; j < ncols && nnz > 0; j++) {
        CoinBigIndex from = starts[j];
        CoinBigIndex to = from + ((lengths != NULL) ? lengths[j]
                                                    : (starts[j + 1] - starts[j]));
        for (CoinBigIndex p = from; p < to; p++, k++) {
            INTEGER(i_out)[k] = indices[p] + 1;
            INTEGER(j_out)[k] = j + 1;
            REAL(v_out)[k] = elements[p];
        }
    }

    SEXP out = PROTECT(Rf_allocVector(VECSXP, 5));
    SEXP nms = PROTECT(Rf_allocVector(STRSXP, 5));
    SET_VECTOR_ELT(out, 0, i_out);
    SET_VECTOR_ELT(out, 1, j_out);
    SET_VECTOR_ELT(out, 2, v_out);
    SET_VECTOR_ELT(out, 3, Rf_ScalarInteger(Clp_numberRows(m)));
    SET_VECTOR_ELT(out, 4, Rf_ScalarInteger(ncols));
    SET_STRING_ELT(nms, 0, Rf_mkChar("i"));
    SET_STRING_ELT(nms, 1, Rf_mkChar("j"));
    SET_STRING_ELT(nms, 2, Rf_mkChar("v"));
    SET_STRING_ELT(nms, 3, Rf_mkChar("nrow"));
    SET_STRING_ELT(nms, 4, Rf_mkChar("ncol"));
    Rf_setAttrib(out, R_NamesSymbol, nms);
    UNPROTECT(5);
    return out;
}

/* ------------------------------------------------------------------ */
/* solution vectors                                                    */
/* ------------------------------------------------------------------ */

extern "C" SEXP coinclp_primal_column_solution(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_primalColumnSolution(m), Clp_numberColumns(m));
}

extern "C" SEXP coinclp_dual_column_solution(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_dualColumnSolution(m), Clp_numberColumns(m));
}

extern "C" SEXP coinclp_primal_row_solution(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_primalRowSolution(m), Clp_numberRows(m));
}

extern "C" SEXP coinclp_dual_row_solution(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    return copy_reals(Clp_dualRowSolution(m), Clp_numberRows(m));
}

extern "C" SEXP coinclp_set_column_solution(SEXP ptr, SEXP value)
{
    Clp_Simplex *m = coinclp_model(ptr);
    Clp_setColSolution(m, real_or_null(value, Clp_numberColumns(m), "value"));
    return R_NilValue;
}

extern "C" SEXP coinclp_unbounded_ray(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    double *ray = Clp_unboundedRay(m);
    SEXP out = PROTECT(copy_reals(ray, Clp_numberColumns(m)));
    if (ray != NULL) Clp_freeRay(m, ray);
    UNPROTECT(1);
    return out;
}

extern "C" SEXP coinclp_infeasibility_ray(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    double *ray = Clp_infeasibilityRay(m);
    SEXP out = PROTECT(copy_reals(ray, Clp_numberRows(m)));
    if (ray != NULL) Clp_freeRay(m, ray);
    UNPROTECT(1);
    return out;
}

/* ------------------------------------------------------------------ */
/* basis / warm start                                                  */
/* ------------------------------------------------------------------ */

extern "C" SEXP coinclp_status_exists(SEXP ptr)
{ return Rf_ScalarLogical(Clp_statusExists(coinclp_model(ptr)) != 0); }

extern "C" SEXP coinclp_status_array(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    unsigned char *st = Clp_statusArray(m);
    R_xlen_t n = (R_xlen_t) Clp_numberRows(m) + Clp_numberColumns(m);
    if (st == NULL || n <= 0) return Rf_allocVector(RAWSXP, 0);
    SEXP out = PROTECT(Rf_allocVector(RAWSXP, n));
    memcpy(RAW(out), st, (size_t) n);
    UNPROTECT(1);
    return out;
}

extern "C" SEXP coinclp_copyin_status(SEXP ptr, SEXP status)
{
    Clp_Simplex *m = coinclp_model(ptr);
    if (TYPEOF(status) != RAWSXP)
        Rf_error("'status' must be a raw vector as returned by clp_status_array()");
    R_xlen_t need = (R_xlen_t) Clp_numberRows(m) + Clp_numberColumns(m);
    if (XLENGTH(status) != need)
        Rf_error("'status' has length %.0f but the model needs %.0f entries",
                 (double) XLENGTH(status), (double) need);
    Clp_copyinStatus(m, (const unsigned char *) RAW(status));
    return R_NilValue;
}

extern "C" SEXP coinclp_get_row_status(SEXP ptr, SEXP seq)
{ return Rf_ScalarInteger(Clp_getRowStatus(coinclp_model(ptr), Rf_asInteger(seq))); }

extern "C" SEXP coinclp_get_column_status(SEXP ptr, SEXP seq)
{ return Rf_ScalarInteger(Clp_getColumnStatus(coinclp_model(ptr), Rf_asInteger(seq))); }

extern "C" SEXP coinclp_set_row_status(SEXP ptr, SEXP seq, SEXP value)
{
    Clp_setRowStatus(coinclp_model(ptr), Rf_asInteger(seq), Rf_asInteger(value));
    return R_NilValue;
}

extern "C" SEXP coinclp_set_column_status(SEXP ptr, SEXP seq, SEXP value)
{
    Clp_setColumnStatus(coinclp_model(ptr), Rf_asInteger(seq), Rf_asInteger(value));
    return R_NilValue;
}

/* ------------------------------------------------------------------ */
/* integer markers (Clp itself solves the relaxation)                  */
/* ------------------------------------------------------------------ */

extern "C" SEXP coinclp_copy_in_integer_information(SEXP ptr, SEXP is_integer)
{
    Clp_Simplex *m = coinclp_model(ptr);
    int ncols = Clp_numberColumns(m);
    if (TYPEOF(is_integer) != LGLSXP || XLENGTH(is_integer) != ncols)
        Rf_error("'is_integer' must be a logical vector with one entry per column (%d)",
                 ncols);
    char *info = (char *) R_alloc(ncols > 0 ? ncols : 1, sizeof(char));
    for (int j = 0; j < ncols; j++)
        info[j] = (LOGICAL(is_integer)[j] == TRUE) ? 1 : 0;
    Clp_copyInIntegerInformation(m, info);
    return R_NilValue;
}

extern "C" SEXP coinclp_delete_integer_information(SEXP ptr)
{
    Clp_deleteIntegerInformation(coinclp_model(ptr));
    return R_NilValue;
}

extern "C" SEXP coinclp_integer_information(SEXP ptr)
{
    Clp_Simplex *m = coinclp_model(ptr);
    int ncols = Clp_numberColumns(m);
    const char *info = Clp_integerInformation(m);
    if (info == NULL || ncols <= 0) return Rf_allocVector(LGLSXP, 0);
    SEXP out = PROTECT(Rf_allocVector(LGLSXP, ncols));
    for (int j = 0; j < ncols; j++) LOGICAL(out)[j] = info[j] ? TRUE : FALSE;
    UNPROTECT(1);
    return out;
}
