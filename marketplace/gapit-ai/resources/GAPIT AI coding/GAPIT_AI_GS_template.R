# =============================================================================
# GAPIT AI  GS mode code (canonical template)
# -----------------------------------------------------------------------------
# Purpose:
#   A single, reusable template for genomic selection (GS) prediction accuracy
#   evaluation via repeated k-fold cross-validation, following the GAPIT AI
#   coding convention:
#     1. source() the bundled gapit_functions.txt (never library(GAPIT)).
#     2. Unified QC (MAF + missing) before GAPIT, with a printed QC summary.
#     3. Simulate phenotype from GD/GM (y = effect + residual), keeping both
#        `y` (used for model training) and `effect` (true breeding value, used
#        ONLY for evaluating predicted breeding values).
#     4. Repeated k-fold CV with NA masking of the test phenotype to prevent
#        leakage (the internal GWAS of GAGBLUP/MAS only sees training data).
#     5. Methods covered:
#        - GAPIT native GS : gBLUP, cBLUP, sBLUP
#        - GAGBLUP         : model="BLINK", buspred=TRUE, lmpred=FALSE
#                            (significant markers enter the RANDOM kinship term)
#        - MAS             : model="BLINK", buspred=TRUE, lmpred=TRUE
#                            (significant markers enter a FIXED linear model)
#        - BayesB          : external BGLR package (model="BayesB")
#        - rrBLUP          : external rrBLUP package (ridge regression BLUP)
#     6. Dual accuracy: correlation against observed phenotype AND against the
#        true breeding value (effect). Prediction column names are detected
#        dynamically (never hard-coded column numbers).
#     7. Checkpoint/resume: each fold is saved as an .rds file.
#
# GAGBLUP / MAS parameters:
#   buspred  = TRUE   -> run BUS (GWAS-assisted) prediction after GWAS.
#   lmpred   = FALSE  -> GAGBLUP (significant markers in the mixed/random term).
#   lmpred   = TRUE   -> MAS    (significant markers in a fixed linear model).
#   pv.cut   = 0.2    -> proportion of markers used for the random-term kinship.
#                        Markers are sorted by P value (ascending); the
#                        significant markers are removed, then the top
#                        `pv.cut` fraction of the remaining markers is used
#                        (default 0.2 = 20%).
#
# Comment language rule (GAPIT AI convention):
#   This baseline template uses English comments. When the skill generates code
#   for a user, the comment language MUST follow the user's language.
# =============================================================================

rm(list = ls())

## =============================================================================
## 1. CONFIG (user-editable)
## =============================================================================

# --- Path to the unzipped GAPIT AI skill package ------------------------------
skill_dir <- "path/to/installed/gapit-ai"

# --- Input files --------------------------------------------------------------
geno_file <- "genotype_numeric.txt"      # numeric GD (individuals x markers)
map_file  <- "SNP_information.txt"       # GM (SNP, Chromosome, Position)
pheno_file <- NULL                       # optional real phenotype; NULL = simulate

# --- Unified QC thresholds ----------------------------------------------------
qc_maf_min     <- 0.05
qc_missing_max <- 0.20

# --- Phenotype simulation -----------------------------------------------------
sim_h2   <- 0.75
sim_NQTN <- 10
sim_seed <- 20261015

# --- Cross-validation ---------------------------------------------------------
n_repeats <- 5                            # number of repeated CV
n_folds   <- 5                            # k folds
seed_base <- 20261015

# --- GS methods (subset as needed) -------------------------------------------
# GAPIT native: "gBLUP","cBLUP","sBLUP","GAGBLUP","MAS"
# External    : "BayesB" (BGLR), "rrBLUP" (rrBLUP)
method_store <- c("gBLUP", "sBLUP", "GAGBLUP", "MAS", "BayesB", "rrBLUP")

# --- GAPIT parameters ---------------------------------------------------------
pca_total <- 3
snp_maf   <- 0.05
pv_cut    <- 0.2                          # GAGBLUP random-term marker fraction
gwas_model <- "BLINK"                     # GWAS front-end for GAGBLUP/MAS

# --- External-package parameters ---------------------------------------------
bglr_nIter    <- 6000                     # BGLR iterations
bglr_burnIn   <- 1000                     # BGLR burn-in

# --- Output -------------------------------------------------------------------
out_dir <- "GAPIT_GS_output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
ckpt_dir <- file.path(out_dir, "checkpoints")
dir.create(ckpt_dir, recursive = TRUE, showWarnings = FALSE)

## =============================================================================
## 2. Environment pre-check & source the bundled GAPIT functions
## =============================================================================
# Check key dependencies BEFORE source() so a missing package is reported
# clearly instead of surfacing as a stop() deep inside the function file.
cat("---- Environment pre-check ----\n")
cat("R version:", R.version.string, "\n")
for (pkg in c("multtest", "snpStats")) {
  cat("  package", pkg, ":",
      if (requireNamespace(pkg, quietly = TRUE)) "OK" else "MISSING (Bioconductor)",
      "\n")
}
for (pkg in c("EMMREML", "data.table")) {
  cat("  package", pkg, ":",
      if (requireNamespace(pkg, quietly = TRUE)) "OK" else "MISSING (optional)",
      "\n")
}
cat("-------------------------------\n\n")

gapit_fn <- file.path(skill_dir, "resources",
                      "gapit_functions.txt")
if (!file.exists(gapit_fn)) {
  stop("gapit_functions.txt not found. Check skill_dir:\n", gapit_fn)
}
source(gapit_fn)
if (!exists("GAPIT", mode = "function")) {
  stop("GAPIT() not available after source(). Check the function file.")
}

## =============================================================================
## 3. Load, validate, and unified QC
## =============================================================================
if (!file.exists(geno_file)) stop("Genotype file not found: ", geno_file)
if (!file.exists(map_file))  stop("Map file not found: ", map_file)

myGD <- read.table(geno_file, header = TRUE, check.names = FALSE,
                   stringsAsFactors = FALSE)
myGM <- read.table(map_file,  header = TRUE, check.names = FALSE,
                   stringsAsFactors = FALSE)
if (!"Taxa" %in% colnames(myGD)) colnames(myGD)[1] <- "Taxa"

gm_cols <- c("SNP", "Chromosome", "Position")
if (!all(gm_cols %in% colnames(myGM))) {
  stop("Map file must contain columns: SNP, Chromosome, Position")
}
myGM <- myGM[, gm_cols, drop = FALSE]

common_snps <- intersect(colnames(myGD)[-1], myGM$SNP)
if (length(common_snps) == 0) stop("No shared SNP between GD and GM.")
myGM <- myGM[match(common_snps, myGM$SNP), , drop = FALSE]
myGD <- myGD[, c("Taxa", common_snps), drop = FALSE]

# --- Unified QC ---------------------------------------------------------------
geno_mat <- as.matrix(myGD[, -1, drop = FALSE])
storage.mode(geno_mat) <- "double"
missing_rate <- colMeans(is.na(geno_mat))
allele_freq  <- colMeans(geno_mat, na.rm = TRUE) / 2
maf          <- pmin(allele_freq, 1 - allele_freq)
keep_marker  <- (missing_rate <= qc_missing_max) & (maf >= qc_maf_min)

cat("==============================================\n")
cat("Unified QC summary (before GAPIT)\n")
cat("  Markers read        :", ncol(geno_mat), "\n")
cat("  Retained after QC   :", sum(keep_marker), "\n")
cat("==============================================\n")
if (sum(keep_marker) == 0) stop("No marker passed QC.")
if (sum(keep_marker) < ncol(geno_mat)) {
  myGD <- myGD[, c(TRUE, keep_marker), drop = FALSE]
  myGM <- myGM[keep_marker, , drop = FALSE]
}
geno_mat <- as.matrix(myGD[, -1, drop = FALSE])
storage.mode(geno_mat) <- "double"

## =============================================================================
## 4. Phenotype: real or simulated
## =============================================================================
if (!is.null(pheno_file)) {
  myY <- read.table(pheno_file, header = TRUE, check.names = FALSE,
                    stringsAsFactors = FALSE)
  if (!"Taxa" %in% colnames(myY)) colnames(myY)[1] <- "Taxa"
  myY <- myY[, c(1, 2)]
  colnames(myY) <- c("Taxa", "Trait")
  myY <- myY[!is.na(myY$Trait), , drop = FALSE]
  myY <- myY[myY$Taxa %in% myGD$Taxa, , drop = FALSE]
  effect_vec <- NULL
  has_effect <- FALSE
} else {
  set.seed(sim_seed)
  sim <- GAPIT.Phenotype.Simulation(GD = myGD, GM = myGM,
                                    h2 = sim_h2, NQTN = sim_NQTN)
  myY <- sim$Y
  colnames(myY) <- c("Taxa", "Trait")
  effect_vec <- sim$u                    # true additive genetic value
  has_effect <- TRUE
  write.csv(myY, file.path(out_dir, "simulation_y.csv"), row.names = FALSE)
  write.csv(data.frame(Taxa = myY$Taxa, effect = effect_vec, residual = sim$e),
            file.path(out_dir, "simulation_effect_residual.csv"), row.names = FALSE)

  # Report realized heritability; when a REML h² is also estimated on real data,
  # report BOTH values (realized h² and estimated h²) to avoid misreading the
  # small-sample downward bias as a method failure.
  realized_h2 <- stats::var(effect_vec) / stats::var(myY$Trait)
  cat("Simulated heritability: target =", sim_h2,
      "| realized =", round(realized_h2, 4), "\n")
}

# Keep GD aligned with Y taxa order.
myY  <- myY[myY$Taxa %in% myGD$Taxa, , drop = FALSE]
myGD <- myGD[match(myY$Taxa, myGD$Taxa), , drop = FALSE]
geno_mat <- as.matrix(myGD[, -1, drop = FALSE])
storage.mode(geno_mat) <- "double"
taxa_all <- myY$Taxa

## =============================================================================
## 5. Helper functions
## =============================================================================
make_folds <- function(n, k, seed) {
  set.seed(seed)
  sample(rep(seq_len(k), length.out = n))
}

# Dynamically detect prediction columns from GAPIT $Pred.
get_pred_cols <- function(pred_df) {
  bv_col <- intersect(c("gBreedingValue", "BLUP", "Predicted_Value"), colnames(pred_df))
  ph_col <- intersect(c("Prediction", "Predicted_Value", "BLUP"), colnames(pred_df))
  list(bv = if (length(bv_col)) bv_col[1] else NA_character_,
       ph = if (length(ph_col)) ph_col[1] else NA_character_)
}

# Standardize a prediction data.frame to: Taxa, gBreedingValue, Prediction.
std_pred <- function(pred_df) {
  cols <- get_pred_cols(pred_df)
  if (is.na(cols$ph) && is.na(cols$bv)) return(NULL)
  taxa_col <- colnames(pred_df)[1]
  out <- data.frame(Taxa = as.character(pred_df[[taxa_col]]),
                    stringsAsFactors = FALSE)
  out$gBreedingValue <- if (!is.na(cols$bv)) pred_df[[cols$bv]] else pred_df[[cols$ph]]
  out$Prediction     <- if (!is.na(cols$ph)) pred_df[[cols$ph]] else pred_df[[cols$bv]]
  out
}

## -----------------------------------------------------------------------------
## Method runners: each returns std_pred for ALL individuals in GD.
## -----------------------------------------------------------------------------
run_gapit_gs <- function(method, Y_cv, GD_all, GM_map) {
  fit <- GAPIT(Y = Y_cv, GD = GD_all, GM = GM_map,
               PCA.total = pca_total, SNP.MAF = snp_maf,
               model = method, file.output = FALSE, Multiple_analysis = FALSE)
  std_pred(fit$Pred)
}

run_gagblup <- function(Y_cv, GD_all, GM_map, lmpred_flag) {
  fit <- GAPIT(Y = Y_cv, GD = GD_all, GM = GM_map,
               PCA.total = pca_total, SNP.MAF = snp_maf,
               model = gwas_model,
               buspred = TRUE,
               lmpred = lmpred_flag,
               pv.cut = pv_cut,
               file.output = FALSE, Multiple_analysis = FALSE)
  std_pred(fit$Pred)
}

run_bayesb_bglr <- function(Y_train, Z_train, Z_all, taxa_all) {
  if (!requireNamespace("BGLR", quietly = TRUE)) {
    stop("BGLR package is not installed. Install it with install.packages('BGLR').")
  }
  ETA <- list(list(X = Z_train, model = "BayesB"))
  fm <- BGLR::BGLR(y = Y_train$Trait, ETA = ETA,
                   nIter = bglr_nIter, burnIn = bglr_burnIn, verbose = FALSE)
  gbv <- as.numeric(Z_all %*% fm$ETA[[1]]$b + fm$mu)
  data.frame(Taxa = taxa_all, gBreedingValue = gbv, Prediction = gbv)
}

run_rrblup <- function(Y_train, Z_train, Z_all, taxa_all) {
  if (!requireNamespace("rrBLUP", quietly = TRUE)) {
    stop("rrBLUP package is not installed. Install it with install.packages('rrBLUP').")
  }
  fm <- rrBLUP::mixed.solve(y = Y_train$Trait, Z = Z_train)
  mu  <- if (is.null(fm$beta)) 0 else fm$beta[1]
  gbv <- as.numeric(mu + Z_all %*% fm$u)
  data.frame(Taxa = taxa_all, gBreedingValue = gbv, Prediction = gbv)
}

## =============================================================================
## 6. Repeated k-fold cross-validation
## =============================================================================
cv_results <- data.frame(
  repeat_id = integer(), fold_id = integer(), method = character(),
  n_train = integer(), n_test = integer(),
  acc_obs = numeric(), acc_effect = numeric(),
  stringsAsFactors = FALSE
)

Z_all <- geno_mat   # 0/1/2 marker matrix (individuals x markers)

for (rep_id in seq_len(n_repeats)) {
  fold_vec <- make_folds(n = nrow(myY), k = n_folds, seed = seed_base + rep_id)

  for (fold_id in seq_len(n_folds)) {
    train_idx <- which(fold_vec != fold_id)
    test_idx  <- which(fold_vec == fold_id)
    test_taxa <- taxa_all[test_idx]

    # NA-mask the test phenotype to prevent leakage.
    Y_cv <- myY
    Y_cv[test_idx, "Trait"] <- NA
    Y_train <- myY[train_idx, , drop = FALSE]

    Z_train <- Z_all[train_idx, , drop = FALSE]

    for (method in method_store) {
      ckpt_file <- file.path(ckpt_dir, sprintf("rep%d_fold%d_%s.rds",
                                               rep_id, fold_id, method))
      if (file.exists(ckpt_file)) next   # resume

      cat(sprintf("Repeat %d / %d, Fold %d / %d, Method %s\n",
                  rep_id, n_repeats, fold_id, n_folds, method))

      pred <- tryCatch(
        switch(method,
               "gBLUP"  = run_gapit_gs("gBLUP",  Y_cv, myGD, myGM),
               "cBLUP"  = run_gapit_gs("cBLUP",  Y_cv, myGD, myGM),
               "sBLUP"  = run_gapit_gs("sBLUP",  Y_cv, myGD, myGM),
               "GAGBLUP"= run_gagblup(Y_cv, myGD, myGM, lmpred_flag = FALSE),
               "MAS"    = run_gagblup(Y_cv, myGD, myGM, lmpred_flag = TRUE),
               "BayesB" = run_bayesb_bglr(Y_train, Z_train, Z_all, taxa_all),
               "rrBLUP" = run_rrblup(Y_train, Z_train, Z_all, taxa_all),
               stop("Unsupported method: ", method)),
        error = function(e) { warning(conditionMessage(e)); NULL }
      )

      if (is.null(pred)) {
        saveRDS(list(method = method, error = TRUE),
                file = ckpt_file)
        next
      }

      pred_test <- pred[match(test_taxa, pred$Taxa), , drop = FALSE]

      acc_obs <- suppressWarnings(
        cor(myY$Trait[test_idx], pred_test$Prediction, use = "complete.obs"))

      acc_effect <- NA_real_
      if (has_effect && !is.null(effect_vec)) {
        acc_effect <- suppressWarnings(
          cor(effect_vec[test_idx], pred_test$gBreedingValue, use = "complete.obs"))
      }

      row_i <- data.frame(
        repeat_id = rep_id, fold_id = fold_id, method = method,
        n_train = length(train_idx), n_test = length(test_idx),
        acc_obs = acc_obs, acc_effect = acc_effect,
        stringsAsFactors = FALSE
      )
      cv_results <- rbind(cv_results, row_i)
      saveRDS(row_i, file = ckpt_file)
    }
  }
}

## =============================================================================
## 7. Summary and export
## =============================================================================
write.csv(cv_results, file.path(out_dir, "cv_results_long.csv"), row.names = FALSE)

summary_by_method <- do.call(rbind, lapply(split(cv_results, cv_results$method),
  function(d) {
    data.frame(
      method        = d$method[1],
      acc_obs_mean  = mean(d$acc_obs, na.rm = TRUE),
      acc_obs_sd    = sd(d$acc_obs, na.rm = TRUE),
      acc_effect_mean = mean(d$acc_effect, na.rm = TRUE),
      acc_effect_sd   = sd(d$acc_effect, na.rm = TRUE),
      n_folds       = sum(!is.na(d$acc_obs))
    )
  }))
rownames(summary_by_method) <- NULL
write.csv(summary_by_method, file.path(out_dir, "cv_summary.csv"), row.names = FALSE)

print(summary_by_method)
cat("\nGS cross-validation done. Outputs written to:", out_dir, "\n")

# --- Boxplot of prediction accuracy by method --------------------------------
if (nrow(cv_results) > 0) {
  grDevices::pdf(file.path(out_dir, "cv_accuracy_by_method.pdf"), width = 8, height = 6)
  graphics::boxplot(acc_obs ~ method, data = cv_results,
                    las = 2, col = "lightblue",
                    main = "Prediction accuracy (vs observed phenotype)",
                    ylab = "Correlation", xlab = "")
  grDevices::dev.off()
  if (has_effect && any(!is.na(cv_results$acc_effect))) {
    grDevices::pdf(file.path(out_dir, "cv_accuracy_effect_by_method.pdf"),
                   width = 8, height = 6)
    graphics::boxplot(acc_effect ~ method, data = cv_results,
                      las = 2, col = "lightgoldenrod",
                      main = "Prediction accuracy (vs true breeding value)",
                      ylab = "Correlation", xlab = "")
    grDevices::dev.off()
  }
}
