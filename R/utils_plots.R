#' \code{align_caption} aligns the caption at the left if the \code{cowplot}
#' package is available
#'
#' @param p A plot created by \code{ggplot}
#' @param caption optional; the caption to be added
#' @param subtitle optional; the subtitle to be added
#'
#' @return The output is the same plot but with left-aligned caption and a
#'  subtitle if provided
leftalign_caption <- function(p, ...){

  if(missing(p)) stop("Please provide a plot")
  if(!exists("caption")) caption <- NULL
  if(!exists("subtitle")) subtitle <- NULL

  if(is.null(caption) & is.null(subtitle)) return(p)

  if(requireNamespace("cowplot", quietly = TRUE)){
    if(is.null(subtitle)){
      p <- p + ggtitle(label = "")
      p <- ggdraw(p) + draw_text(text = caption, x = 0.01, y = 0.995, hjust = 0, vjust = 1, size = 22)
    }else{
      p <- p + ggtitle(label = "", subtitle = "")
      p <- ggdraw(p) + draw_text(text = caption, x = 0.01, y = 0.98, hjust = 0, vjust = 1, size = 22)
      p <- ggdraw(p) + draw_text(text = subtitle, x = 0.01, y = 0.91, hjust = 0, vjust = 1, size = 16)
    }
  }else{
    phistogramm <- phistogramm + ggtitle(label = caption, subtitle = subtitle)
  }

  return(p)
}

get_subtit_samplesize <- function(n, nmove)
  paste0(paste0(rep(" ", nmove - nchar(n) + 10), collapse = ""), "n = ", n)




#' S3 method for \code{roc} object
#'
#' \code{plot.roc} is the S3
#'
#' @param x \code{roc} object
#' @param which optional; specifies which type of plots shall be created. If not
#'   set, all plots are created. Possible values are histogramm, empirical, fit,
#'   roc_uncertainty, parameter_uncertainty, and partial matching is supported.
#' @param ... optional; additional arguments to be passed to the single plotting
#'   functions (see details)
#' @details TBD
#'
plot.roc <- function(x, which, ...) {

  availplots <- c("histogramm", "empirical", "fit", "roc_uncertainty",
             "parameter_uncertainty")

  if(missing(which)){
    create <- availplots
  }else{
    if(inherits(which, c("integer", "numeric"))){
      if(any(which > length(availplots)) | any(which <= 0)){
        stop(sprintf(paste("Wrong input for argument \"which\",",
                           "has to be between 0 and %d", length(availplots))))
        }
      create <- availplots[which]
    }else{
      create <- as.character(sapply(which, function(x, availplots) match.arg(x, availplots), avail = availplots))
    }
  }

  plotlist <- list()
  plotcounter <- 1

  if("empirical" %in% create){
    plotlist[[plotcounter]] <- plot_roc_empirical(x, ...)
    plotcounter <- plotcounter + 1
  }

  if("histogramm" %in% create){
    plotlist[[plotcounter]] <- plot_roc_histogramm(x, ...)
    plotcounter <- plotcounter + 1
  }

  if("fit" %in% create){
    cat("ANDERE METHODE ALS NUR EMPIRICAL VORHANDEN")
  }

  if("roc_uncertainty" %in% create){
    cat("ANDERE METHODE ALS NUR EMPIRICAL VORHANDEN")
  }

  if("parameter_uncertainty" %in% create){
    cat("ANDERE METHODE ALS NUR EMPIRICAL VORHANDEN")
  }

  return(plotlist)
}



#' Histogramm and support plot for \code{roc} objects
#'
#' @inheritParams plot.roc
#'
#' @details
plot_roc_histogramm <- function(x, ...){

  obsforc_df  <- as.data.frame.roc(x, type = "obsforc") %>% as.tibble()
  obsforc_df0 <- obsforc_df %>% filter(obs == 0)
  obsforc_df1 <- obsforc_df %>% filter(obs == 1)

  if(!exists("predictor")) predictor <- ""
  if(!is.numeric("ylim")) ylim <- c(-1, 1)
  if(!exists("color")) color <- c("#E41A1C", "#377EB8")
  if(!is.numeric("xlim")) xlim <- c(min(obsforc_df$forc), max(obsforc_df$forc))
  if(!exists("breaks")) breaks <- seq(xlim[1], xlim[2], length.out = 31)

  line_vals <- obsforc_df %>%
    group_by(obs) %>%
    summarize(minv = min(forc), maxv = max(forc)) %>%
    ungroup

  dat_line  <- tibble(
    x  = c(line_vals %>% filter(obs == 0) %>% select(-obs) %>% as.numeric,
           line_vals %>% filter(obs == 1) %>% select(-obs) %>% as.numeric),
    y   = c(ylim[1], ylim[1], ylim[2], ylim[2]),
    obs = as.factor(c(0,0,1,1)))

  phistogramm <- ggplot() +
    geom_histogram(data = obsforc_df0, aes(x = forc, y = -..density..),
                   fill = color[1], alpha = 1, breaks = breaks) +
    geom_histogram(data = obsforc_df1, aes(x = forc, y = ..density..),
                   fill = color[2], alpha = 1, breaks = breaks) +
    geom_line(data = dat_line, aes(x = x, y = y, col = obs), lwd = 1) +
    scale_color_manual(values = color[1:2]) +

    geom_hline(yintercept = 0) +
    xlab(predictor) + ylab("") + ggtitle("", subtitle = "") +
    theme(legend.position = "none") +
    scale_fill_manual(name = "Observation", values = colors[1:2]) +

    scale_y_continuous(
      labels = NULL,
      breaks = seq(ylim[1], ylim[2], length.out = 11),
      minor_breaks = NULL) +

    coord_cartesian(ylim = ylim) +

    annotate("text", x = xlim[1] + 0.95 * diff(xlim), y = ylim[1] + 0.1 * diff(ylim),
             label = "F[0]", size = 7, col = color[1], parse = TRUE) +

    annotate("text", x = xlim[1] + 0.95 * diff(xlim), y = ylim[1] + 0.9 * diff(ylim),
             label = "F[1]", size = 7, col = color[2], parse = TRUE) +

    theme_minimal() + theme(legend.position = "none")

  phistogramm  <- leftalign_caption(phistogramm, ...)

  return(phistogramm)
}

plot_roc_empirical <- function(x, ...){
  p <- ggplot() +
    geom_line(data = x$empROC %>% as.tibble, aes(x = FPR, y = TPR)) +
    theme_minimal()
  return(p)
}







#' Plot function for beta ROC curves
#'
#' @inheritParams get_TPR
#' @param p
#' @param lty
#' @param lwd
#'
plot_beta <- function(pars, MDE_info, p, lty, lwd){

  if(missing(pars)) stop("pars need to be specified")

  if(missing(MDE_info)){
    if(length(pars) == 2)
      MDE_info <- list(methods = "beta2p", info = "unrestricted")
    if(length(pars) == 3)
      MDE_info <- list(methods = "beta3p_v", info = "unrestricted")
    if(length(pars) == 4)
      MDE_info <- list(methods = "beta4p", info = "unrestricted")
  }

  if(missing(lty)) lty <- 1
  if(missing(lwd)) lwd <- 0.7

  color <- "#377EB8"
  FPR <- seq(0, 1, by = 0.005)
  TPR <- get_TPR(FPR, pars, MDE_info)
  tib <- tibble(FPR = c(0, FPR, 1), TPR = c(0, TPR, 1))

  betainfo <- paste0(round(pars, 1), collapse = "; ")
  subtitle <- paste0("Beta parameters (", betainfo, ")")

  if(missing(p)){
    p <- ggplot(tib, aes(x = FPR, y = TPR)) +
      geom_line(col = color, lty = lty, lwd = lwd) +
      ggtitle(label = "Beta ROC curve", subtitle = subtitle) +
      theme_minimal()
  }else{
    p <- p + geom_line(data = tib, aes(x = FPR, y = TPR),
                       col = color[1], lty = lty, lwd = lwd)
  }
  return(p)
}

plot_binormal <- function(pars, MDE_info, p, lty, lwd){

  if(missing(pars)) stop("pars need to be specified")

  if(missing(MDE_info)){
    if(length(pars) == 2)
      MDE_info <- list(methods = "bin2p", info = "unrestricted")
    if(length(pars) == 3)
      MDE_info <- list(methods = "bin3p", info = "unrestricted")
  }

  if(missing(lty)) lty <- 1
  if(missing(lwd)) lwd <- 0.7

  color <- "#377EB8"
  FPR <- seq(0, 1, by = 0.005)
  TPR <- get_TPR(FPR, pars, MDE_info)
  tib <-   tib <- tibble(FPR = c(0, FPR, 1), TPR = c(0, TPR, 1))

  bininfo <- paste0(round(pars, 1), collapse = "; ")
  subtitle <- paste0("Binormal parameters (", bininfo, ")")

  if(missing(p)){
    p <- ggplot(tib, aes(x = FPR, y = TPR)) +
      geom_line(col = color, lty = lty, lwd = lwd) +
      ggtitle(label = "Binormal ROC curve", subtitle = subtitle) +
      theme_minimal()
  }else{
    p <- p + geom_line(data = tib, aes(x = FPR, y = TPR),
                       col = color[1], lty = lty, lwd = lwd)
  }
  return(p)
}