# GAPIT-AI

An AI-agent skill for GWAS and Genomic Selection, built on [GAPIT](https://github.com/jiabowang/GAPIT).

![version](https://img.shields.io/badge/version-v1.0--beta.1.4-blue)
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
| `gapit-ai-trae-v1.0-beta.1.4.zip` | TRAE | 中文 | TRAE skill (self-contained) |
| `gapit-ai-claude-v1.0-beta.1.4.zip` | Claude Code | English | Claude Code skill |
| `gapit-ai-marketplace-v1.0-beta.1.4.zip` | TRAE Marketplace | 中文 | Uploadable to the TRAE plugin marketplace |

The three packages share the same knowledge base and mode code; they differ only in language and packaging target.

## Installation

GAPIT-AI is an **AI-agent skill** — you do not run it directly. After a one-time setup, you talk to your AI agent in plain language, and the agent reads the skill to generate, run, and interpret the GAPIT analysis for you.

### Option 1 — Let the agent install it (recommended)

Tell your agent:

> "Install the GAPIT-AI skill from https://github.com/jiabowang/GAPIT-AI"

The agent clones the repository and places the skill files where it can read them — no manual steps needed.

### Option 2 — Install manually

```bash
git clone https://github.com/jiabowang/GAPIT-AI.git
cd GAPIT-AI
./install.sh          # TRAE version (default)
# or
./install.sh claude   # Claude Code version
```

## Quick start

Once installed, just ask in plain language:

> **"Run a GWAS with BLINK on my maize data and give me the Manhattan and QQ plots."**
> GAPIT-AI loads your genotype and phenotype files, runs BLINK, then generates and interprets the Manhattan and QQ plots.

> **"Use GAGBLUP to predict phenotypes for 100 untested lines."**
> GAPIT-AI runs GWAS-assisted GBLUP and reports the predicted breeding values and prediction accuracy.

You never need to write R code yourself — the agent does it for you, based on the skill.

## Documentation

- [User Manual (English)](GAPIT_AI_User_Manual_EN.md)

## Citation

GAPIT-AI builds on GAPIT. If you use GAPIT in published work, please cite:

Wang J., Zhang Z. **GAPIT Version 4: Integration of GWAS into Genomic Prediction.** *Molecular Biology and Evolution*, 2026, msag107. https://doi.org/10.1093/molbev/msag107

## License

This repository is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

The bundled `gapit_functions.txt` is derived from [GAPIT](https://github.com/jiabowang/GAPIT), which is licensed under **GPL (>= 2)**. See [LICENSE](LICENSE) for details.
