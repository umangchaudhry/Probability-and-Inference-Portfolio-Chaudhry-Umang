library(tidyverse)
library(foreach)
library(dplyr)
library(doParallel)

args <- commandArgs(trailingOnly = TRUE)
args <- as.numeric(args)

parameters <-
  list(
    n = 201,
    dist = "normal",
    mean = 0,
    sd = 1,
    shape = 1.4,
    scale = 3,
    model = "KDE",
    stat = "median",
    smoo = 0.3,
    R = 5000
  )

generate_data <- function(parameter) {
  if (parameter$dist == "normal") {
    parameter$data <- rnorm(parameter$n, parameter$mean, parameter$sd)
  } else if (parameter$dist == "gamma") {
    parameter$data <-
      rgamma(n = parameter$n,
             shape = parameter$shape,
             scale = parameter$scale)
  }
  return(parameter)
}

estimate_CI <- function(parameter) {
  data <- parameter$data
  sm <- get(parameter$stat)
  parameter$sumstat <- sm(data)
  if (parameter$dist == "nomal" &
      parameter$model == "moments_gamma") {
    parameter$CI <- NA
    return(parameter)
  }
  
  else if (parameter$model == "moments_normal") {
    #browser()
    parameter$mean_MN <- mean(data)
    parameter$sd_MN <- sd(data)
    samp.dist <- NA
    sim.data <-
      array(
        rnorm(
          parameter$n * parameter$R,
          parameter$mean_MN,
          parameter$sd_MN
        ),
        dim = c(parameter$n, parameter$R)
      )
    samp.dist <- apply(sim.data, 2, FUN = sm)
    parameter$CI <- quantile(samp.dist, c(0.05, 0.95))
    return(parameter)
  }
  
  else if (parameter$model == "moments_gamma") {
    if (min(data) < 0) {
      parameter$CI <- NA
      return(parameter)
    } else {
      parameter$shape_MG <- (mean(data) ^ 2) / var(data)
      parameter$scale_MG <- var(data) / mean(data)
      sim.data <-
        array(
          rgamma(
            parameter$n * parameter$R,
            shape = parameter$shape_MG,
            scale = parameter$scale_MG
          ),
          dim = c(parameter$n, parameter$R)
        )
      samp.dist <- apply(sim.data, 2, FUN = sm)
      parameter$CI <- quantile(samp.dist, c(0.05, 0.95))
      return(parameter)
    }
  }
  
  else if (parameter$model == "bootstrap") {
    samp.dist <- rep(NA, parameter$R)
    for (i in 1:parameter$R) {
      b <- sample(parameter$data, parameter$n, replace = TRUE)
      samp.dist[i] <- sm(b)
    }
    parameter$CI <- quantile(samp.dist, c(0.05, 0.95))
    return(parameter)
  }
  
  else if (parameter$model == "KDE") {
    ecdfstar <- function(t, dat, smooth) {
      outer(t, dat, function(a, b) {
        pnorm(a, b, smooth)
      }) %>% rowMeans
    }
    
    tbl <-
      data.frame(x = seq(min(data) - 2 * sd(data), max(data) + 2 * sd(data), by = 0.01))
    tbl$p <- ecdfstar(tbl$x, data, parameter$smoo)
    tbl <- tbl[!duplicated(tbl$p), ]
    tbl$p[1] <- -Inf
    tbl$p[nrow(tbl)] <- Inf
    
    qkde <- function(ps, tbl) {
      rows <- cut(ps, tbl$p, labels = FALSE)
      tbl[rows, "x"]
    }
    
    U <- runif(parameter$n * parameter$R)
    sim.data <-
      array(qkde(U, tbl), dim = c(parameter$n, parameter$R))
    samp.dist <- apply(sim.data, 2, FUN = sm)
    #browser()
    sum(is.na(samp.dist))
    parameter$CI <- quantile(samp.dist, c(0.05, 0.95))
    return(parameter)
  }
}

capture_stat <- function(parameter) {
  true.norm.med <- qnorm(0.5)
  true.norm.min <-
    mean(apply(array(
      rnorm(parameter$n * 10000), dim = c(parameter$n, 10000)
    ), 2, min))
  true.gamma.med <- qgamma(0.5, shape = 1.4, scale = 3)
  true.gamma.min <-
    mean(apply(array(
      rgamma(parameter$n * 10000, shape = 1.4, scale = 3),
      dim = c(parameter$n, 10000)
    ), 2, min))
  
  if (parameter$dist == "normal" &
      parameter$model == "moments_gamma") {
    return (NA)
  }
  
  else if (sum(is.na(parameter$CI))) {
    return(NA)
  }
  
  else if (parameter$dist == "normal") {
    if (parameter$stat == "median") {
      if (parameter$CI[1] < true.norm.med &
          true.norm.med < parameter$CI[2]) {
        count = 1
      } else {
        count = 0
      }
      return(count)
    }
    
    if (parameter$stat == "min") {
      if (parameter$CI[1] < true.norm.min &
          true.norm.min < parameter$CI[2]) {
        count = 1
      } else {
        count = 0
      }
      return(count)
    }
  } else if (parameter$dist == "gamma") {
    if (parameter$stat == "median") {
      if (parameter$CI[1] < true.gamma.med &
          true.gamma.med < parameter$CI[2]) {
        count = 1
      } else {
        count = 0
      }
      return(count)
    }
    if (parameter$stat == "min") {
      if (parameter$CI[1] < true.gamma.min &
          true.gamma.min < parameter$CI[2]) {
        count = 1
      } else {
        count = 0
      }
      return(count)
    }
  }
}

sim.settings <-
  expand.grid(
    dist = c("normal", "gamma"),
    model = c("moments_normal", "moments_gamma", "bootstrap", "KDE"),
    par.int = c("median", "min"),
    cov.prob = NA,
    stringsAsFactors = FALSE,
    KEEP.OUT.ATTRS = FALSE
  )

for (k in args) {
  parameters <-
    list(
      n = 201,
      dist = sim.settings[k, 1],
      mean = 0,
      sd = 1,
      shape = 1.4,
      scale = 3,
      model = sim.settings[k, 2],
      stat = sim.settings[k, 3],
      R = 5000,
      smoo = 0.3
    )
  cover <- NA
  for (sims in 1:10) {
    cover[sims] <- parameters %>%
      generate_data %>% estimate_CI %>% capture_stat
  }
  sim.settings[k, 4] <- mean(cover)
}

outfile <- "./results/" 
saveRDS(sim.settings[args, ], file = outfile)