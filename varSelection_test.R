## This script demonstrates and tests changes made to the function yaImpute::varSelection.
##


# Clear Workspace
rm(list = ls())


# Attach packages
library(digest)
library(future)
library(yaImpute)


# Load externally defined functions
source("grmsd_changed.R")
source("varSelection_changed.R")   ## *

## *NOTE: calls to varSelection now reference the modified version of the function, calls to the 
##      package version must now explicitly contain the namespace (yaImpute::varSelection).



# Load .RData file containing the inputs provided to each version of the function
load("varSelection_test.RData")
env.list <- as.list(env)
for(i in seq_along(env.list)){
    assign(names(env.list)[i], env.list[[i]])
}


# Using the future package to simulate threads in R, this way the first test will not block the
# commencement of the second. (have to be careful that the number of cores being used does not
# exceed the number available).
plan(multisession)


# Test package version, on Windows this will run with useParallel == FALSE.
pkg.result %<-% {
    set.seed(117)
    pkg.start <- Sys.time()
    pkg.tmp   <- suppressMessages(
        yaImpute::varSelection(x = x, y = y, yaiMethod = yaiMethod, trace = trace,
                               k = k, nboot = nboot, pVal = 0.05, rfMode = "regression",
                               ntree = 500, useParallel = FALSE, bootstrap = FALSE)
    )
    pkg.runtime <- Sys.time() - pkg.start
    list(start = pkg.start, result = pkg.tmp, runtime = pkg.runtime)
}


# Test modified version
new.result %<-% {
    set.seed(117)
    new.start <- Sys.time()
    new.tmp   <- suppressMessages(
        varSelection(x = x, y = y, yaiMethod = yaiMethod, trace = trace,
                     k = k, nboot = nboot, pVal = 0.05, rfMode = "regression",
                     ntree = 500, bootstrap = FALSE)
    )
    new.runtime <- Sys.time() - new.start
    list(start = new.start, result = new.tmp, runtime = new.runtime)
}


# output runtimes
cat("Runtime for yaImpute::varSelection (package version): ", pkg.result$runtime, "\n")
cat("Runtime for varSelection (non-package version): ", new.result$runtime, "\n")


# Compare output objects by creating an MD5 hash of both objects using the digest package, note that
# due to the call to the new package being different by design that the list element 'call' must be
# deleted first.
pkg.md5 <- digest(pkg.result$result[-which(names(pkg.result$result) == "call")])
new.md5 <- digest(new.result$result[-which(names(pkg.result$result) == "call")])
if(identical(pkg.md5, new.md5)){
    cat("Modifications to varSelection produced the expected output!")
} else {
    cat("Modifications to varSelection failed to produce the expected output!")
}
