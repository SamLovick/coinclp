## The clpAPI compatibility layer, exercised the way existing code uses it.

library(coinclp)

near <- function(x, y, tol = 1e-6) all(abs(x - y) < tol)

stopifnot(is.character(versionCLP()), nzchar(versionCLP()))

lp <- initProbCLP()
stopifnot(isCLPpointer(lp), !isNULLpointerCLP(lp),
          identical(clpPtrType(lp), "clp_prob"),
          typeof(clpPointer(lp)) == "externalptr")
clpPtrType(lp) <- "renamed"
stopifnot(identical(clpPtrType(lp), "renamed"))

## This is the sequence ROI.plugin.clp used.
setLogLevelCLP(lp, 0)
loadProblemCLP(lp, 2, 3, c(0, 3, 6), c(0, 1, 2, 0, 1, 2),
               c(120, 110, 1, 210, 30, 1),
               lb = c(0, 0), ub = c(1e30, 1e30), obj_coef = c(143, 60),
               rlb = rep(-1e30, 3), rub = c(15000, 4000, 75))
setObjDirCLP(lp, -1)
setMaximumIterationsCLP(lp, 1000)
setMaximumSecondsCLP(lp, 60)
stopifnot(solveInitialCLP(lp) == 0)

stopifnot(getSolStatusCLP(lp) == 0,
          status_codeCLP(getSolStatusCLP(lp)) == "solution is optimal",
          return_codeCLP(0) == "solution process was successful",
          near(getObjValCLP(lp), 6315.625),
          near(getColPrimCLP(lp), c(21.875, 53.125)),
          length(getRowDualCLP(lp)) == 3,
          length(getColDualCLP(lp)) == 2,
          near(getRowPrimCLP(lp), c(13781.25, 4000, 75)))

stopifnot(getNumRowsCLP(lp) == 3, getNumColsCLP(lp) == 2,
          getNumNnzCLP(lp) == 6,
          near(getObjCoefsCLP(lp), c(143, 60)),
          near(getRowUpperCLP(lp), c(15000, 4000, 75)),
          near(getColLowerCLP(lp), c(0, 0)),
          length(getVecStartCLP(lp)) == 3,
          length(getIndCLP(lp)) == 6,
          length(getNnzCLP(lp)) == 6,
          length(getVecLenCLP(lp)) == 2,
          getObjDirCLP(lp) == -1,
          getLogLevelCLP(lp) == 0,
          getMaximumIterationsCLP(lp) == 1000,
          getMaximumSecondsCLP(lp) >= 60,
          is.logical(getHitMaximumIterationsCLP(lp)))

chgObjCoefsCLP(lp, c(1, 1))
stopifnot(near(getObjCoefsCLP(lp), c(1, 1)))
chgColUpperCLP(lp, c(10, 10))
stopifnot(near(getColUpperCLP(lp), c(10, 10)))
chgRowLowerCLP(lp, rep(-1e30, 3))
chgRowUpperCLP(lp, c(15000, 4000, 60))
stopifnot(near(getRowUpperCLP(lp), c(15000, 4000, 60)))
chgColLowerCLP(lp, c(0, 0))

## Names and scaling.
copyNamesCLP(lp, c("x", "y"), c("mix", "time", "capacity"))
stopifnot(lengthNamesCLP(lp) >= 8)
probNameCLP(lp, "compat")
scaleModelCLP(lp, 1)
stopifnot(getScaleFlagCLP(lp) == 1)
dropNamesCLP(lp)

## The other solve entry points.
setObjDirCLP(lp, 1)
stopifnot(is.numeric(solveInitialDualCLP(lp)) || is.integer(solveInitialDualCLP(lp)))
primalCLP(lp)
dualCLP(lp, 0)
idiotCLP(lp, 0)

## Structural edits.
addRowsCLP(lp, 1, -1e30, 30, c(0, 2), c(0, 1), c(1, 1))
stopifnot(getNumRowsCLP(lp) == 4)
delRowsCLP(lp, 1, 3)
stopifnot(getNumRowsCLP(lp) == 3)
addColsCLP(lp, 1, 0, 1e30, 1, c(0, 1), 0, 1)
stopifnot(getNumColsCLP(lp) == 3)
delColsCLP(lp, 1, 2)
stopifnot(getNumColsCLP(lp) == 2)
resizeCLP(lp, 3, 2)

## Optional entry points report availability rather than failing obscurely.
available <- isAvailableFuncCLP("Clp_writeMps")
stopifnot(is.logical(available), length(available) == 1L)
stopifnot(identical(unname(isAvailableFuncCLP("no_such_function")), FALSE))

## Save and restore round trip.
snapshot <- tempfile()
stopifnot(saveModelCLP(lp, snapshot) == 0)
stopifnot(restoreModelCLP(lp, snapshot) == 0)
unlink(snapshot)

## Writing MPS works whichever entry point is available.
mps <- tempfile(fileext = ".mps")
writeMPSCLP(lp, mps)
stopifnot(file.exists(mps), length(readLines(mps)) > 3)
unlink(mps)

delProbCLP(lp)
stopifnot(isNULLpointerCLP(lp))
