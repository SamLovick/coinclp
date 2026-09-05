/* coinclp: the solve entry points and the ClpSolve options object. */

#include "coinclp.h"

/* --- solvers --------------------------------------------------------- */

extern "C" SEXP coinclp_initial_solve(SEXP ptr)
{ return Rf_ScalarInteger(Clp_initialSolve(coinclp_model(ptr))); }

extern "C" SEXP coinclp_initial_dual_solve(SEXP ptr)
{ return Rf_ScalarInteger(Clp_initialDualSolve(coinclp_model(ptr))); }

extern "C" SEXP coinclp_initial_primal_solve(SEXP ptr)
{ return Rf_ScalarInteger(Clp_initialPrimalSolve(coinclp_model(ptr))); }

extern "C" SEXP coinclp_initial_barrier_solve(SEXP ptr)
{ return Rf_ScalarInteger(Clp_initialBarrierSolve(coinclp_model(ptr))); }

extern "C" SEXP coinclp_initial_barrier_no_cross_solve(SEXP ptr)
{ return Rf_ScalarInteger(Clp_initialBarrierNoCrossSolve(coinclp_model(ptr))); }

extern "C" SEXP coinclp_initial_solve_with_options(SEXP ptr, SEXP opt)
{
    Clp_Simplex *model = coinclp_model(ptr);
    Clp_Solve *options = coinclp_options(opt);
    return Rf_ScalarInteger(Clp_initialSolveWithOptions(model, options));
}

extern "C" SEXP coinclp_primal(SEXP ptr, SEXP if_values_pass)
{
    return Rf_ScalarInteger(Clp_primal(coinclp_model(ptr),
                                       Rf_asInteger(if_values_pass)));
}

extern "C" SEXP coinclp_dual(SEXP ptr, SEXP if_values_pass)
{
    return Rf_ScalarInteger(Clp_dual(coinclp_model(ptr),
                                     Rf_asInteger(if_values_pass)));
}

extern "C" SEXP coinclp_idiot(SEXP ptr, SEXP try_hard)
{
    Clp_idiot(coinclp_model(ptr), Rf_asInteger(try_hard));
    return R_NilValue;
}

extern "C" SEXP coinclp_crash(SEXP ptr, SEXP gap, SEXP pivot)
{
    return Rf_ScalarInteger(Clp_crash(coinclp_model(ptr), Rf_asReal(gap),
                                      Rf_asInteger(pivot)));
}

/* --- ClpSolve options ------------------------------------------------ */

#define CLPSOLVE_GET_INT(fname, call)                              \
    extern "C" SEXP fname(SEXP opt)                                \
    { return Rf_ScalarInteger(call(coinclp_options(opt))); }

#define CLPSOLVE_SET_INT(fname, call)                              \
    extern "C" SEXP fname(SEXP opt, SEXP value)                    \
    {                                                              \
        int v = Rf_asInteger(value);                               \
        if (v == NA_INTEGER) Rf_error("'value' must not be NA");    \
        call(coinclp_options(opt), v);                             \
        return R_NilValue;                                         \
    }

extern "C" SEXP coinclp_options_set_solve_type(SEXP opt, SEXP method, SEXP extra)
{
    ClpSolve_setSolveType(coinclp_options(opt), Rf_asInteger(method),
                          Rf_asInteger(extra));
    return R_NilValue;
}

extern "C" SEXP coinclp_options_set_presolve_type(SEXP opt, SEXP amount, SEXP extra)
{
    ClpSolve_setPresolveType(coinclp_options(opt), Rf_asInteger(amount),
                             Rf_asInteger(extra));
    return R_NilValue;
}

extern "C" SEXP coinclp_options_set_special_option(SEXP opt, SEXP which,
                                                   SEXP value, SEXP extra)
{
    ClpSolve_setSpecialOption(coinclp_options(opt), Rf_asInteger(which),
                              Rf_asInteger(value), Rf_asInteger(extra));
    return R_NilValue;
}

extern "C" SEXP coinclp_options_get_special_option(SEXP opt, SEXP which)
{
    return Rf_ScalarInteger(ClpSolve_getSpecialOption(coinclp_options(opt),
                                                      Rf_asInteger(which)));
}

extern "C" SEXP coinclp_options_get_extra_info(SEXP opt, SEXP which)
{
    return Rf_ScalarInteger(ClpSolve_getExtraInfo(coinclp_options(opt),
                                                  Rf_asInteger(which)));
}

CLPSOLVE_GET_INT(coinclp_options_get_solve_type, ClpSolve_getSolveType)
CLPSOLVE_GET_INT(coinclp_options_get_presolve_type, ClpSolve_getPresolveType)
CLPSOLVE_GET_INT(coinclp_options_get_presolve_passes, ClpSolve_getPresolvePasses)
CLPSOLVE_GET_INT(coinclp_options_infeasible_return, ClpSolve_infeasibleReturn)
CLPSOLVE_SET_INT(coinclp_options_set_infeasible_return, ClpSolve_setInfeasibleReturn)
CLPSOLVE_GET_INT(coinclp_options_do_dual, ClpSolve_doDual)
CLPSOLVE_SET_INT(coinclp_options_set_do_dual, ClpSolve_setDoDual)
CLPSOLVE_GET_INT(coinclp_options_do_singleton, ClpSolve_doSingleton)
CLPSOLVE_SET_INT(coinclp_options_set_do_singleton, ClpSolve_setDoSingleton)
CLPSOLVE_GET_INT(coinclp_options_do_doubleton, ClpSolve_doDoubleton)
CLPSOLVE_SET_INT(coinclp_options_set_do_doubleton, ClpSolve_setDoDoubleton)
CLPSOLVE_GET_INT(coinclp_options_do_tripleton, ClpSolve_doTripleton)
CLPSOLVE_SET_INT(coinclp_options_set_do_tripleton, ClpSolve_setDoTripleton)
CLPSOLVE_GET_INT(coinclp_options_do_tighten, ClpSolve_doTighten)
CLPSOLVE_SET_INT(coinclp_options_set_do_tighten, ClpSolve_setDoTighten)
CLPSOLVE_GET_INT(coinclp_options_do_forcing, ClpSolve_doForcing)
CLPSOLVE_SET_INT(coinclp_options_set_do_forcing, ClpSolve_setDoForcing)
CLPSOLVE_GET_INT(coinclp_options_do_implied_free, ClpSolve_doImpliedFree)
CLPSOLVE_SET_INT(coinclp_options_set_do_implied_free, ClpSolve_setDoImpliedFree)
CLPSOLVE_GET_INT(coinclp_options_do_dupcol, ClpSolve_doDupcol)
CLPSOLVE_SET_INT(coinclp_options_set_do_dupcol, ClpSolve_setDoDupcol)
CLPSOLVE_GET_INT(coinclp_options_do_duprow, ClpSolve_doDuprow)
CLPSOLVE_SET_INT(coinclp_options_set_do_duprow, ClpSolve_setDoDuprow)
CLPSOLVE_GET_INT(coinclp_options_do_singleton_column, ClpSolve_doSingletonColumn)
CLPSOLVE_SET_INT(coinclp_options_set_do_singleton_column, ClpSolve_setDoSingletonColumn)
CLPSOLVE_GET_INT(coinclp_options_presolve_actions, ClpSolve_presolveActions)
CLPSOLVE_SET_INT(coinclp_options_set_presolve_actions, ClpSolve_setPresolveActions)
CLPSOLVE_GET_INT(coinclp_options_substitution, ClpSolve_substitution)
CLPSOLVE_SET_INT(coinclp_options_set_substitution, ClpSolve_setSubstitution)
