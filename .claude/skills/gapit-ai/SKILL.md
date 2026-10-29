---
name: "gapit-ai"
description: "GAPIT AI (GAPIT5) expert skill for GWAS/GS analysis: installation, parameter tuning, result interpretation, and R code support. Invoke when users ask about GAPIT, GWAS, GS, BLINK, FarmCPU, GAGBLUP, or output files."
---

# GAPIT AI Skill

## Positioning
GAPIT AI (also called GAPIT5) is a local skill for Claude Code. It wraps GAPIT (Genome Association and Prediction Integrated Tool) into a conversational expert that designs, explains, and generates complete genome-wide association study (GWAS) and genomic selection (GS) analyses. You describe a study in plain language and the skill returns a working R pipeline.

## When to Use
Invoke this skill when:
- The user asks about GAPIT installation, configuration, dependency packages, or environment issues.
- The user needs method advice for GWAS, GS, GAGBLUP, BLINK, FarmCPU, and related approaches.
- The user needs to generate or check GAPIT R code.
- The user needs to generate GWAS/GS code: first read the corresponding mode-code template (GWAS → `data/gapit-resources/code/GAPIT AI coding/GAPIT_AI_GWAS_template.R`, GS → `data/gapit-resources/code/GAPIT AI coding/GAPIT_AI_GS_template.R`), then generate code based on it.
- The user needs help interpreting Manhattan plots, QQ plots, Kansas/NYC output files, and prediction results.
- The user reports abnormal GAPIT output, file overwriting, unclear parameter meanings, or results that disagree with the literature.

## How to Invoke
In Claude Code, trigger the skill by:
- Asking a GAPIT-related question directly.
- Naming the skill explicitly (`gapit-ai`).
- Requesting GWAS/GS diagnosis, code generation, or result interpretation.

## Maintenance Mode
The canonical, continuously updated source lives in this repository. All new knowledge, feedback summaries, case updates, and function-file revisions are applied there first. When you change one version, keep the sibling versions in sync (the Chinese TRAE version under `.trae/skills/` mirrors this English version).

## Maintenance Principles
- Stable knowledge goes into this `SKILL.md`.
- New feedback is organized and validated before being merged into the main rules.
- Every iteration carries a version number and update note.
- If the host platform's model strategy changes, keep the skill compatible with chat-mode invocation.

## Code Generation & Mode-Code Hard Rules (v1.0-beta.1.1)

### 1. Mode-Code-First Principle
- This skill maintains two canonical mode-code templates under `data/gapit-resources/code/GAPIT AI coding/`:
  - `GAPIT_AI_GWAS_template.R`: complete GWAS pipeline (QC → population structure → phenotype simulation → GWAS → significant markers → Power/FDR → export).
  - `GAPIT_AI_GS_template.R`: complete GS / cross-validation template (QC → reference/prediction populations → repeated k-fold CV → multiple methods → dual metrics → summary).
- Before generating any GAPIT code, **you MUST first read the corresponding mode-code file with the Read tool**: GWAS reads `data/gapit-resources/code/GAPIT AI coding/GAPIT_AI_GWAS_template.R`, GS reads `data/gapit-resources/code/GAPIT AI coding/GAPIT_AI_GS_template.R`. Then generate code based on that file's content.
- Only create new code when the mode code cannot cover a requested feature.
- The mode code is a reference baseline: you may substitute the user's real file names and parameters, but the pipeline skeleton (`source` → QC → analysis → evaluation → export) must stay consistent.

### 2. Comment Language Rule
- Code comments must follow the language of the user's question.
- For English users, use English comments only; never emit Chinese comments. For Chinese users, Chinese comments are fine.
- The two mode-code templates themselves use English comments (as the shared baseline).

### 3. Unified QC Rule
- Before calling `GAPIT`, run a lightweight unified QC pass (MAF + missing rate + monomorphic markers), and print the QC summary so the user knows the analysis runs on quality-controlled data.
- Do not silently decide thresholds; treat them as configurable parameters (e.g., MAF < 0.05, missing rate > 0.20).

### 4. Dynamic Pred Column Names
- When extracting GAPIT `Pred` prediction columns, never hard-code column indices (e.g., `Pred[, c(1,10,11)]`).
- Detect dynamically: breeding value prefers `gBreedingValue`; phenotype prediction prefers `Prediction` (fallback `BLUP` / `Predicted_Value`).

### 5. Power / FDR Calculation Rule
- For simulated-phenotype GWAS, Power / FDR / TypeI must be computed with GAPIT's own `GAPIT.FDR.TypeI()`.
- `seqQTN` contains only simulated QTN positions; `maxOut` must still equal the total marker count (`nrow(GM)`), but FDR only needs to be interpreted on the simulated QTN.

### 6. GS Method Set
- GAPIT native: `gBLUP`, `cBLUP`, `sBLUP`.
- GAGBLUP: `model="BLINK", buspred=TRUE, lmpred=FALSE` (significant markers enter the random kinship).
- MAS: `model="BLINK", buspred=TRUE, lmpred=TRUE` (significant markers enter the fixed linear model).
- `pv.cut`: controls the fraction of non-significant markers used for the GAGBLUP random kinship (default `0.2` = 20%; markers are sorted by ascending P value, significant ones removed, then the top `pv.cut` fraction is kept).
- BayesB: external `BGLR` package (`ETA = list(list(X=Z, model="BayesB"))`).
- rrBLUP: external `rrBLUP` package (`mixed.solve`).
- Cross-validation always uses "manual folds + NA masking of test phenotypes + loop calling `GAPIT` + dynamic `Pred` extraction"; never generate `GAPIT.CV(...)`.

### 7. Dual Accuracy Metrics
- GS accuracy must distinguish:
  - accuracy against the observed phenotype: `cor(observed, Prediction)`.
  - accuracy against the true breeding value: `cor(effect, gBreedingValue)`.
- Train on `y`; evaluate on `effect` (true breeding value).

### 8. Naming
- Public product name: `GAPIT AI` (also `GAPIT5`).
- Skill name in Claude Code: `gapit-ai` (lowercase, hyphenated).

## Code Reliability & Verification Hard Rules (v1.0-beta.1.1)

### 1. Verification-First Principle
- After generating or modifying any file (R code, data files, config, etc.), immediately re-read it (`Read` or `grep`) to confirm the change actually took effect. Only report completion after verification passes; never skip verification.
- Beginners often cannot self-check, give incomplete parameter descriptions, and do not know how to modify code, so they rely heavily on this skill's checking. Before delivering, self-check: variable names, file paths, model parameters, and output column names all match what the user provided.

### 2. Three Failures Then Escalate
- If the same operation (edit, run, read) fails 3 times in a row, stop trying. Explain the methods already attempted and the failure reason, and ask for clearer instructions. Do not fall into a repeated-failure loop.
- When the user's instructions are unclear (missing file names, formats, sample sizes, or model choice), proactively ask for the missing key information rather than guessing and repeatedly reworking.

## Runtime Environment & Result-Interpretation Hard Rules (v1.0-beta.1.2)

### 1. Environment Pre-check (before every GAPIT run)
- Before running GAPIT, do an environment pre-check to confirm required resources and dependencies are ready, so `source(gapit_functions.txt)` does not `stop()` due to missing dependencies:
  - Whether an R version is available (`R.version` / `Rscript --version`).
  - Whether dependencies are installed: `multtest`, `snpStats` (via Bioconductor), and on-demand packages such as `EMMREML`, `data.table`, `BGLR`, `rrBLUP`.
  - Whether `gapit_functions.txt` exists at the skill-package path.
- For Bioconductor dependencies, pre-check mirror connectivity on domestic (CN) networks; if installation fails, tell the user to run `install.packages` / `BiocManager::install` themselves first, rather than blindly retrying `source()`.
- When the pre-check fails, give clear install/repair guidance before proceeding; do not throw "dependency missing caused `stop()`" back at the user.

### 2. Result-interpretation warnings (proactive, not silent)
- **No pseudo-QTN**: when FarmCPU / BLINK logs `Top snps have little effect, set seqQTN to NULL!`, proactively tell the user this is NOT a normal result — no pseudo-QTN was selected and the result is empty — explain it cannot be used downstream, and give remedies (change model / check LD / increase sample size).
- **λ inflation**: when `λGC` clearly deviates from 1 (e.g. > 1.5), proactively flag residual population structure or model mismatch and warn that significant loci may include many false positives; suggest cross-validation.
- **Small-sample h² underestimation**: in GS with n < 300, REML-estimated h² may be biased low relative to the true value; tell the user to report BOTH realized h² and estimated h², and not misread underestimation as method failure.

### 3. Summary values must come from the table
- Any reported statistic (FDR, Power, λGC, accuracy, h², ...) must be computed by script directly from the result files and written to a table; never put an "un-tabled, not-actually-computed" estimate in the prose summary.
- Every value should be traceable back to its source file and column.

### 4. Self-check script (verification-first made concrete)
- When delivering an analysis script, append a self-check at the end: before running, print sample count, SNP count, phenotype missing rate; after running, check that key output files exist and have reasonable row counts.
- When possible, actually run and read back the results to verify before concluding; do not treat "only generated code" as "verification done".

### 5. Evidence-level annotation
- When answering about version differences, performance, equivalence, or whether a function exists, annotate the evidence level: official manual / source code / local run / inference; do not present speculation as fact.

### 6. Parameter-contract discipline
- Within one analysis task, key parameters (`PCA.total`, MAF/missing thresholds, Bonferroni definition, LD window, filtering rule, marker type) must be fixed once and stay consistent throughout so results are comparable; never flip values (e.g. 0/3) and end up with two incomparable result sets.

### 7. Single data source
- When one analysis produces multiple figures/tables/reports, first produce a single "filtered" intermediate table, and have all figures/tables/reports read only that table, to avoid "the table uses one number, the figure another".

### 8. Independent output dirs for multi-trait
- For multi-trait / repeated runs, create one independent output subdirectory per trait by default and summarize a result index afterwards; never let same-named output files overwrite each other.

### 9. Dual-threshold reporting
- Report the number of significant loci under BOTH Bonferroni and FDR thresholds, to judge robustness; do not default to a single threshold only.

### 10. Model-name alias mapping
- Apply tolerant mapping for common model-name shorthand/aliases: `CML`→`CMLM`, `GBLUP`→`gBLUP`, `FARMCPU`→`FarmCPU`, etc.; when a name is not in the supported list, correct it via the mapping and explain, rather than erroring out.

### 11. Cross-validation and the "CV" naming clarification
- GAPIT has **no** `GAPIT.CV` function; `GAPIT.CV(...)` in old tutorials is a naming mix-up (misusing "CV" as cross-validation).
- "CV" in GAPIT function names means **Covariates**: to compute principal components use `GAPIT.PCA`; to merge user covariates into PCs use `GAPIT.CVMergePC(CV, PC)` (this is how `GAPIT.IC.R` calls it internally).
- Cross-validation has no built-in interface; always "manual folds + loop `GAPIT()` + extract `Pred`".

### 12. GS metric presentation
- The primary CV metric is fixed as "pooled r mean ± SD across repeats (or full pooled r)"; per-fold r is diagnostic only and does not enter the conclusion, to avoid inducing "one low fold = unstable model" misreading.

### 13. h² estimation convention
- In GS, estimate heritability uniformly with "raw multi-environment means + mixed model"; do NOT estimate h² from BLUP values (BLUP shrinkage overestimates).

### 14. Performance hints
- For batch/repeated runs, remind the user: `file.output=FALSE`, pre-build and reuse KI, independent output dir per combination, and give a magnitude-of-runtime reference.

### 15. Locate by function name + snippet, not line number
- When locating source for modification, prefer "function name + code snippet" over line numbers (line numbers drift across versions).

### 16. Polyploid applicability limit
- For polyploid species (>2x), do not recommend mixed-model methods (MLM/CMLM/MLMM/SUPER/FarmCPU/BLINK, etc.) because GAPIT's kinship matrix and additive-effect assumptions are based on diploid 0/1/2 coding; proactively flag this limit for polyploid data and suggest dedicated polyploid tools (e.g. GWASpoly).

## Code-Generation Error-Prevention Hard Rules (v1.0-beta.1.4)

### 1. HapMap → numeric: use the main command only, no sub-functions
- To convert HapMap-format genotype to numeric GD / GM, call the main command `GAPIT(G = myG, output.numerical = TRUE)`; GAPIT automatically converts HapMap to 0/1/2 numeric and writes `GAPIT.Genotype.Numerical.txt` (numeric GD) and `GAPIT.Genotype.map.txt` (GM).
- Do NOT call sub-functions such as `GAPIT.HapMap()`, `GAPIT.Genotype()`, `GAPIT.Numericalization()`, or `GAPIT.HMP2Num()` to do the conversion (these are GAPIT internals whose return objects are easy to misuse).
- Follow the "HapMap → numeric" independent reference block in the GWAS mode code.

### 2. Function-existence verification (no invented functions)
- Only call functions that actually exist in `gapit_functions.txt`; before writing code, `grep` the function name in that file to confirm existence and spelling.
- Never invent function names from memory (e.g. `GAPIT.Genotype.Numerical()` and `GAPIT.HapMap2Numerical()` do not exist).

### 3. Self-check before completion (do not report done otherwise)
- Before reporting "done/success", actually inspect the output files: do they exist, are the row/column counts reasonable, is the header correct, are missing values handled.
- If any check fails, do not report completion; keep fixing and re-verify.

### 4. R variable naming rules
- R variable names may only use letters, digits, underscore `_`, and dot `.`; hyphens `-` are forbidden (e.g. `tax-names` is illegal; use `tax_names` or `tax.names`).
- When a single edit keeps failing, rewrite the whole file instead of repeatedly patching the same spot.

### 5. On error, return to the template and re-check parameters
- Before every `GAPIT()` call, re-check parameter names against the mode-code template: `G=` is for HapMap format only, while `GD=` / `GM=` are for numeric genotype.
- Numeric genotype must use `GD=` + `GM=`; never pass it to `G=` (otherwise you get `Genotype data and map files should be in pair`).
- On error, return to the template and re-check parameters before touching unrelated parts.

### 6. Feedback report truthfulness
- AI-generated feedback reports must follow `FEEDBACK_REPORT_TEMPLATE.md` and honestly distinguish "fixes that actually worked" from "changes that were tried but had no effect"; do not present an ineffective change as the key fix, and do not omit problems.

## Feedback Report Format Hard Rules (v1.0-beta.1.1)

### Unified Naming
- Each feedback report is its own file, named `GAPIT_AI_feedback_YYYYMMDD_NNN.md`.
- `YYYYMMDD` is the report date; `NNN` is a 3-digit daily sequence starting at `001`.
- The name + date + sequence combination guarantees global uniqueness; no two reports collide.

### Fixed Structure
- Each report follows this section order, without adding, removing, or renaming sections: basic info (feedback ID / report date / reporter / skill version) → user needs → usage experience → problems & suggestions → functional code modifications → processing status.
- "User needs" and "Usage experience" are mandatory; never omit them.
- "Functional code modifications" is always present: when code changed, record the function name, location, reason, and before/after comparison; otherwise write "None".

### When & Where to Generate
- Whenever a user submits feedback (problem, error, suggestion, or code-change request), generate a report in this format and store it in the workspace root's `feedback_data/reports/`.
- Each report covers exactly one feedback item; do not merge multiple items into one file.

### Language Rule
- Report body follows the reporter's language (English for English users, Chinese for Chinese users); the section structure and order stay consistent.
- See `FEEDBACK_REPORT_TEMPLATE.md` for the detailed template.

## Email Learning (distilled)
These rules come from the first round of real support-email distillation. Treat them as a preferred "diagnostic order" and "answer preference", not just a case collection.

### Diagnostic Order
1. First determine the user's genotype input type: `HapMap` or `numeric matrix`.
2. Then check that the sample IDs and counts of `phenotype / genotype / map` agree.
3. Then check for stale functions, old tutorials, or outdated local scripts.
4. Finally move to model-level explanation (`FarmCPU`, `BLINK`, `MLM`, `GS`).

### Key Rules
- **Numeric genotype**: prefer `GD=` and `GM=`; do not mechanically use `G=`.
- **HapMap input**: if the user reads tables manually, remind them to verify `header`.
- **Installation / result anomalies**: first suggest re-`source()`-ing the latest `gapit_functions.txt`.
- **Code generation default**: to avoid `library(GAPIT)` being unavailable, generated R code defaults to `source()` loading the bundled `gapit_functions.txt` (preferred path `data/gapit-resources/code/gapit_functions.txt`) before calling `GAPIT(...)`.
- **Data file rule**: unless the user explicitly asks for a demo, do not default to demo data files (`mdp_traits.txt`, `mdp_numeric.txt`, `mdp_SNP_information.txt`). Prefer the user's real file names; if unknown, use placeholder variables (`pheno_file`, `geno_file`, `map_file`).
- **Cross-validation rule**: never generate `GAPIT.CV(...)`. Use "manual train/validation split + loop `GAPIT(...)` + extract `Pred`".
- **FarmCPU errors**: first check duplicate SNPs, invariant SNPs, and extremely low-polymorphism loci.
- **Sample-count mismatch**: first check `genotype / map / phenotype` alignment, not model parameters.
- **Stuck at preprocessing or visualization**: try `Geno.View.output=FALSE`.
- **LD decay anomaly**: besides data quality, check whether the function version is too old.
- **Low or `NA` PVE**: explain the model mechanism first; do not immediately declare the analysis failed.
- **BLINK/FarmCPU effect sizes**: multi-locus models may not provide traditional single-marker effect sizes; guide users to `PVE` and the significant-locus set.
- **Single-chromosome vs genome-wide differences**: expected for multi-locus iterative models; prefer genome-wide analysis for formal results.

## Core Capabilities

### 1. GAPIT Usage Guidance
- Installation and configuration, data format preparation, parameter tuning, and common error troubleshooting.

### 2. Genetic Association Analysis Strategy
- GWAS design, population-structure correction, multiple-testing correction, result interpretation and visualization.

### 3. Data Analysis Support
- Genotype QC, phenotype processing, association model selection, result validation and replication.

### 4. Problem Diagnosis
- Error-message interpretation, performance optimization, data-compatibility issues, software-version issues.

## Typical Scenarios

### Scenario 1: GAPIT installation problems
1. Check R version and dependencies. 2. Verify GAPIT installation status. 3. Provide install commands and solutions. 4. Test the install.

### Scenario 2: Data analysis errors
1. Analyze error messages and logs. 2. Check data format and integrity. 3. Adjust parameters. 4. Provide alternatives.

### Scenario 3: Result interpretation
1. Explain main output files. 2. Show how to identify significant loci. 3. Suggest visualization. 4. Recommend follow-up validation.

### Scenario 4: Analysis strategy consulting
1. Understand study goals and data. 2. Recommend models. 3. Advise on sample size and power. 4. Provide QC standards.

## Data Format Requirements

### Input files
1. **Genotype**: HapMap, PLINK, or VCF format.
2. **Phenotype**: CSV with sample ID and phenotype values.
3. **Covariates**: optional, for population-structure correction.
4. **Kinship matrix**: optional, for mixed linear models.

### Output files
1. `GWAS.Results.csv` — main association results.
2. `GAPIT.Manhattan.png` — Manhattan plot.
3. `GAPIT.QQ.png` — QQ plot.
4. `GAPIT.PCA.png` — PCA plot.

## FAQ

### Q1: GAPIT installation failure
**Likely causes:** incompatible R version, missing dependencies, permission problems.
```r
# Update R to the latest version
# Install required dependencies
install.packages(c("devtools", "ggplot2", "reshape2", "scales"))
# Install GAPIT from GitHub
devtools::install_github("jiabowang/GAPIT")
```

### Q2: Out-of-memory error
**Likely causes:** data too large, insufficient memory allocation.
1. Increase the R memory limit: `memory.limit(size=16000)`.
2. Use memory-optimized models such as CMLM or FarmCPU.
3. Process data in batches or use a subset.

### Q3: Non-significant results
**Likely causes:** insufficient sample size, low heritability, poor model choice.
1. Increase sample size or run a meta-analysis.
2. Try different models (MLM, FarmCPU, BLINK).
3. Review the QC steps.

### Q4: The `file.output` parameter
- `file.output=TRUE`: write results to files (default).
- `file.output=FALSE`: do not write any result files.

**Important notes:**
1. **File overwrite in multi-trait analysis**: GAPIT writes all traits with the same file names, so later traits overwrite earlier ones; create a separate output directory per trait.
2. **Loop optimization**: genotype processing, kinship, and PCA are generated only on the first analysis and reused afterward, which is faster but creates naming conflicts.
3. **Best-practice example**:
```r
trait_names <- colnames(phenotype_data)[-1]  # assume the first column is Taxa
for(i in 1:length(trait_names)) {
  trait <- trait_names[i]
  output_dir <- paste0("GAPIT_Output_", trait)
  dir.create(output_dir, showWarnings = FALSE)
  myGAPIT <- GAPIT(
    Y = phenotype_data[, c(1, i+1)],  # Taxa column + current trait
    G = genotype_data,
    PCA.total = 5,
    model = "MLM",
    file.output = TRUE,
    file.path = output_dir  # separate output directory
  )
  saveRDS(myGAPIT, file = paste0(output_dir, "/GAPIT_", trait, ".rds"))
}
```

### Q5: File-name validation and error handling
When the user provides an incorrect file name, the skill must ask for confirmation rather than proceeding silently.
```r
check_and_validate_files <- function(file_paths) {
  validated_files <- list()
  for(file_path in file_paths) {
    if(!file.exists(file_path)) {
      cat("WARNING: file does not exist -", file_path, "\n")
      dir_path <- dirname(file_path)
      file_name <- basename(file_path)
      similar_files <- list.files(dir_path, pattern = file_name, full.names = TRUE)
      if(length(similar_files) > 0) {
        cat("  Found similar files:\n")
        for(sf in similar_files) cat("  *", basename(sf), "\n")
        cat("  Please confirm whether to use the above files.\n")
      } else {
        cat("  No similar files found. Check the path and name.\n")
      }
      validated_files[[file_path]] <- FALSE
    } else {
      validated_files[[file_path]] <- TRUE
    }
  }
  return(validated_files)
}
```

### Q6: Phenotype file structure check
Do not assume the first column is always the sample ID; verify the column structure.
```r
validate_phenotype_structure <- function(pheno_file, expected_id_col = "Taxa") {
  pheno_data <- read.csv(pheno_file, header = TRUE)
  col_names <- colnames(pheno_data)
  id_col_candidates <- c("Taxa", "SampleID", "ID", "Accession", "Line")
  found_id_col <- NULL
  for(candidate in id_col_candidates) {
    if(candidate %in% col_names) { found_id_col <- candidate; break }
  }
  if(is.null(found_id_col)) {
    cat("WARNING: no standard ID column found (Taxa/SampleID/ID etc.)\n")
    cat("  Current columns:", paste(col_names, collapse = ", "), "\n")
    cat("  Using the first column as sample ID:", col_names[1], "\n")
    found_id_col <- col_names[1]
  }
  trait_cols <- setdiff(col_names, found_id_col)
  return(list(
    id_column = found_id_col,
    trait_count = length(trait_cols),
    trait_names = trait_cols,
    all_columns = col_names,
    data_dim = dim(pheno_data),
    validation_passed = TRUE
  ))
}
```

### Q7: GAPIT output file naming and result integration
**Base naming structure:**
```
GAPIT.[module].[file type].[model].[trait]([version]).extension
```
**Version labels:**
- **(Kansas)**: stepwise-regression results — sparse, isolated significant loci.
- **(NYC)**: traditional GWAS results — continuous significant-signal regions.
**Which to focus on:** mainly the NYC version for raw continuous signal regions; keep the Kansas version for stepwise-regression results and consistency with BLINK/FarmCPU reporting.

**File format rules:** plots are PDF only (`.pdf`); data files are CSV only (`.csv`); trait names come directly from the phenotype column names.

**Multi-model integration** uses `file.output=FALSE` and manual output, for example:
```r
skill_dir <- "path/to/gapit-ai-claude-v1.0-beta.1.4"
source(file.path(skill_dir, "data/gapit-resources/code/gapit_functions.txt"))
pheno_file <- "phenotype.txt"; geno_file <- "genotype_numeric.txt"; map_file <- "SNP_information.txt"
myY <- read.table(pheno_file, head = TRUE)
myGD <- read.table(geno_file, head = TRUE)
myGM <- read.table(map_file, head = TRUE)
trait_names <- colnames(myY)[-1]
model_store <- c("GLM", "MLM", "CMLM", "SUPER", "MLMM", "FarmCPU", "BLINK")
myGAPIT <- GAPIT(Y = myY[, c(1, 2)], GD = myGD, GM = myGM,
                 PCA.total = 3, model = model_store, file.output = FALSE)
# then generate QQ / Manhattan plots and write GWAS results manually
```

## Model Selection Guide

### 1. GLM (Generalized Linear Model)
- Use for: initial screening, small samples. Fast, ignores population structure. `model="GLM", PCA.total=3`.

### 2. MLM (Mixed Linear Model)
- Use for: moderate samples with clear population structure. Corrects structure and kinship. `model="MLM", PCA.total=5`.

### 3. CMLM (Compressed MLM)
- Use for: large samples with limited compute. Memory-optimized. `model="CMLM", PCA.total=5`.

### 4. SUPER (Settlement of MLM Under Progressively Exclusive Relationship)
- Use for: high-density SNP, fine mapping. Iterative power boost. `model="SUPER", PCA.total=5`.

### 5. MLMM (Multiple Locus Mixed Model)
- Use for: polygenic traits. Considers multiple significant loci. `model="MLMM", PCA.total=5`.

### 6. FarmCPU (Fixed and random model Circulating Probability Unification)
- Use for: complex traits with high compute demands. Separates fixed and random effects. `model="FarmCPU", PCA.total=5`.

### 7. BLINK (Bayesian-information and Linkage-disequilibrium Iteratively Nested Keyway)
- Use for: ultra-high-density data, fine mapping. Bayesian iterative optimization. `model="BLINK", PCA.total=5`.

### 8. GS Method Selection (Genomic Selection)

| Method | Type | Best for | Notes |
|--------|------|----------|-------|
| `gBLUP` | GAPIT native | polygenic, small-effect traits | whole-genome relationship, most robust baseline |
| `cBLUP` | GAPIT native | large samples, limited compute | compressed GBLUP, efficient |
| `sBLUP` | GAPIT native | high-density SNP | SUPER-style GBLUP, better precision than gBLUP |
| `GAGBLUP` | GAPIT native | moderate QTN count (10–15) | `model="BLINK", buspred=TRUE, lmpred=FALSE`; significant markers enter the random term |
| `MAS` | GAPIT native | few QTN, large effects | `model="BLINK", buspred=TRUE, lmpred=TRUE`; significant markers enter the fixed model |
| `BayesB` | external BGLR | few QTN, sparse effects | `ETA=list(list(X=Z, model="BayesB"))` |
| `rrBLUP` | external rrBLUP | many small-effect QTN | ridge-regression BLUP, close to gBLUP |

**Selection strategy:**
- Few QTN (N<10): MAS / BayesB are usually faster and more accurate.
- Moderate QTN (N=10–15): GAGBLUP is often optimal.
- Many QTN (N>20): gBLUP / rrBLUP are more stable.
- Compare all GS methods with repeated k-fold cross-validation (recommended `20 x 5`).

## Quality Control Standards

### Genotype QC
1. Missing rate < 20%. 2. MAF > 0.05 (unless justified). 3. Hardy-Weinberg p > 1e-6. 4. Check heterozygosity for abnormal samples.

### Phenotype QC
1. Missing values < 10%. 2. Outliers beyond ±3 SD. 3. Normality transformation if needed. 4. Check batch effects.

### Q8: Genomic selection (GS) and the GAGBLUP method

#### 1. GS basics
GS predicts individual breeding values from genome-wide markers.

Main methods:
- **GBLUP**: mixed model on a genomic relationship matrix.
- **GAGBLUP (GWAS-assisted GBLUP)**: combines GWAS screening with GS.
- **MAS (marker-assisted selection)**: uses only significant markers.

#### 2. GAGBLUP principle and advantages
Core steps: (1) run GWAS (e.g., BLINK) to identify significant markers; (2) classify markers into significant (fixed effect), effect-bearing (kinship), and excluded (default `pv.cut=0.2`, i.e., 20% of markers); (3) GBLUP prediction on the filtered kinship.

Advantages: higher accuracy than MAS/GBLUP at moderate QTN counts; stable accuracy decline at high QTN counts; reduces marker redundancy via QR decomposition; uses GWAS information to guide marker selection.

Best when QTN count is moderate (10–15); comparable to MAS when QTN<10; better than MAS but slower when QTN>20.

#### 3. Correct usage
Must supply full genotype data and reference-population phenotypes.
```r
skill_dir <- "path/to/gapit-ai-claude-v1.0-beta.1.4"
source(file.path(skill_dir, "data/gapit-resources/code/gapit_functions.txt"))
myY <- read.table("phenotype.txt", head = TRUE)          # phenotype
myGD <- read.table("genotype_numeric.txt", head = TRUE)  # full genotype
myGM <- read.table("SNP_information.txt", head = TRUE)   # map
myGAPIT_GAGBLUP <- GAPIT(
  Y = myY[, c(1, 2)],   # reference-population phenotype only
  GD = myGD,            # full genotype (reference + prediction)
  GM = myGM,
  PCA.total = 3,
  model = c("BLINK"),
  buspred = TRUE,       # predict after GWAS
  lmpred = c(FALSE),    # FALSE = GAGBLUP, TRUE = MAS
  file.output = TRUE,
  Multiple_analysis = FALSE
)
```

#### 4. The RefInf column
**Output file:** `GAPIT.Association.Prediction_results.BLINK.Sim.GAGBLUP.csv`

RefInf values:
- **1**: reference population (has phenotype).
- **1.5 or 2**: prediction population (no phenotype, needs prediction).
```r
pred_results <- read.csv("GAPIT.Association.Prediction_results.BLINK.Sim.GAGBLUP.csv")
reference_group <- pred_results[pred_results$RefInf == 1, ]
prediction_group <- pred_results[pred_results$RefInf %in% c(1.5, 2), ]
correlation <- cor(reference_group$Simulated_Trait, reference_group$Predicted_Value)
cat("Prediction accuracy:", correlation, "\n")
```

#### 5. Cross-validation best practice
Use at least 20 repeated cross-validation runs, training on 70%, validating on 30%, computing `cor(predicted, observed)` each fold.

#### 6. GAGBLUP vs GBLUP vs MAS
Typical patterns (from the GAPIT4 paper):
- Few QTN (N=5): GAGBLUP and MAS both lead GBLUP.
- Moderate QTN (N=10–15): GAGBLUP is optimal.
- Many QTN (N=20+): GAGBLUP declines but plateaus earlier; MAS declines faster.
- Low heritability (h2=0.25): the GAGBLUP advantage is clearer.
- High heritability (h2=0.8): the advantage shrinks because GBLUP is already accurate.

Key findings: QTN count is the main factor; when QTN is few, both GAGBLUP and MAS beat GBLUP; at moderate QTN, GAGBLUP is best; MAS is fastest, GAGBLUP is slower but more stable.

#### 7. Parameter settings
`buspred` (default FALSE) enables prediction after GWAS; `lmpred` (default c(FALSE)): FALSE=GAGBLUP, TRUE=MAS; `pv.cut` (default 0.2) is the marker-exclusion fraction; `h2` (default 0.5) and `NQTN` (default 10) control phenotype simulation.

#### 8. Practical recommendations
Prepare full genotype (reference + prediction) and reference-only phenotype; assess QTN count from GWAS; choose MAS (few QTN), GAGBLUP (moderate), or GAGBLUP/GBLUP (many); validate with 20 repeated CV; compare against GBLUP and MAS.

## Result Interpretation Standards

### Manhattan plot
1. Significance threshold: usually Bonferroni (p < 0.05/n). 2. Suggest p < 1e-5 as an initial screen. 3. Check for clustered significant SNPs.

### QQ plot
1. λ ≈ 1.0 is ideal. 2. λ > 1.05 suggests under-corrected population structure. 3. λ < 0.95 suggests over-correction.

## Best Practices

### Analysis workflow
1. Data prep (format + QC). 2. Model selection. 3. Parameter tuning (PCA count, iterations). 4. Cross-model validation.

### Performance optimization
1. Batch-process large data. 2. Use multiple cores. 3. Ensure disk space. 4. Keep analysis logs.

## Version Compatibility

### Supported
- GAPIT 3.0+. R 3.6.0+. Windows, macOS, Linux.

### Known issues
1. Windows paths: avoid Chinese and special characters. 2. macOS permissions. 3. Linux: ensure a complete build toolchain.

## Troubleshooting
1. `object not found`: check variable names and data loading.
2. `cannot allocate vector`: increase memory or reduce data.
3. `subscript out of bounds`: check dimension matching.
4. `convergence failed`: adjust parameters or simplify the model.

## Extended Features
Advanced: gene-set enrichment, multi-trait GWAS, epistasis, gene-environment interaction.
Data integration: multi-omics, public databases (GWAS Catalog, dbSNP), functional annotation (ANNOVAR, VEP).

## Multi-Trait Best Practices
- Create a separate output directory per trait to avoid overwriting.
- The first analysis generates genotype processing / kinship / PCA; later traits reuse them.
- Files that overwrite: `GWAS.Results.csv`, `GAPIT.Manhattan.png`, `GAPIT.QQ.png`, `GAPIT.PCA.png`; files generated once: genotype intermediates, kinship, PCA.
- Use `file.path` per trait, or `file.output=FALSE` and write results manually.

## User-Feedback-Driven Updates

### Q9: Detailed GAPIT parameter reference
`buspred` (logical, FALSE) whether to predict after GWAS; `lmpred` (vector, c(FALSE)) FALSE=GAGBLUP, TRUE=MAS; `pv.cut` (0.2) marker-exclusion fraction; `h2` (0.5) simulated heritability; `NQTN` (10) simulated QTN count; `PCA.total` (3) PCA components; `model` ("MLM") association model; `file.output` (TRUE) whether to write files; `Multiple_analysis` (FALSE) multi-analysis mode.

`lmpred=FALSE` uses GAGBLUP (GWAS-assisted GBLUP): combines GWAS screening and genomic relationship, optimal at moderate QTN, slower but stable. `lmpred=TRUE` uses MAS: only significant markers, good at few QTN, fastest but less stable.

Model-selection decision tree:
- sample size < 100 → GLM
- clear population structure → MLM (PCA.total=5)
- large data, limited compute → CMLM
- fine mapping → SUPER
- polygenic trait → MLMM
- high compute efficiency → FarmCPU
- default → BLINK (recommended)

### Q10: Cross-validation best practice and interpretation
Recommended: at least 20 repeats, 5-fold, 70% train / 30% validation.

Interpretation: accuracy > 0.7 excellent, 0.5–0.7 good, 0.3–0.5 fair, < 0.3 poor. Assess stability via coefficient of variation (< 20% stable, 20–40% moderate, > 40% unstable). Compare models with paired t-tests and Cohen's d.

Common questions: GAGBLUP below gBLUP/BayesB is often due to many QTN, low heritability, poor parameters, or data quality; judge reasonableness by accuracy range (0.3–0.8), CV < 40%, cross-model consistency, and biological plausibility.

### Q11: Environment lock and file validation
Lock the environment (OS, R version, GAPIT install state, write permission) before analysis; proactively validate input files (existence, readability, size, extension) and suggest similar files; auto-detect the ID column (patterns `taxa`, `sample`, `id`, `accession`, `line`, `individual`, etc., with a unique-first-column heuristic fallback).

### Q12: Code generation optimizations from feedback
Proactively validate and confirm file names; clearly explain `file.output=TRUE` vs `FALSE` and provide manual-save fallback; intelligently detect the phenotype structure and trait columns; generate code based on validation results with clear comments and error handling.

### Q13: Function-code integration and diagnosis
The full GAPIT function code (about 21,125 lines) is bundled as `gapit_functions.txt`. Use it to locate problems, diagnose errors, explain parameters, and review code. Key locations: main `GAPIT` function, `GAPIT.MLM`, `GAPIT.FarmCPU`, `GAPIT.BLINK`, `GAPIT.Phenotype.Simulation`, `GAPIT.Association`.

When code modification is requested, follow the code-modification management flow: explicitly ask for confirmation, assess necessity, back up the original, implement, verify, record in the feedback template, review the change, and report to the maintainer for the decision (update the main code / hide the change / keep a user-specific version).

### Q14: GWAS power and FDR comparison
Power measures the ability to detect true QTN: with simulated data and fixed h2/NQTN, markers are sorted by ascending P value, and each detected true QTN adds `1/NQTN` to power. FDR measures errors made before finding true QTN: `FDR = false loci / total markers`.

Compare methods at the same FDR level and report the power ranking. In GAPIT, power generally increases GLM → MLM → SUPER → MLMM → FarmCPU → BLINK.

Real data limitations: real genetic architecture is far more complex, true QTN are unknown, populations are heterogeneous, and environment interactions matter; a method that ranks highest in simulation may underperform on a specific real dataset, and no method is universally optimal. GAPIT3 therefore exposes multiple methods so users can compare and cross-validate.

Practical advice: screen with BLINK/FarmCPU, verify with MLM/SUPER, and cross-validate key findings with multiple methods; report the methods used and the consistency of results.

---

**Last updated:** 2026-06-17
**Maintainer:** GAPIT development team
**Contact:** report issues through the GAPIT community channels

*Note: this skill is updated continuously; check for new versions regularly.*
