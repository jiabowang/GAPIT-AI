# 题库（Question Bank）与评测机制

本文件定义 `gapit-expert` 的“题库驱动评测”工作流，供公开发布后复用。

## 题库文件

题库文件用于评测技能水平，也可用于模拟问题与回归测试。

- 内部题库（可能含隐私信息）：`data/gapit-resources/question_bank.jsonl`
- 发布版题库（已脱敏，推荐随 skill 对外分发）：`data/gapit-resources/question_bank_public.jsonl`

题库为 `JSONL`（一行一个题目），字段建议保持稳定：
- `bank_id`：题库唯一 ID（例如 `EMAIL::...` / `GITHUB::...`）
- `source`：`email` / `github_issue`
- `topic`：问题类型
- `tags`：关键词标签
- `question`：题干
- `metadata`：来源辅助信息（thread_id / issue_url 等）
- `status`：默认 `unanswered`；当题目被回答并验收后可改为 `answered`

## 抽题规则

- 默认每次抽取 `5–8` 题
- 若用户明确指定题目数量，则以用户要求为准
- 抽题场景默认完全随机
- 若后续需要做定向评测，可按 `topic`、`tags` 或 `source` 筛题

## 评测与打分（建议）

每次评测从题库抽题，让 skill 回答后，应生成“问题-回答对应文件”，再由人工评分。

建议产出文件：`evaluation/answers_YYYYMMDD.jsonl`

每行字段建议：
- `bank_id`
- `question`
- `answer`
- `model_or_skill_version`：当时的 skill 版本号（或 commit/tag）
- `timestamp`
- `score_accuracy`（1-5）
- `score_completeness`（1-5）
- `score_clarity`（1-5）
- `score_actionability`（1-5）
- `score_professionalism`（1-5）
- `reviewer_notes`

## 用户使用过程的问答记录（发布后必须做）

公开发布后，为了持续提升 skill，需要收集真实用户问答：
- 建议用户将关键对话导出为文本/截图/markdown
- 或使用本项目已有的 `FEEDBACK_TEMPLATE.md` 反馈模板
- 使用体验记录放入：`.trae/skills/gapit-expert/feedback_data/experience/`
- 对具体回答的满意度记录放入：`.trae/skills/gapit-expert/feedback_data/satisfaction/`

后续迭代建议：按周汇总新增问答、提炼稳定规则，再写回 `SKILL.md`，避免未经验证的经验直接进入主规则。
