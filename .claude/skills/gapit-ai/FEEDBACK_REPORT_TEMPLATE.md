# GAPIT AI Feedback Report Template

This file defines the unified format for GAPIT AI (GAPIT5) feedback reports. All feedback must follow this structure so reports stay consistent and never collide.

## Naming rule

Feedback report files are named:

```
GAPIT_AI_feedback_YYYYMMDD_NNN.md
```

- `GAPIT_AI_feedback` is the fixed prefix.
- `YYYYMMDD` is the report date, e.g. `20261015`.
- `NNN` is a 3-digit daily sequence starting at `001`.

The name + date + sequence combination guarantees global uniqueness. Example: `GAPIT_AI_feedback_20261015_001.md`.

## Report structure

Each report contains the following sections in a fixed order; do not add, remove, or rename sections.

```markdown
# GAPIT AI Feedback Report

**Feedback ID**: GAPIT_AI_feedback_YYYYMMDD_NNN
**Report date**: YYYY-MM-DD
**Reporter**: [name / nickname]
**Skill version**: [e.g. v1.0-beta.1.3]

## User needs
[What task, question, or requirement the user raised, and what they expected the skill to do]

## Usage experience
[The user's real experience using the skill, including what worked well and any errors, slowdowns, or confusion]

## Problems & suggestions
[The specific problems encountered, plus the user's improvement suggestions]

## Functional code modifications
[Whether this feedback involved GAPIT code changes; if so, record the function name, location, reason, and before/after comparison; otherwise write "None"]

## Processing status
- Status: [Pending / In progress / Resolved]
- Priority: [High / Medium / Low]
```

## Filling requirements

- "User needs" and "Usage experience" are mandatory; never omit them.
- "Functional code modifications" is always present. When code changed, record the function name, location, reason, and before/after comparison; otherwise write "None".
- The report body follows the reporter's language (English for English users, Chinese for Chinese users); the section structure and order stay the same.
- Each report covers exactly one feedback item; do not merge multiple items into one file.

## Storage location

Store generated feedback reports in the workspace root's `feedback_data/reports/` folder.
