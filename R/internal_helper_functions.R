#' @description Function to create expanded keep and random effect grp object
expand.mat_vec <- function(pop_n, 
                           mat) {
  
  keep.mat <- matrix(1, length(pop_n), length(pop_n))
  diag(keep.mat) <- 0
  
  keep.mat <- keep.mat[rep(1:nrow(keep.mat), times = pop_n), 
                       rep(1:ncol(keep.mat), times = pop_n)]
  
  keep <- lower(keep.mat)
  
  mat <- mat[rep(1:nrow(mat), times = pop_n), 
             rep(1:ncol(mat), times = pop_n)]
  
  out <- lower(mat)
  
  return(out)
}

#' @description Function to create expanded pop-to-ind data frame. Use internally to generate vector of indices to retain for analysis
expand.keep <- function(pop_n){
  
  keep.mat <- matrix(1, length(pop_n), length(pop_n))
  diag(keep.mat) <- 0
  
  keep.mat <- keep.mat[rep(1:nrow(keep.mat), times = pop_n), 
                       rep(1:ncol(keep.mat), times = pop_n)]
  
  keep <- lower(keep.mat)
  
  return(keep)
}

#' @description Function to create expanded pop-to-ind data frame. Use internally to convert population-based pairiwse distances to individual-based vector
expand.mat <- function(mat,
                       pop_n,
                       format = 'vector') {
  if(is.null(pop_n)){
    return(mat)
    
  } else {
    
    if(is.vector(mat) | dim(mat)[2] == 1) {
      n.mat <- matrix(0, length(pop_n), length(pop_n))
      n.mat[lower.tri(n.mat)] <- mat
      mat <- n.mat
    }
    
    if(length(pop_n) != ncol(mat)) {
      stop("Number of populations in pop_n does not match number of populations sampled!")
    }
    
    keep.mat <- matrix(1, length(pop_n), length(pop_n))
    diag(keep.mat) <- 0
    
    keep.mat <- keep.mat[rep(1:nrow(keep.mat), times = pop_n), 
                         rep(1:ncol(keep.mat), times = pop_n)]
    
    keep <- lower(keep.mat)
    
    mat <- mat[rep(1:nrow(mat), times = pop_n), 
               rep(1:ncol(mat), times = pop_n)]
    
    if(format == 'vector'){
      out <- lower(mat)[keep == 1]
      
    } else {
      out <- mat
    }
    
    return(out)
  }
}

#' @description Function to create expanded pop-to-pop data frame
expand.mat_ <- function(from_mat,
                        to_mat,
                        pop_n) {
  
  # args <- list(...)
  
  if(length(pop_n) != ncol(from_mat)) {
    stop("Number of populations in pop_n does not match number of populations sampled!")
  }
  
  obs <- length(pop_n)
  cnt <- 0
  
  out.list <- vector(mode = 'list')
  
  for(i in 1:(obs-1)) {
    pop1 <- from_mat[(i+1):obs, i]
    pop2 <- to_mat[(i+1):obs, i]
    
    tfi <- cbind(pop1, pop2)
    
    for(j in 1:nrow(tfi)) {
      for(k in 1:2) {
        cnt <- cnt + 1
        tfi.rep <- tfi[rep(j, times = pop_n[tfi[j,k]]),]
        out.list[[cnt]] <- tfi.rep
        
      } # End k
    } # End j
  } # End i
  
  out.df <- do.call(rbind, out.list) %>% as.data.frame()
  out.df$pop1 <- factor(out.df$pop1)
  out.df$pop2 <- factor(out.df$pop2)
  
  return(out.df)
}

## FOR ASSESSING AICc of fitted models, not exported
Resistance.Opt_AICc <-
  function(PARM,
           Resistance,
           CS.inputs = NULL,
           gdist.inputs = NULL,
           jl.inputs = NULL,
           GA.inputs,
           Min.Max = 'max',
           iter = NULL,
           quiet = FALSE) {
    t1 <- proc.time()[3]
    
    EXPORT.dir <- GA.inputs$Write.dir
    
    r <- Resistance
    if (!is.null(iter)) {
      if (GA.inputs$surface.type[iter] == "cat") {
        PARM <- PARM / min(PARM)
        parm <- PARM
        df <-
          data.frame(id = unique(r), PARM) # Data frame with original raster values and replacement values
        r <- subs(r, df)
        
      } else {
        r <- SCALE(r, 0, 10)
        
        # Set equation for continuous surface
        equation <- floor(PARM[1]) # Parameter can range from 1-9.99
        
        # Read in resistance surface to be optimized
        SHAPE <- (PARM[2])
        Max.SCALE <- (PARM[3])
        
        # Apply specified transformation
        rick.eq <- (equation == 2 ||
                      equation == 4 ||
                      equation == 6 || equation == 8)
        if (rick.eq == TRUE & SHAPE > 5) {
          equation <- 9
        }
        
        if (equation == 1) {
          r <- Inv.Rev.Monomolecular(r, parm = PARM)
          EQ <- "Inverse-Reverse Monomolecular"
          
        } else if (equation == 5) {
          r <- Rev.Monomolecular(r, parm = PARM)
          EQ <- "Reverse Monomolecular"
          
        } else if (equation == 3) {
          r <- Monomolecular(r, parm = PARM)
          EQ <- "Monomolecular"
          
        } else if (equation == 7) {
          r <- Inv.Monomolecular(r, parm = PARM)
          EQ <- "Inverse Monomolecular"
          
        } else if (equation == 8) {
          r <- Inv.Ricker(r, parm = PARM)
          EQ <- "Inverse Ricker"
          
        } else if (equation == 4) {
          r <- Ricker(r, parm = PARM)
          EQ <- "Ricker"
          
        } else if (equation == 6) {
          r <- Rev.Ricker(r, parm = PARM)
          EQ <- "Reverse Ricker"
          
        } else if (equation == 2) {
          r <- Inv.Rev.Ricker(r, parm = PARM)
          EQ <- "Inverse-Reverse Ricker"
          
        } else {
          r <- (r * 0) + 1 #  Distance
          EQ <- "Distance"
        } # End if-else
      } # Close parameter type if-else
    } else {
      r <- SCALE(r, 0, 10)
      
      # Set equation for continuous surface
      equation <- floor(PARM[1]) # Parameter can range from 1-9.99
      
      # Read in resistance surface to be optimized
      SHAPE <- (PARM[2])
      Max.SCALE <- (PARM[3])
      
      # Apply specified transformation
      rick.eq <- (equation == 2 ||
                    equation == 4 || equation == 6 || equation == 8)
      if (rick.eq == TRUE & SHAPE > 5) {
        equation <- 9
      }
      
      if (equation == 1) {
        r <- Inv.Rev.Monomolecular(r, parm = PARM)
        EQ <- "Inverse-Reverse Monomolecular"
        
      } else if (equation == 5) {
        r <- Rev.Monomolecular(r, parm = PARM)
        EQ <- "Reverse Monomolecular"
        
      } else if (equation == 3) {
        r <- Monomolecular(r, parm = PARM)
        EQ <- "Monomolecular"
        
      } else if (equation == 7) {
        r <- Inv.Monomolecular(r, parm = PARM)
        EQ <- "Inverse Monomolecular"
        
      } else if (equation == 8) {
        r <- Inv.Ricker(r, parm = PARM)
        EQ <- "Inverse Ricker"
        
      } else if (equation == 4) {
        r <- Ricker(r, parm = PARM)
        EQ <- "Ricker"
        
      } else if (equation == 6) {
        r <- Rev.Ricker(r, parm = PARM)
        EQ <- "Reverse Ricker"
        
      } else if (equation == 2) {
        r <- Inv.Rev.Ricker(r, parm = PARM)
        EQ <- "Inverse-Reverse Ricker"
        
      } else {
        r <- (r * 0) + 1 #  Distance
        EQ <- "Distance"
      } # End if-else
    }
    File.name <- "resist_surface"
    # if (cellStats(r, "max") > 1e6)
    if (max(r@data@values, na.rm = TRUE) > 1e6)
      r <-
      SCALE(r, 1, 1e6) # Rescale surface in case resistance are too high
    r <- reclassify(r, c(-Inf, 1e-06, 1e-06, 1e6, Inf, 1e6))
    
    
    if (!is.null(CS.inputs)) {
      writeRaster(
        x = r,
        filename = paste0(EXPORT.dir, File.name, ".asc"),
        overwrite = TRUE
      )
      CS.resist <-
        Run_CS2(
          CS.inputs,
          r = r
        )
      
      # Replace NA with 0...a workaround for errors when two points fall within the same cell.
      # CS.resist[is.na(CS.resist)] <- 0
      
      # Run mixed effect model on each Circuitscape effective resistance
      AIC.stat <- suppressWarnings(AIC(
        MLPE.lmm2(
          resistance = CS.resist,
          response = CS.inputs$response,
          ID = CS.inputs$ID,
          ZZ = CS.inputs$ZZ,
          REML = FALSE
        )
      ))
      ROW <- nrow(CS.inputs$ID)
      
    }
    
    if (!is.null(jl.inputs)) {
      cd <- Run_CS.jl(jl.inputs = jl.inputs,
                      r = r,
                      CurrentMap = FALSE,
                      full.mat = FALSE)
      
      # Run mixed effect model on each Circuitscape effective resistance
      AIC.stat <- suppressWarnings(AIC(
        MLPE.lmm2(
          resistance = cd,
          response = jl.inputs$response,
          ID = jl.inputs$ID,
          ZZ = jl.inputs$ZZ,
          REML = FALSE
        )
      ))
      ROW <- nrow(jl.inputs$ID)
      
    }
    
    if (!is.null(gdist.inputs)) {
      cd <- Run_gdistance(gdist.inputs, r)
      
      AIC.stat <- suppressWarnings(AIC(
        MLPE.lmm2(
          resistance = cd,
          response = gdist.inputs$response,
          ID = gdist.inputs$ID,
          ZZ = gdist.inputs$ZZ,
          REML = FALSE
        )
      ))
      ROW <- nrow(gdist.inputs$ID)
    }
    
    k <- length(PARM) + 1
    AICc <- (AIC.stat) + (((2 * k) * (k + 1)) / (ROW - k - 1))
    
    rt <- proc.time()[3] - t1
    if (quiet == FALSE) {
      cat(paste0("\t", "Iteration took ", round(rt, digits = 2), " seconds"), "\n")
      #     cat(paste0("\t", EQ,"; ",round(SHAPE,digits=2),"; ", round(Max.SCALE,digits=2)),"\n")
      cat(paste0("\t", "AICc = ", round(AICc, 4)), "\n")
      if (!is.null(iter)) {
        if (GA.inputs$surface.type[iter] != "cat") {
          cat(paste0("\t", EQ, " | Shape = ", PARM[2], " | Max = ", PARM[3]),
              "\n",
              "\n")
        }
      }
    }
    OPTIM.DIRECTION(Min.Max) * (AICc) # Function to be minimized/maximized
  }

# FUNCTIONS
OPTIM.DIRECTION <- function(x) {
  OPTIM <- ifelse(x == 'max', -1, 1)
  return(OPTIM)
}


Cont.Param <- function(PARM) {
  df <- data.frame(PARM[1], PARM[2])
  colnames(df) <- c("shape_opt", "max")
  row.names(df) <- NULL
  return(df)
}


read.matrix <-
  function(cs.matrix) {
    lower(read.table(cs.matrix)[-1, -1])
  }


read.matrix2 <- function(cs.matrix) {
  m <- read.table(cs.matrix)[-1, -1]
}


# Create ZZ matrix for mixed effects model
ZZ.mat <- function(ID, drop = NULL) { ## Added 11/5/2019
  ID.num <- ID
  
  # Sparse correlation matrix -----------------------------------------------------------
  if(any("corr_" %in% names(ID))) {
    
    if(any("pop1.pop" %in% names(ID))) {
      # ID.num$pop1 <- as.numeric(ID.num$pop1.pop)
      # ID.num$pop2 <- as.numeric(ID.num$pop2.pop)
      
      # Zl.corr <-
      #   lapply(c("pop1.pop", "pop2.pop"), function(nm) # c("pop1", "pop2")
      #     Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
      
      ID.num$pop1 <- as.numeric(ID.num$pop1.ind)
      ID.num$pop2 <- as.numeric(ID.num$pop2.ind)
      
      Zl.corr <-
        lapply(c("pop1.ind", "pop2.ind"), function(nm) # c("pop1", "pop2")
          Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
      
      
    } else {
      ID.num$pop1 <- as.numeric(ID.num$pop1)
      ID.num$pop2 <- as.numeric(ID.num$pop2)
      
      Zl.corr <-
        lapply(c("pop1", "pop2"), function(nm) # c("pop1", "pop2")
          Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
    }
    
    
    for(i in 1:dim(Zl.corr[[1]])[1]){
      # for(j in 1:dim(Zl.corr[[1]])[2]) {
      Zl.corr[[1]][i,] <- (ID.num$pop1 == i & ID.num$corr_ == 1)
      # Zl.corr[[1]][i,j] <- ifelse(ID.num$pop1[j] == i & ID.num$cor.grp[j] == 1, 1, 0)
      # }
    }
    
    for(i in 1:dim(Zl.corr[[2]])[1]){
      # for(j in 1:dim(Zl.corr[[2]])[2]) {
      Zl.corr[[2]][i,] <- (ID.num$pop2 == i & ID.num$corr_ == 1)
      # Zl.corr[[2]][i,j] <- ifelse(ID.num$pop2[j] == i & ID.num$cor.grp[j] == 1, 1, 0)
      # }
    }
    
    ZZ.corr <- Reduce("+", Zl.corr[-1], Zl.corr[[1]])
    ZZ.corr <- Matrix::drop0(ZZ.corr)
  }
  
  
  if(any("pop1.pop" %in% names(ID))) {
    
    ### TEST
    # ID$gd<-rnorm(nrow(ID))
    # df <- data.frame(pop = ID$pop1.ind,
    #                  y = ID$gd,
    #                  x = rnorm(nrow(ID)),
    #                  grp = ID$pop1.pop,
    #                  cor.grp = ID$cor.grp,
    #                  cg = ID$pop1.pop,
    #                  cg_t = sample(x = c(1,2), size = nrow(ID), replace = T))
    
    # df <- data.frame(pop = ID$pop1,
    #                  y = ID$gd,
    #                  x = rnorm(nrow(ID)),
    #                  grp = ID$pop1,
    #                  cor.grp = ID$cor.grp,
    #                  cg = ID$pop1)
    # 
    # # fmla <- y ~ x + (1 |  pop) + (1 | grp) + (1 | grp)
    # fmla <- y ~ x + (1 |  pop) + (1 | grp)
    # mod <-
    #   lme4::lFormula(fmla,
    #            data = df)
    # mod$reTrms$Zt <- ZZ
    # dfun <- do.call(lme4::mkLmerDevfun, mod)
    # opt <- lme4::optimizeLmer(dfun)
    # 
    # MOD <-
    #   (lme4::mkMerMod(environment(dfun), opt, mod$reTrms, fr = mod$fr))
    ### END TEST
    
    Zl <-
      lapply(c("pop1.ind", "pop2.ind"), function(nm)
        Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
    ZZ.ind <- Reduce("+", Zl[-1], Zl[[1]])
    
    Zl <-
      lapply(c("pop1.pop", "pop2.pop"), function(nm)
        Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
    ZZ.pop <- Reduce("+", Zl[-1], Zl[[1]])
    
    if(any("corr_" %in% names(ID))) {
      ZZ <- rbind(ZZ.ind, ZZ.pop, ZZ.corr)
      
    } else {
      ZZ <- rbind(ZZ.ind, ZZ.pop)
      
    }
    
  } else {
    Zl <-
      lapply(c("pop1", "pop2"), function(nm)
        Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
    ZZ <- ZZ.pop <- Reduce("+", Zl[-1], Zl[[1]])
    
    if(any("corr_" %in% names(ID))) {
      ZZ <- rbind(ZZ.pop, ZZ.corr)
      
    }
  }
  
  if(!is.null(drop)){
    ZZ <- ZZ[, drop == 1]
  }
  
  return(ZZ)
  
} ## End function

ZZ.mat_select <- function(ID, drop) {
  Zl <-
    lapply(c("pop1", "pop2"), function(nm)
      Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
  ZZ <- Reduce("+", Zl[-1], Zl[[1]])
  
  ZZ <- ZZ[, drop == 1]
  
  return(ZZ)
  
  # Zl <-
  #   lapply(c("pop1", "pop2"), function(nm)
  #     Matrix::fac2sparse(ID[[nm]], "d", drop = FALSE))
  # 
  # p1 <- as.numeric(ID$pop1)
  # p2 <- as.numeric(ID$pop2)
  # 
  # for(i in p1) {
  #     Zl[[1]][i,] <- Zl[[1]][i,] * drop
  # }
  # 
  # for(i in p2) {
  #     Zl[[2]][i,] <- Zl[[2]][i,] * drop
  # }
  # 
  # ZZ <- Reduce("+", Zl[-1], Zl[[1]])
  # 
  # ZZ <- ZZ[,drop == 1]
  # return(ZZ)
}


# Rescale function
SCALE.vector <- function(data, MIN, MAX, threshold = 1e-5) {
  if (abs(MIN - MAX) < threshold) {
    data[is.finite(data)] <- 0
    data
  } else {
    Mn = min(data)
    Mx = max(data)
    (MAX - MIN) / (Mx - Mn) * (data - Mx) + MAX
  }
}

# Define scaling function
# This will rescale from 1 to specified MAX
SCALE <- function(data, MIN, MAX, threshold = 1e-5) {
  if (abs(MIN - MAX) < threshold) {
    data[is.finite(raster::values(data))] <- 0
    data
  } else {
    Mn = min(raster::values(data), na.rm = TRUE)
    Mx = max(raster::values(data), na.rm = TRUE)
    (MAX - MIN) / (Mx - Mn) * (data - Mx) + MAX
  }
}

# Sample values for suggests
sv.cat <- function(levels, pop.size, min, max) {
  cat.starts <- matrix(nrow = pop.size, ncol = levels)
  for (r in 1:pop.size) {
    L <- list()
    for (i in 1:levels) {
      if (runif(1) < .5) {
        z <- runif(1)
      } else {
        z <- runif(1, min, max)
      }
      L[[i]] <- z
    }
    #   uz<-unlist(L)
    cat.starts[r, ] <- (unlist(L))
  }
  cat.starts[, 1] <- 1
  return(cat.starts)
}


# No Gaussian distribution
sv.cont.nG <- function(direction,
                       pop.size,
                       max,
                       min.scale,
                       max.scale,
                       scale = NULL, 
                       eqs) {
  inc <- c(1, 3)
  dec <- c(7, 5)
  peak <- c(2, 4, 6, 8)
  L <- list()
  
  if (!is.null(scale)) {
    cont.starts <- matrix(nrow = pop.size, ncol = 4)
    for (r in 1:pop.size) {
      scale.parm <- runif(1, min.scale, max.scale)
      if (runif(1) < .5 && direction == "Increase") {
        #       z1<-c(sample(inc,1)
        z <- Increase.starts.nG(sample(inc, 1))
        z <- c(z, scale.parm)
      } else if (runif(1) < .5 && direction == "Decrease") {
        z <- c(sample(dec, 1),
               runif(1, .01, 10),
               runif(1, 1, max),
               scale.parm)
      } else if (runif(1) < .5 && direction == "Peaked") {
        z <- c(sample(peak, 1),
               runif(1, .01, 10),
               runif(1, 1, max),
               scale.parm)
      } else {
        z <- c(sample(eqs, 1),
               # runif(1, 1, 9.99),
               runif(1, .01, 10),
               runif(1, 1, max),
               scale.parm)
      }
      cont.starts[r,] <- z
    }
  } else {
    cont.starts <- matrix(nrow = pop.size, ncol = 3)
    for (r in 1:pop.size) {
      if (runif(1) < .5 && direction == "Increase") {
        #       z1<-c(sample(inc,1)
        z <- Increase.starts.nG(sample(inc, 1))
      } else if (runif(1) < .5 && direction == "Decrease") {
        z <- c(sample(dec, 1), runif(1, .01, 10), runif(1, 1, max))
      } else if (runif(1) < .5 && direction == "Peaked") {
        z <- c(sample(peak, 1), runif(1, .01, 10), runif(1, 1, max))
      } else {
        z <- c(sample(eqs, 1),
               # runif(1, 1, 9.99), 
               runif(1, .01, 10), 
               runif(1, 1, max))
      }
      cont.starts[r,] <- z
    }
  }
  if(ncol(cont.starts) == 4) {
    rs <- sample(pop.size, floor(0.25 * pop.size), replace = F)
    cont.starts[rs, 4] <- 0.25
  }
  
  cont.starts
}

Increase.starts <- function(x) {
  if (x == 1) {
    z <- c(x, runif(1, .01, 10), runif(1, 1, 10), 1)
  } else {
    z <- c(x, runif(1, .01, 10), runif(1, 1, 100), 1)
  }
}

Increase.starts.nG <- function(x) {
  if (x == 1) {
    z <- c(x, runif(1, .01, 10), runif(1, 1, 10))
  } else {
    z <- c(x, runif(1, .01, 10), runif(1, 1, 100))
  }
}



unique <- raster::unique

eq.set <- function(include.list) {
  out <- vector(mode = "list", length = length(include.list))
  for (i in seq_along(include.list)) {
    if (include.list[[i]] == "A" | is.na(include.list[[i]])) {
      out <- 1:9
      return(out)
    } else if (include.list[[i]] == "M") {
      out <- c(1, 3, 5, 7, 9)
      return(out)
    } else if (include.list[[i]] == "R") {
      out <- c(2, 4, 6, 8, 9)
      return(out)
    } else if (!is.na(match(include.list[[i]], 1:9))) {
      out <- include.list
      return(out)
    } else {
      cat(
        "The specified transformations to assess are not valid. \n
        Please see Details of the GA.prep."
      )
    }
  }
}

get.EQ <- function(equation) {
  # Apply specified transformation
  if (is.numeric(equation)) {
    equation = floor(equation)
    if (equation == 1) {
      EQ <- "Inverse-Reverse Monomolecular"
      
    } else if (equation == 5) {
      EQ <- "Reverse Monomolecular"
      
    } else if (equation == 3) {
      EQ <- "Monomolecular"
      
    } else if (equation == 7) {
      EQ <- "Inverse Monomolecular"
      
    } else if (equation == 8) {
      EQ <- "Inverse Ricker"
      
    } else if (equation == 4) {
      EQ <- "Ricker"
      
    } else if (equation == 6) {
      EQ <- "Reverse Ricker"
      
    } else if (equation == 2) {
      EQ <- "Inverse-Reverse Ricker"
      
    } else {
      EQ <- "Distance"
    }
    
    (EQ)
  } else {
    if (equation == "Inverse-Reverse Monomolecular") {
      EQ <- 1
      
    } else if (equation == "Reverse Monomolecular") {
      EQ <- 5
      
    } else if (equation == "Monomolecular") {
      EQ <- 3
      
    } else if (equation == "Inverse Monomolecular") {
      EQ <- 7
      
    } else if (equation == "Inverse Ricker") {
      EQ <- 8
      
    } else if (equation == "Ricker") {
      EQ <- 4
      
    } else if (equation == "Reverse Ricker") {
      EQ <- 6
      
    } else if (equation == "Inverse-Reverse Ricker") {
      EQ <- 2
      
    } else {
      EQ <- 9
    }
    
    (EQ)
  }
}

Result.txt <-
  function(GA.results,
           GA.inputs,
           method,
           k,
           Run.Time,
           fit.stats,
           MLPE.coef = NULL,
           optim,
           aic,
           AICc,
           LL,
           fit.mod_REML = NULL) {
    if(class(GA.results) == 'ga') {
      summary.file <-
        paste0(GA.inputs$Results.dir, "Multisurface_Optim_Summary.txt")
      # AICc<-GA.results@fitnessValue
      # AICc<-round(AICc,digits=4)
      ELITE <- floor(GA.inputs$percent.elite * GA.inputs$pop.size)
      #   mlpe.results<-MLPE.lmm_coef(GA.inputs$Results.dir,genetic.dist=CS.inputs$response)
      
      sink(summary.file)
      cat(paste0(
        "Summary from multisurface optimization run conducted on ",
        Sys.Date()
      ),
      "\n")
      cat(paste0(" --- GA package summary output --- "), "\n")
      cat("\n")
      cat("\n")
      print(summary(GA.results))
      cat("\n")
      
      cat(paste0(" --- ResistanceGA summary output --- "), "\n")
      cat("\n")
      
      cat(paste0("Optimized using: ", method), "\n")
      cat("\n")
      cat(paste0("Objective function: ", optim), "\n")
      cat("\n")
      cat(paste0("Surfaces included in optimization:"), "\n")
      cat(GA.inputs$parm.type$name, "\n")
      cat("\n")
      cat(paste0("k =  ", k), "\n")
      cat("\n")
      cat(paste0("Minimum AIC: ", aic), "\n")
      cat("\n")
      cat(paste0("AICc: ", AICc), "\n")
      cat("\n")
      cat(paste0("Pseudo marginal R-square (R2m): ", fit.stats[[1]]), "\n")
      cat(paste0("Pseudo conditional R-square (R2c): ", fit.stats[[2]]),
          "\n")
      cat("\n")
      cat(paste0("Log Likelihood: ", LL), "\n")
      cat("\n")
      cat(paste0("Optimized values for each surface:"), "\n")
      cat(GA.results@solution, "\n")
      cat("\n")
      cat("\n")
      if(!is.null(fit.mod_REML)) {
        cat(paste0("----- Final MLPE model fit using REML -----"), "\n")
        print(summary(fit.mod_REML))
        cat("\n")
        cat("\n")
      }
      cat(paste0("Optimization took ", Run.Time, " seconds to complete"),
          "\n")
      sink()
    } else {
      sum.out <- summary(GA.results)
      summary.file <-
        paste0(GA.inputs$Results.dir, "Multisurface_Optim_Summary.txt")
      # AICc<-GA.results@fitnessValue
      # AICc<-round(AICc,digits=4)
      ELITE <- floor(GA.inputs$percent.elite * GA.inputs$pop.size)
      #   mlpe.results<-MLPE.lmm_coef(GA.inputs$Results.dir,genetic.dist=CS.inputs$response)
      
      sink(summary.file)
      cat(paste0(
        "Summary from multisurface optimization run conducted on ",
        Sys.Date()
      ),
      "\n")
      cat(paste0(" --- GA package summary output --- "), "\n")
      cat("\n")
      cat("\n")
      print(summary(GA.results))
      cat("\n")
      
      cat(paste0(" --- ResistanceGA summary output --- "), "\n")
      cat("\n")
      
      cat(paste0("Optimized using: ", method), "\n")
      cat("\n")
      cat(paste0("Objective function: ", optim), "\n")
      cat("\n")
      cat(paste0("Surfaces included in optimization:"), "\n")
      cat(GA.inputs$parm.type$name, "\n")
      cat("\n")
      
      cat(paste0("k =  ", k), "\n")
      cat("\n")
      cat(paste0("Minimum AIC: ", aic), "\n")
      cat("\n")
      cat(paste0("AICc: ", AICc), "\n")
      cat("\n")
      cat(paste0("Pseudo marginal R-square (R2m): ", fit.stats[[1]]), "\n")
      cat(paste0("Pseudo conditional R-square (R2c): ", fit.stats[[2]]),
          "\n")
      cat("\n")
      cat(paste0("Log Likelihood: ", LL), "\n")
      cat("\n")
      cat(paste0("Optimized values for each surface:"), "\n")
      cat(GA.results@solution, "\n")
      cat("\n")
      cat(paste0("Optimization took ", Run.Time, " seconds to complete"),
          "\n")
      sink()
    }
    
  }

##########################################################################################

get.name <- function(x) {
  nm <- deparse(substitute(x))
  return(nm)
}


# Transformation Eqs ------------------------------------------------------

Monomolecular <- function(r, parm) {
  parm[3] * (1 - exp(-1 * r / parm[2])) + 1 # Monomolecular
}

Inv.Monomolecular <- function(r, parm) {
  if (class(r) == "RasterLayer") {
    R <- parm[3] * (exp(-1 * r / parm[2]))
    (R <- (R - cellStats(R, stat = "min")) + 1)
  } else {
    R <- parm[3] * (exp(-1 * r / parm[2]))
    (R <- (R - min(R)) + 1)
  }
}

Inv.Rev.Monomolecular <- function(r, parm) {
  if (class(r) == "RasterLayer") {
    rev.rast <- SCALE((-1 * r), 0, 10)
    Inv.Monomolecular(rev.rast, parm)
  } else {
    rev.rast <- SCALE.vector((-1 * r), 0, 10)
    Inv.Monomolecular(rev.rast, parm)
  }
}

Rev.Monomolecular <- function(r, parm) {
  if (class(r) == "RasterLayer") {
    rev.rast <- SCALE((-1 * r), 0, 10)
    Monomolecular(rev.rast, parm)
  } else {
    rev.rast <- SCALE.vector((-1 * r), 0, 10)
    Monomolecular(rev.rast, parm)
  }
}


Ricker <- function(r, parm) {
  parm[3] * r * exp(-1 * r / parm[2]) + 1 # Ricker
}

Inv.Ricker <- function(r, parm) {
  if (class(r) == "RasterLayer") {
    R <- (-1 * parm[3]) * r * exp(-1 * r / parm[2]) - 1 # Ricker
    R <-
      # SCALE(R,
      #       MIN = abs(cellStats(R, stat = 'max')),
      #       MAX = abs(cellStats(R, stat = 'min'))) # Rescale
      SCALE(R,
            MIN = abs(max(R@data@values, na.rm = TRUE)),
            MAX = abs(min(R@data@values, na.rm = TRUE))) # Rescale
  } else {
    R <- (-1 * parm[3]) * r * exp(-1 * r / parm[2]) - 1 # Ricker
    R <- SCALE.vector(R, MIN = abs(max(R)), MAX = abs(min(R))) # Rescale
  }
}

Inv.Rev.Ricker <- function(r, parm) {
  if (class(r) == "RasterLayer") {
    rev.rast <- SCALE((-1 * r), 0, 10)
    Inv.Ricker(rev.rast, parm)
  } else {
    rev.rast <- SCALE.vector((-1 * r), 0, 10)
    Inv.Ricker(rev.rast, parm)
  }
}

Rev.Ricker <- function(r, parm) {
  if (class(r) == "RasterLayer") {
    rev.rast <- SCALE((-1 * r), 0, 10)
    Ricker(rev.rast, parm)
  } else {
    rev.rast <- SCALE.vector((-1 * r), 0, 10)
    Ricker(rev.rast, parm)
  }
}
yn.question <- function(question, add_lines_before = TRUE) {
  choices <- c("Yes", "No", "New Subdirectory")
  if(add_lines_before) cat("------------------------\n")   
  the_answer <- menu(choices, title = question)
  
  if(the_answer == 1L) {
    return(TRUE)
  } else if(the_answer == 2L) {
    return(FALSE)
  } else if(the_answer == 3L){
    return(NA)
  }
}