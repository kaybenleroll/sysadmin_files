##						Emacs please make this -*- R -*-
## empty Rprofile.site for R on Debian
##
## Copyright (C) 2008 Dirk Eddelbuettel and GPL'ed
##
## see help(Startup) for documentation on ~/.Rprofile and Rprofile.site

# ## Example of .Rprofile
# options(width=65, digits=5)
# options(show.signif.stars=FALSE)
# setHook(packageEvent("grDevices", "onLoad"),
#         function(...) grDevices::ps.options(horizontal=FALSE))
# set.seed(1234)
# .First <- function() cat("\n   Welcome to R!\n\n")
# .Last <- function()  cat("\n   Goodbye!\n\n")

options(
    lib               = '/usr/local/lib/R/site-library',
    CRAN              = c('http://probability.ca/cran/',
                          'http://ftp.heanet.ie/mirrors/cran.r-project.org/',
                          'http://www.stats.bris.ac.uk/R/'),
    repos             = c('http://probability.ca/cran/',
                          'http://ftp.heanet.ie/mirrors/cran.r-project.org/',
                          'http://www.stats.bris.ac.uk/R/',
                          'http://www.bioconductor.org/packages/release/bioc'),
    browserNLdisabled = TRUE,
    width             = '160',
    digits            = 15,
    digits.secs       = 3,
    deparse.max.lines = 2
);

if (interactive()) {
    suppressMessages(require(devtools))
}


Sys.setenv(R_HISTSIZE = '100000');

.custom.env <- new.env();

.custom.env$cran.nox.view.list <- c('Bayesian',
                                    'Cluster',
                                    'DifferentialEquations',
                                    'Distributions',
                                    'Econometrics',
                                    'Finance',
                                    'HighPerformanceComputing',
                                    'MachineLearning',
                                    'Multivariate',
                                    'OfficialStatistics',
                                    'Optimization',
                                    'ReproducibleResearch',
                                    'Robust',
                                    'SocialSciences',
                                    'Survival',
                                    'TimeSeries');


.custom.env$cran.view.list <- c(.custom.env$cran.nox.view.list,
                                'Graphics',
                                'gR');





# ## Example of Rprofile.site
# local({
#  # add MASS to the default packages, set a CRAN mirror
#  old <- getOption("defaultPackages"); r <- getOption("repos")
#  r["CRAN"] <- "http://my.local.cran"
#  options(defaultPackages = c(old, "MASS"), repos = r)
#})



###
### .ls.objects()   improved list of objects
###

.custom.env$.ls.objects <- function (pos = 1, pattern, order.by, decreasing = FALSE, head = FALSE, n = 5) {
    napply <- function(names, fn) sapply(names, function(x) fn(get(x, pos = pos)))
    names <- ls(pos = pos, pattern = pattern)

    obj.class      <- napply(names, function(x) as.character(class(x))[1])
    obj.mode       <- napply(names, mode)
    obj.type       <- ifelse(is.na(obj.class), obj.mode, obj.class)
    obj.size       <- napply(names, object.size)
    obj.prettysize <- napply(names, function(x) { capture.output(print(object.size(x), units = "auto")) })
    obj.dim        <- t(napply(names, function(x) as.numeric(dim(x))[1:2]))

    vec <- is.na(obj.dim)[, 1] & (obj.type != "function")

    obj.dim[vec, 1] <- napply(names, length)[vec]

    out        <- data.frame(obj.type, obj.size, obj.prettysize, obj.dim)
    names(out) <- c("Type", "Size", "PrettySize", "Rows", "Columns")

    if (!missing(order.by)) {
        out    <- out[order(out[[order.by]], decreasing=decreasing), ]
    }

    if (head) { out <- head(out, n) }

    return(out);
}

# shorthand
.custom.env$lsos <- function(..., n = 30) {
    .ls.objects(..., order.by = "Size", decreasing = TRUE, head = TRUE, n = n);
}


.custom.env$startup <- function() { require(ProjectTemplate); load.project(); }

.custom.env$startdev <- function() { dev_mode(TRUE); load('.RData'); startup(); }

while('.custom.env' %in% search()) { detach('.custom.env') }
attach(.custom.env);
