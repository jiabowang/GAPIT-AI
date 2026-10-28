# GAPIT-AI

An AI-agent skill for GWAS and Genomic Selection, built on [GAPIT](https://github.com/jiabowang/GAPIT).

![version](https://img.shields.io/badge/version-v1.0--beta.1.3-blue)
![license](https://img.shields.io/badge/license-GPL--3.0-green)
![R](https://img.shields.io/badge/R-%3E%3D4.3.0-lightgrey)

## What is GAPIT-AI?

GAPIT-AI turns natural-language instructions into GAPIT-based GWAS and Genomic Selection (GS) analyses. Instead of writing R commands, users ask questions in plain language, and the skill generates, runs, and interprets GAPIT code.

Supported methods:

- **GWAS**: GLM, MLM, CMLM, MLMM, SUPER, FarmCPU, BLINK
- **GS**: gBLUP, cBLUP, sBLUP, GAGBLUP, MAS

## Available versions

| Package | Platform | Language | Description |
|---|---|---|---|
| `gapit-ai-trae-v1.0-beta.1.3.zip` | TRAE | 中文 | TRAE skill (self-contained) |
| `gapit-ai-claude-v1.0-beta.1.3.zip` | Claude Code | English | Claude Code skill |
| `gapit-ai-marketplace-v1.0-beta.1.3.zip` | TRAE Marketplace | 中文 | Uploadable to the TRAE plugin marketplace |

The three packages share the same knowledge base and mode code; they differ only in language and packaging target.

## Installation

### From GitHub (recommended)

```bash
git clone https://github.com/jiabowang/GAPIT-AI.git
cd GAPIT-AI
./install.sh          # TRAE version (default)
# or
./install.sh claude   # Claude Code version
```

The installer copies the skill into your agent's skills directory and places the shared data resources alongside it.

### From a release archive

Download the zip for your platform from [Releases](../../releases), unzip it, and place the skill folder into your agent's skills directory.

## Quick start

```r
# Load the bundled GAPIT functions
source("data/gapit-resources/code/gapit_functions.txt")

# Run a GWAS
myGAPIT <- GAPIT(
  Y  = myY,                      # phenotype (Taxa + trait)
  GD = myGD,                     # numeric genotype
  GM = myGM,                     # SNP map
  model = c("MLM", "FarmCPU", "BLINK"),
  PCA.total = 3
)
```

## Documentation

- [User Manual (English)](GAPIT_AI_User_Manual_EN.md)

## Citation

GAPIT-AI builds on GAPIT. If you use GAPIT in published work, please cite:

Wang J., Zhang Z. **GAPIT Version 4: Integration of GWAS into Genomic Prediction.** *Molecular Biology and Evolution*, 2026, msag107. https://doi.org/10.1093/molbev/msag107

## License

This repository is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

The bundled `gapit_functions.txt` is derived from [GAPIT](https://github.com/jiabowang/GAPIT), which is licensed under **GPL (>= 2)**. See [LICENSE](LICENSE) for details.
