/* coinclp: solver parameters, status flags and diagnostics. */

#include "coinclp.h"

#define CLP_GET_INT(fname, call)                                   \
    extern "C" SEXP fname(SEXP ptr)                                \
    { return Rf_ScalarInteger(call(coinclp_model(ptr))); }

#define CLP_GET_DBL(fname, call)                                   \
    extern "C" SEXP fname(SEXP ptr)                                \
    { return Rf_ScalarReal(call(coinclp_model(ptr))); }

#define CLP_GET_LGL(fname, call)                                   \
    extern "C" SEXP fname(SEXP ptr)                                \
    { return Rf_ScalarLogical(call(coinclp_model(ptr)) != 0); }

#define CLP_SET_INT(fname, call)                                   \
    extern "C" SEXP fname(SEXP ptr, SEXP value)                    \
    {                                                              \
        int v = Rf_asInteger(value);                               \
        if (v == NA_INTEGER) Rf_error("'value' must not be NA");    \
        call(coinclp_model(ptr), v);                               \
        return R_NilValue;                                         \
    }

#define CLP_SET_DBL(fname, call)                                   \
    extern "C" SEXP fname(SEXP ptr, SEXP value)                    \
    {                                                              \
        double v = Rf_asReal(value);                               \
        if (ISNA(v)) Rf_error("'value' must not be NA");            \
        call(coinclp_model(ptr), v);                               \
        return R_NilValue;                                         \
    }

/* --- direction and objective ---------------------------------------- */

CLP_GET_DBL(coinclp_optimization_direction, Clp_optimizationDirection)
CLP_SET_DBL(coinclp_set_optimization_direction, Clp_setOptimizationDirection)
CLP_GET_DBL(coinclp_obj_sense, Clp_getObjSense)
CLP_SET_DBL(coinclp_set_obj_sense, Clp_setObjSense)
CLP_GET_DBL(coinclp_objective_value, Clp_objectiveValue)
CLP_GET_DBL(coinclp_objective_offset, Clp_objectiveOffset)
CLP_SET_DBL(coinclp_set_objective_offset, Clp_setObjectiveOffset)

/* --- tolerances and limits ------------------------------------------ */

CLP_GET_DBL(coinclp_primal_tolerance, Clp_primalTolerance)
CLP_SET_DBL(coinclp_set_primal_tolerance, Clp_setPrimalTolerance)
CLP_GET_DBL(coinclp_dual_tolerance, Clp_dualTolerance)
CLP_SET_DBL(coinclp_set_dual_tolerance, Clp_setDualTolerance)
CLP_GET_DBL(coinclp_dual_objective_limit, Clp_dualObjectiveLimit)
CLP_SET_DBL(coinclp_set_dual_objective_limit, Clp_setDualObjectiveLimit)
CLP_GET_DBL(coinclp_dual_bound, Clp_dualBound)
CLP_SET_DBL(coinclp_set_dual_bound, Clp_setDualBound)
CLP_GET_DBL(coinclp_infeasibility_cost, Clp_infeasibilityCost)
CLP_SET_DBL(coinclp_set_infeasibility_cost, Clp_setInfeasibilityCost)
CLP_GET_DBL(coinclp_maximum_seconds, Clp_maximumSeconds)
CLP_SET_DBL(coinclp_set_maximum_seconds, Clp_setMaximumSeconds)
CLP_GET_DBL(coinclp_small_element_value, Clp_getSmallElementValue)
CLP_SET_DBL(coinclp_set_small_element_value, Clp_setSmallElementValue)
CLP_SET_INT(coinclp_set_maximum_iterations, Clp_setMaximumIterations)
CLP_GET_LGL(coinclp_hit_maximum_iterations, Clp_hitMaximumIterations)

extern "C" SEXP coinclp_maximum_iterations(SEXP ptr)
{
    /* Clp 1.17 exports this one without the Clp_ prefix. */
#if COINCLP_HAVE_CLP_MAXIMUMITERATIONS
    return Rf_ScalarInteger(Clp_maximumIterations(coinclp_model(ptr)));
#else
    return Rf_ScalarInteger(maximumIterations(coinclp_model(ptr)));
#endif
}

/* --- algorithm control ---------------------------------------------- */

CLP_GET_INT(coinclp_log_level, Clp_logLevel)
CLP_SET_INT(coinclp_set_log_level, Clp_setLogLevel)
CLP_GET_INT(coinclp_scaling_flag, Clp_scalingFlag)
CLP_SET_INT(coinclp_set_scaling, Clp_scaling)
CLP_GET_INT(coinclp_perturbation, Clp_perturbation)
CLP_SET_INT(coinclp_set_perturbation, Clp_setPerturbation)
CLP_GET_INT(coinclp_algorithm, Clp_algorithm)
CLP_SET_INT(coinclp_set_algorithm, Clp_setAlgorithm)
CLP_GET_INT(coinclp_number_iterations, Clp_numberIterations)
CLP_SET_INT(coinclp_set_number_iterations, Clp_setNumberIterations)

/* --- status ---------------------------------------------------------- */

CLP_GET_INT(coinclp_status, Clp_status)
CLP_SET_INT(coinclp_set_problem_status, Clp_setProblemStatus)
CLP_GET_INT(coinclp_secondary_status, Clp_secondaryStatus)
CLP_SET_INT(coinclp_set_secondary_status, Clp_setSecondaryStatus)

CLP_GET_LGL(coinclp_is_abandoned, Clp_isAbandoned)
CLP_GET_LGL(coinclp_is_proven_optimal, Clp_isProvenOptimal)
CLP_GET_LGL(coinclp_is_proven_primal_infeasible, Clp_isProvenPrimalInfeasible)
CLP_GET_LGL(coinclp_is_proven_dual_infeasible, Clp_isProvenDualInfeasible)
CLP_GET_LGL(coinclp_is_primal_objective_limit_reached, Clp_isPrimalObjectiveLimitReached)
CLP_GET_LGL(coinclp_is_dual_objective_limit_reached, Clp_isDualObjectiveLimitReached)
CLP_GET_LGL(coinclp_is_iteration_limit_reached, Clp_isIterationLimitReached)
CLP_GET_LGL(coinclp_primal_feasible, Clp_primalFeasible)
CLP_GET_LGL(coinclp_dual_feasible, Clp_dualFeasible)

CLP_GET_DBL(coinclp_sum_primal_infeasibilities, Clp_sumPrimalInfeasibilities)
CLP_GET_DBL(coinclp_sum_dual_infeasibilities, Clp_sumDualInfeasibilities)
CLP_GET_INT(coinclp_number_primal_infeasibilities, Clp_numberPrimalInfeasibilities)
CLP_GET_INT(coinclp_number_dual_infeasibilities, Clp_numberDualInfeasibilities)

extern "C" SEXP coinclp_check_solution(SEXP ptr)
{
    Clp_checkSolution(coinclp_model(ptr));
    return R_NilValue;
}
