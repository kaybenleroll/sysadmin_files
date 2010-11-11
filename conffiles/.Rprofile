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

options(lib             = '/usr/local/lib/R/site-library');
options(CRAN            = c("http://ftp.heanet.ie/mirrors/cran.r-project.org/", "http://www.stats.bris.ac.uk/R/"));
options(repos           = c("http://ftp.heanet.ie/mirrors/cran.r-project.org/", "http://www.stats.bris.ac.uk/R/", "http://r-forge.r-project.org"));
options(width           = '180');
options(digits          = 15);
options(digits.secs     = 3);
options(defaultPackages = c(getOption('defaultPackages'), 'ProjectTemplate'));


.custom.env <- new.env();

.custom.env$cran.view.list <- c('Bayesian',
                                'Cluster',
                                'Distributions',
                                'Econometrics',
                                'Finance',
                                'Graphics',
                                'gR',
                                'HighPerformanceComputing',
                                'MachineLearning',
                                'Multivariate',
                                'OfficialStatistics',
                                'Optimization',
                                'ReproducibleResearch',
                                'Robust',
                                'Survival',
                                'TimeSeries');


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
    napply <- function(names, fn) sapply(names, function(x) fn(get(x, pos = pos)));
    names <- ls(pos = pos, pattern = pattern);

    obj.class <- napply(names, function(x) as.character(class(x))[1]);
    obj.mode  <- napply(names, mode);
    obj.type  <- ifelse(is.na(obj.class), obj.mode, obj.class);
    obj.size  <- napply(names, object.size);
    obj.dim   <- t(napply(names, function(x) as.numeric(dim(x))[1:2]));

    vec <- is.na(obj.dim)[, 1] & (obj.type != "function");

    obj.dim[vec, 1] <- napply(names, length)[vec];

    out        <- data.frame(obj.type, obj.size, obj.dim);
    names(out) <- c("Type", "Size", "Rows", "Columns");

    if(!missing(order.by)) { out <- out[order(out[[order.by]], decreasing = decreasing), ] }
    if(head)               { out <- head(out, n) }

    return(out);
}



# shorthand
.custom.env$lsos <- function(..., n = 30) {
    .ls.objects(..., order.by = "Size", decreasing = TRUE, head = TRUE, n = n);
}


while('.custom.env' %in% search()) { detach('.custom.env') }
attach(.custom.env);
