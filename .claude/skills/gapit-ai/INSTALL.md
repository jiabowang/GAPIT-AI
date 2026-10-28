# GAPIT AI (Claude Code) — Installation & Usage

## What this is
GAPIT AI (GAPIT5) is a Claude Code skill for genome-wide association studies (GWAS) and genomic selection (GS). It bundles the full GAPIT function library so you do not need to install GAPIT itself as an R package.

## Prerequisites
1. **Claude Code** installed and available in your terminal.
2. **R** with `Rscript` on your `PATH`.
3. A few R packages used by the genomic-selection templates: `BGLR` and `rrBLUP` (for BayesB and rrBLUP), plus `data.table` for fast file handling.

## Loading the skill
Claude Code discovers skills from the `.claude/skills/` directory of your project (or your user-level skills directory).

Place the `gapit-ai` folder so the file `.claude/skills/gapit-ai/SKILL.md` exists in the project you open with Claude Code. Then start a Claude Code session in that project and mention the skill by name, for example:

- "Use gapit-ai to check my BLINK parameter settings."
- "Use gapit-ai to generate a GAGBLUP cross-validation script."

The bundled data lives in `data/gapit-resources/` alongside `.claude/`. Keep that folder next to the skill so the generated code can find `data/gapit-resources/code/gapit_functions.txt`.

## How generated R code loads GAPIT
Generated scripts never call `library(GAPIT)`. They load the bundled function file instead:

```r
skill_dir <- "path/to/your/workspace"   # the folder that contains data/gapit-resources
source(file.path(skill_dir, "data/gapit-resources/code/gapit_functions.txt"))
exists("GAPIT")   # should print TRUE
```

## Quick test
Ask the skill any short, data-free question to confirm it is loaded:

- "Use gapit-ai to explain what Multi_iter does in GAPIT."
- "Use gapit-ai to generate a standard BLINK GWAS code template."

If it does not respond, confirm `.claude/skills/gapit-ai/SKILL.md` exists, restart Claude Code, and reopen the project.

## Notes
- This English version mirrors the Chinese TRAE version under `.trae/skills/GAPIT-AI/`. Keep both in sync when making changes.
- Two mode-code templates under `data/gapit-resources/code/GAPIT AI coding/` are the canonical reference for generated GWAS and GS code.
