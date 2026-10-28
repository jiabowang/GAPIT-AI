# =============================================================================
# GAPIT AI  GWAS mode code (canonical template)
# -----------------------------------------------------------------------------
# Purpose:
#   A single, reusable template for a complete GAPIT GWAS pipeline that follows
#   the GAPIT AI coding convention:
#     1. source() the bundled gapit_functions.txt (never library(GAPIT)).
#     2. Run a lightweight unified QC (MAF + missing rate) BEFORE GAPIT and
#        print the QC summary so the user knows which markers were retained.
#     3. Optionally simulate a phenotype from GD/GM (y = effect + residual),
#        keeping BOTH `y` (used for GWAS) and `effect` (used for evaluation).
#     4. Run GWAS with one or more models:
#        GLM, MLM, CMLM, MLMM, SUPER, FarmCPU, BLINK.
#     5. Report significant loci and compute Power / FDR / Type I error using
#        GAPIT's OWN GAPIT.FDR.TypeI() function. Only the simulated QTNs are
#        evaluated for FDR; maxOut must still be set to the total marker count.
#     6. Export results (GWAS table, significant SNPs, power/FDR curves).
#
# Comment language rule (GAPIT AI convention):
#   This baseline template uses English comments. When the skill generates code
#   for a user, the comment language MUST follow the user's language.
# =============================================================================

rm(list = ls())

## -----------------------------------------------------------------------------
## 0. Working directory
## -----------------------------------------------------------------------------
# Set to the folder where input files live and outputs should be written.
# setwd("path/to/your/project")
# -----------------------------------------------------------------------------

## =============================================================================
## 1. CONFIG (user-editable)
## =============================================================================

# --- Path to the unzipped GAPIT AI skill package ------------------------------
# This is where gapit_functions.txt is bundled.
skill_dir <- "path/to/installed/gapit-ai"

# --- Input files --------------------------------------------------------------
# GD: numeric genotype (individuals x markers, first column = Taxa/ID)
# GM: marker map (SNP, Chromosome, Position)
# Y : phenotype (Taxa + trait columns). Set to NULL to simulate a phenotype.
geno_file <- "genotype_numeric.txt"      # numeric GD
map_file  <- "SNP_information.txt"       # GM
pheno_file <- NULL                       # e.g. "phenotype.txt" (optional)

# Trait column name in pheno_file (used only if pheno_file is provided).
trait_col <- NULL                        # if NULL, the 2nd column is used

# --- Unified QC thresholds (applied before GAPIT) -----------------------------
qc_maf_min     <- 0.05                   # minor allele frequency lower bound
qc_missing_max <- 0.20                   # maximum per-marker missing rate

# --- Phenotype simulation (used when pheno_file is NULL) ----------------------
sim_h2    <- 0.75                        # heritability
sim_NQTN  <- 10                          # number of simulated QTNs
sim_seed  <- 20261015                    # seed for reproducible simulation

# --- GWAS model(s) ------------------------------------------------------------
# One or more of: "GLM","MLM","CMLM","MLMM","SUPER","FarmCPU","BLINK"
model_store <- c("GLM", "BLINK")

# --- GWAS parameters ----------------------------------------------------------
pca_total <- 3                           # number of PCs used as covariates
snp_maf   <- 0.05                        # MAF filter inside GAPIT (SNP.MAF)
cutoff    <- 0.05                        # significance threshold (Bonferroni/FDR)

# --- Power / FDR / Type I evaluation (GAPIT.FDR.TypeI) ------------------------
# WS = 1 means exact-match QTN detection. maxOut must equal the TOTAL marker
# count even though only the simulated QTNs are evaluated for FDR.
fdr_ws     <- 1
fdr_maxout <- NULL                       # NULL -> set to nrow(GM) automatically

# --- Output -------------------------------------------------------------------
out_dir <- "GAPIT_GWAS_output"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

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
## 3. Load and validate input
## =============================================================================
if (!file.exists(geno_file)) stop("Genotype file not found: ", geno_file)
if (!file.exists(map_file))  stop("Map file not found: ", map_file)

myGD <- read.table(geno_file, header = TRUE, check.names = FALSE,
                   stringsAsFactors = FALSE)
myGM <- read.table(map_file,  header = TRUE, check.names = FALSE,
                   stringsAsFactors = FALSE)

# Normalize ID column names to "Taxa".
if (!"Taxa" %in% colnames(myGD)) colnames(myGD)[1] <- "Taxa"

# GM must contain SNP / Chromosome / Position.
gm_cols <- c("SNP", "Chromosome", "Position")
if (!all(gm_cols %in% colnames(myGM))) {
  stop("Map file must contain columns: SNP, Chromosome, Position")
}
myGM <- myGM[, gm_cols, drop = FALSE]

# Align GD and GM by SNP order.
common_snps <- intersect(colnames(myGD)[-1], myGM$SNP)
if (length(common_snps) == 0) {
  stop("No shared SNP between GD columns and GM$SNP.")
}
myGM <- myGM[match(common_snps, myGM$SNP), , drop = FALSE]
myGD <- myGD[, c("Taxa", common_snps), drop = FALSE]

## =============================================================================
## 4. Unified QC (MAF + missing rate) and QC summary
## =============================================================================
# Compute per-marker statistics on the 0/1/2 numeric matrix.
geno_mat <- as.matrix(myGD[, -1, drop = FALSE])
storage.mode(geno_mat) <- "double"

# Missing rate per marker (proportion of NA).
missing_rate <- colMeans(is.na(geno_mat))

# Minor allele frequency per marker (0/1/2 coding; allele count = 2*n).
allele_freq <- colMeans(geno_mat, na.rm = TRUE) / 2
maf         <- pmin(allele_freq, 1 - allele_freq)

keep_missing <- missing_rate <= qc_missing_max
keep_maf     <- maf >= qc_maf_min
keep_marker  <- keep_missing & keep_maf

cat("==============================================\n")
cat("Unified QC summary (before GAPIT)\n")
cat("  Markers read           :", ncol(geno_mat), "\n")
cat("  Removed, missing >", qc_missing_max, " :",
    sum(!keep_missing), "\n")
cat("  Removed, MAF <", qc_maf_min, "        :",
    sum(keep_missing & !keep_maf), "\n")
cat("  Retained after QC      :", sum(keep_marker), "\n")
cat("==============================================\n")

if (sum(keep_marker) == 0) stop("No marker passed QC. Relax QC thresholds.")
if (sum(keep_marker) < ncol(geno_mat)) {
  myGD <- myGD[, c(TRUE, keep_marker), drop = FALSE]
  myGM <- myGM[keep_marker, , drop = FALSE]
}
cat("Analysis will proceed with the QC-filtered markers (n =",
    nrow(myGM), ").\n\n")

## =============================================================================
## 5. Phenotype: use real phenotype or simulate one
## =============================================================================
if (!is.null(pheno_file)) {
  if (!file.exists(pheno_file)) stop("Phenotype file not found: ", pheno_file)
  myY <- read.table(pheno_file, header = TRUE, check.names = FALSE,
                    stringsAsFactors = FALSE)
  if (!"Taxa" %in% colnames(myY)) colnames(myY)[1] <- "Taxa"
  if (is.null(trait_col)) trait_col <- colnames(myY)[2]
  if (!trait_col %in% colnames(myY)) stop("Trait column not found: ", trait_col)
  myY <- myY[, c("Taxa", trait_col)]
  colnames(myY) <- c("Taxa", "Trait")
  myY <- myY[!is.na(myY$Trait), , drop = FALSE]

  # Keep only individuals present in GD.
  myY <- myY[myY$Taxa %in% myGD$Taxa, , drop = FALSE]

  effect_vec <- NULL       # no true breeding value available for real data
  qtn_pos    <- NULL       # no known QTN positions for real data
  do_sim_eval <- FALSE
} else {
  cat("No phenotype file provided. Simulating phenotype (h2 =", sim_h2,
      ", NQTN =", sim_NQTN, ").\n")
  set.seed(sim_seed)
  sim <- GAPIT.Phenotype.Simulation(
    GD    = myGD,
    GM    = myGM,
    h2    = sim_h2,
    NQTN  = sim_NQTN
  )
  myY        <- sim$Y                       # y = effect + residual (for GWAS)
  effect_vec <- sim$u                       # true additive genetic value (eval)
  qtn_pos    <- sim$QTN.position            # QTN indices on GM
  do_sim_eval <- TRUE

  # Save simulation outputs.
  write.csv(myY, file.path(out_dir, "simulation_y.csv"), row.names = FALSE)
  write.csv(data.frame(QTN_position = qtn_pos),
            file.path(out_dir, "simulation_qtn_positions.csv"), row.names = FALSE)
  write.csv(data.frame(Taxa = myY$Taxa, effect = effect_vec,
                       residual = sim$e),
            file.path(out_dir, "simulation_effect_residual.csv"), row.names = FALSE)
}

cat("Phenotype: n =", nrow(myY), "individuals.\n\n")

## =============================================================================
## 6. Run GWAS
## =============================================================================
gwas_list <- list()

for (m in model_store) {
  cat("Running GWAS model:", m, "\n")

  fit <- GAPIT(
    Y                  = myY,
    GD                 = myGD,
    GM                 = myGM,
    PCA.total          = pca_total,
    SNP.MAF            = snp_maf,
    model              = m,
    Multi_iter         = FALSE,
    Random.model       = FALSE,
    Geno.View.output   = FALSE,
    file.output        = FALSE
  )

  gwas <- fit$GWAS
  if (is.null(gwas)) {
    warning("Model ", m, " returned no GWAS table.")
    next
  }

  # Keep a minimal, ordered result table: SNP, Chr, Pos, P.
  gwas_tbl <- gwas[, c(1, 2, 3, 4)]
  colnames(gwas_tbl) <- c("SNP", "Chromosome", "Position", "P.value")
  gwas_tbl <- gwas_tbl[order(gwas_tbl$P.value), , drop = FALSE]

  gwas_list[[m]] <- list(fit = fit, gwas = gwas, gwas_tbl = gwas_tbl)

  write.csv(gwas_tbl,
            file.path(out_dir, paste0("GWAS_", m, "_results.csv")),
            row.names = FALSE)

  # --- Significant loci (Bonferroni + BH-FDR dual thresholds) ----------------
  bonf_thr <- cutoff / nrow(gwas)
  fdr_thr  <- cutoff
  pvals    <- gwas_tbl$P.value

  sig_bonf <- gwas_tbl[pvals < bonf_thr, , drop = FALSE]
  write.csv(sig_bonf,
            file.path(out_dir, paste0("GWAS_", m, "_significant_bonferroni.csv")),
            row.names = FALSE)

  sig_fdr <- gwas_tbl[stats::p.adjust(pvals, method = "BH") < fdr_thr, , drop = FALSE]
  write.csv(sig_fdr,
            file.path(out_dir, paste0("GWAS_", m, "_significant_fdr.csv")),
            row.names = FALSE)

  cat("  Model", m, ": min P =", format(min(pvals), scientific = TRUE),
      "| Bonferroni threshold =", format(bonf_thr, scientific = TRUE),
      "| significant SNPs (Bonf.) =", nrow(sig_bonf),
      "| significant SNPs (BH-FDR) =", nrow(sig_fdr), "\n")

  # --- Power / FDR / Type I (only when simulated QTNs are known) ------------
  if (do_sim_eval && !is.null(qtn_pos) && length(qtn_pos) > 0) {
    # GAPIT.FDR.TypeI expects GWAS as SNP, CHR, BP, P (optionally MAF).
    gwas_for_fdr <- gwas[, c(1, 2, 3, 4)]
    maxout <- if (is.null(fdr_maxout)) nrow(myGM) else fdr_maxout

    fdr_res <- GAPIT.FDR.TypeI(
      WS      = fdr_ws,
      GM      = myGM,
      seqQTN  = qtn_pos,
      GWAS    = gwas_for_fdr,
      maxOut  = maxout
    )

    # FDR / TypeI matrices have one row per QTN, one column per WS.
    fdr_curve <- data.frame(
      Power   = fdr_res$Power,
      FDR     = fdr_res$FDR[, 1],
      TypeI   = fdr_res$TypeI[, 1]
    )
    write.csv(fdr_curve,
              file.path(out_dir, paste0("GWAS_", m, "_power_fdr_typeI.csv")),
              row.names = FALSE)

    cat("  Model", m, ": FDR AUC =", round(fdr_res$AUC.FDR[1], 4),
        "| TypeI AUC =", round(fdr_res$AUC.T1[1], 4), "\n")
  }
}

cat("\nGWAS done. Outputs written to:", out_dir, "\n")
