## coinclp 0.1.2

A licence change, with no change to the code.

### Why

The package was released as "License: EPL", which in an R DESCRIPTION means
EPL 1.0, since that is the only Eclipse entry in R's licence database. Both
the Free Software Foundation and the Eclipse Foundation record EPL 1.0 as
incompatible with the GPL, and that blocks GPL-licensed packages from
building on this one -- including ROI.plugin.coinclp, which imports ROI
(GPL-3) and slam (GPL-2). The point was raised against the archived
ROI.plugin.clp in 2018 and never answered there.

The package is now MIT, which is compatible with the GPL and with the
Eclipse Public License of the Clp library it links against, so neither side
is blocked. Clp's own EPL 2.0 does not elect the GPL secondary licence, so
compatibility could not be inherited from upstream. No part of COIN-OR Clp
is in this package's source: it is an independent binding, and EPL copyleft
applies file by file, so it never extended to this code.

I am the sole author and copyright holder of coinclp, so the change is mine
to make. It widens the permissions granted to users rather than narrowing
them. A LICENSE file giving the year and copyright holder accompanies it, as
CRAN requires for MIT.

### Also in this release

inst/COPYRIGHTS previously said that Clp "is not included in this package".
That is true of the source package but not of a binary: the Clp libraries
are static, so a compiled coinclp contains Clp object code, and the Windows
and macOS binaries built by CRAN distribute it under EPL 2.0. The file now
records that and points at the upstream source, as EPL 2.0 section 3.2 asks.

## Test environments

* Windows 11, R 4.5.2, Rtools45 (Clp 1.17.0)
* GitHub Actions: ubuntu-latest (R release, R devel, R oldrel-1),
  macOS-latest (R release), windows-latest (R release)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Reverse dependencies

ROI.plugin.coinclp imports coinclp (>= 0.1.0) and is unaffected by this
release; its own licence change, to GPL-3, follows in a separate submission.
