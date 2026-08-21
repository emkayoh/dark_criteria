# dc_envCap.R  (JMFK)
# Capture the computational environment to a timestamped text file, so a
# results set can be tied to the machine, code state, and configuration
# that produced it. Written for cross-platform comparison runs (macOS and
# RISC-V) and for eventual inclusion in reviewer or examiner records.
#
# Usage:
#   source("dc_envCap.R")
#   envCap()                                  # writes to working directory
#   envCap(dir = results_dir, tag = "titan")  # writes alongside results

envCap <- function(
    dir = ".",
    tag = NULL,
    code_dir = NULL,
    notes = NULL
) {
    run_stamp <- format(Sys.time(), "%Y-%m-%d_%H%M%S")

    node <- unname(Sys.info()[["nodename"]])
if (!nzchar(node) || identical(node, "UNKNOWN")) {
    node <- tryCatch(system2("hostname", "-s", stdout = TRUE)[1],
                     error = function(e) "unknown")
}

    filename <- file.path(
        dir,
        paste0(
            "local_environment_",
            if (is.null(tag)) node else tag, "_",
            run_stamp,
            "_pid", Sys.getpid(),
            ".txt"
        )
    )

    # Helper: run a shell command, returning NA rather than erroring.
    try_cmd <- function(cmd, args) {
        out <- tryCatch(
            suppressWarnings(system2(cmd, args, stdout = TRUE, stderr = FALSE)),
            error = function(e) NA_character_
        )
        if (length(out) == 0L) NA_character_ else out
    }

    sink(file = filename)
    on.exit(sink(NULL), add = TRUE)   # restore output even if this errors

    cat("Environment capture\n")
    cat("===================\n\n")
    cat("File:      ", basename(filename), "\n")
    cat("Written:   ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
    cat("Timezone:  ", Sys.timezone(), "\n")
    if (!is.null(notes)) cat("Notes:     ", notes, "\n")
    cat("\n")

    cat("Machine\n-------\n")
    si <- Sys.info()
    cat("Node:      ", unname(si[["nodename"]]), "\n")
    cat("OS:        ", unname(si[["sysname"]]), unname(si[["release"]]), "\n")
    cat("Version:   ", unname(si[["version"]]), "\n")
    cat("Machine:   ", unname(si[["machine"]]), "  (architecture)\n")
    cat("User:      ", unname(si[["user"]]), "\n")
    cat("Cores:     ", parallel::detectCores(), " detected\n")
    cat("Platform:  ", R.version$platform, "\n")
    cat("\n")

    cat("R\n-\n")
    cat("Version:   ", R.version.string, "\n")
    cat("RNG kind:  ", paste(RNGkind(), collapse = ", "), "\n")
    cat("R_LIBS:    ", paste(.libPaths(), collapse = "; "), "\n")
    cat("\n")

    cat("Numerical libraries\n-------------------\n")
    cat("(Summation order in BLAS/LAPACK determines whether identical\n")
    cat(" inputs give bit-identical linear algebra across platforms.)\n")
    ext <- tryCatch(extSoftVersion(), error = function(e) character(0))
    if (length(ext)) {
        for (nm in names(ext)) cat(sprintf("  %-12s %s\n", nm, ext[[nm]]))
    }
    la <- tryCatch(La_version(), error = function(e) NA_character_)
    cat("  LAPACK ver  ", la, "\n")
    cat("\n")

    cat("Floating-point check\n--------------------\n")
    cat("(Exact hex representation; compare across machines to confirm\n")
    cat(" identical pseudo-random streams under a pinned RNG version.)\n")
    old_seed <- if (exists(".Random.seed", envir = .GlobalEnv)) {
        get(".Random.seed", envir = .GlobalEnv)
    } else {
        NULL
    }
    set.seed(100001)
    probe <- rnorm(5)
    cat("  set.seed(100001); rnorm(5):\n")
    cat("   ", paste(sprintf("%a", probe), collapse = "\n    "), "\n")
    cat("  double.eps:", sprintf("%a", .Machine$double.eps), "\n")
    if (!is.null(old_seed)) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
    }
    cat("\n")

    cat("Repository state\n----------------\n")
    gd <- if (is.null(code_dir)) getwd() else path.expand(code_dir)
    gargs <- c("-C", shQuote(gd))
    commit  <- try_cmd("git", c(gargs, "rev-parse", "HEAD"))
    short   <- try_cmd("git", c(gargs, "rev-parse", "--short", "HEAD"))
    branch  <- try_cmd("git", c(gargs, "rev-parse", "--abbrev-ref", "HEAD"))
    origin  <- try_cmd("git", c(gargs, "config", "--get", "remote.origin.url"))
    subject <- try_cmd("git", c(gargs, "log", "-1", "--format=%s"))
    cdate   <- try_cmd("git", c(gargs, "log", "-1", "--date=iso", "--format=%ad"))
    status  <- try_cmd("git", c(gargs, "status", "--porcelain"))
    cat("Directory: ", gd, "\n")
    cat("Branch:    ", branch, "\n")
    cat("Commit:    ", commit, "\n")
    cat("Short:     ", short, "\n")
    cat("Date:      ", cdate, "\n")
    cat("Subject:   ", subject, "\n")
    cat("Remote:    ", origin, "\n")
    if (length(status) == 1L && is.na(status)) {
        cat("Clean:      unknown (git unavailable)\n")
    } else if (length(status) == 0L) {
        cat("Clean:      yes (no uncommitted changes)\n")
    } else {
        cat("Clean:      NO -- uncommitted changes present:\n")
        cat(paste0("  ", status, collapse = "\n"), "\n")
    }
    cat("\n")

    cat("Session info\n------------\n")
    print(sessionInfo())
    cat("\n")

    cat("Locale\n------\n")
    cat(Sys.getlocale(), "\n\n")

    cat("Relevant environment variables\n------------------------------\n")
    keep <- c("DC_ROOT", "R_HOME", "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS",
              "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS", "LANG", "TZ")
    for (k in keep) {
        v <- Sys.getenv(k, unset = NA_character_)
        cat(sprintf("  %-24s %s\n", k, if (is.na(v)) "(unset)" else v))
    }

    sink(NULL)
    on.exit()   # sink already closed; cancel the handler
    message("Environment captured: ", filename)
    invisible(filename)
}