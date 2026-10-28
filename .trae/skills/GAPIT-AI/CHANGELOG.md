# 变更记录

## v1.0-beta.1.3

### 反馈批次（2026-10-28 新增 4 份）驱动的修复与规则
- 代码修复（`code/R/`，已整合进 `gapit_functions.txt`）：
  - `GAPIT.Power` 返回加 `drop=FALSE`，修复 `WS=c(1)` 时 `$Power`/`$FDR` 降维成 vector、`pw$Power[,1]` 报错的问题。
  - `GAPIT.Main` 末尾「The results are saved ...」日志加 `if(file.output)` 门控，修复 `file.output=FALSE` 时仍打印误导信息。
- 硬规则新增（三份 SKILL.md）：
  - 第 16 条「多倍体适用性限制」：多倍体物种（>2 倍体）不建议使用基于混合模型的方法（亲缘矩阵与加性效应假设基于二倍体），建议改用多倍体专用工具。
- `GAPIT_FUNCTION_SUMMARY.md` 升级：
  - 原「核心子函数」小节替换为「函数 API 速查表」（10 组约 90 个函数，每函数签名 → 返回）。
  - 「常见问题位置索引」由行号定位改为函数名定位（对齐硬规则 #15）。
  - 删除不存在的旧函数名 `GAPIT.Association()`。
- 版本号由 v1.0-beta.1.2 升级为 v1.0-beta.1.3。

## v1.0-beta.1.2

### 反馈汇总驱动的规则与模板更新（2026-10 反馈批次）
- 新增「运行环境与结果解读硬规则」章节（15 条），吸收 11 份反馈报告的结论：
  1. 环境预检（每次运行 GAPIT 前检查 R 版本、依赖包、gapit_functions.txt）
  2. 结果解读告警（无 pseudo-QTN / λ 膨胀 / 小样本 h² 低估主动提示）
  3. 汇总数值必须落表（禁止文字摘要写未落表的估算值）
  4. 自检脚本（验证优先的落地）
  5. 证据等级标注（官方手册/源码/实测/推断）
  6. 参数口径契约（关键参数一次定死、全程一致）
  7. 单一数据源（图/表/报告共用一个过滤后中间表）
  8. 多性状独立输出目录
  9. 双阈值口径（Bonferroni + BH-FDR）
  10. 模型名容错映射（CML→CMLM 等）
  11. 交叉验证与"CV"命名澄清（GAPIT 无 GAPIT.CV；CV=协变量 → GAPIT.PCA / GAPIT.CVMergePC）
  12. GS 指标呈现规范（池化 r ± SD，单折仅诊断）
  13. h² 估计口径（原始多环境均值，禁用 BLUP 估 h²）
  14. 性能提示
  15. 行号定位改函数名 + 片段
- `GAPIT_FUNCTION_SUMMARY.md` 新增「关键返回结构与命名说明」：`Pred`/`RefInf` 结构、Kansas/NYC 图含义、CV 与协变量区分
- 模式代码模板更新：GWAS/GS 模板增加环境预检；GWAS 显著位点改 Bonferroni + BH-FDR 双阈值；GS 模拟表型报告实现 h²
- 同步英文版（Claude）与 marketplace 版

### 版本
- 版本号由 v1.0-beta.1.1 升级为 v1.0-beta.1.2；发布包名相应更新为 `gapit-ai-trae-v1.0-beta.1.2.zip`（Claude 版 `gapit-ai-claude-v1.0-beta.1.2.zip`）

## v1.0-beta.1.1

### 命名与定位
- 本技能正式命名为 **GAPIT AI**（亦可称 **GAPIT5**），发布包名为 `gapit-ai-trae-v1.0-beta.1.1.zip`
- 技能目录由 `gapit-expert` 重命名为 `GAPIT-AI`，`SKILL.md` 的 `name`/`description` 与相关引用同步更新
- `gapit_functions.txt` 去重为单一副本，仅存于 `data/gapit-resources/code/`，技能目录内不再重复存放

### 新增模式代码（mode code）
- 新增两套功能齐全的规范模式代码，置于 `data/gapit-resources/code/GAPIT AI coding/`：
  - `GAPIT_AI_GWAS_template.R`：GWAS 全流程模板，支持 GLM / MLM / CMLM / MLMM / SUPER / FarmCPU / BLINK，含统一 QC、表型模拟、Power/FDR/TypeI 计算
  - `GAPIT_AI_GS_template.R`：GS 全流程模板，支持 gBLUP / cBLUP / sBLUP / GAGBLUP / MAS / BayesB(BGLR) / rrBLUP，含重复 k 折交叉验证、双指标准确率
- 确立**模式代码优先**硬规则：优先复用模式代码；仅当模式代码无法覆盖某一功能时才新写代码

### GAPIT 函数更新
- 合并用户提供的最新 `gapit_functions.txt`（21158 行）
- 修复文件末尾残留顶层测试脚本导致 `source()` 触发 `C stack usage too close to the limit` 的问题，清理后仅保留函数定义
- 备份原始含测试脚本版本为 `gapit_functions.txt.bak_20261015_with_testcode`
- 将函数内部 `ABLUP`/`ablup` 统一重命名为 `GAGBLUP`/`gagblup`（GWAS 辅助 GBLUP），涉及 `R/GAPIT.R`、`R/GAPIT.PagainstP.R`、`R/GAPIT.SS.R` 三个子函数及合并后的 `gapit_functions.txt`；原始版本备份于 `backup_20261020_ablup_to_gagblup/`

### 技能规则更新
- 新增「代码生成与模式代码硬规则」章节，覆盖：
  1. 模式代码优先原则
  2. 注释语言规则（跟随用户语言；英文用户代码注释必须为英文）
  3. 统一 QC 规则（GAPIT 分析前统一质控，并打印质控后结果）
  4. Pred 动态列名（不硬编码列序号）
  5. Power/FDR 必须使用 `GAPIT.FDR.TypeI`；`seqQTN` 仅传模拟 QTN，`maxOut=nrow(GM)`
  6. GS 方法集合（含 GAGBLUP/MAS 的 `lmpred`/`pv.cut` 语义；不生成 `GAPIT.CV`）
  7. 双指标准确率（观测值与育种值）
  8. 命名规则
- 模型选择指南新增 GS 方法选择表（gBLUP/cBLUP/sBLUP/GAGBLUP/MAS/BayesB/rrBLUP）与重复 k 折交叉验证选择策略
- 新增「反馈报告格式硬规则」：统一命名 `GAPIT_AI_feedback_YYYYMMDD_NNN.md`（贯通前缀 + 日期 + 流水号，保证不重名）；固定报告结构，必填「用户需求」与「使用体验」，涉及代码改动时如实记录「功能代码修改」；新增模板文件 `FEEDBACK_REPORT_TEMPLATE.md`
- 新增「代码生成可靠性与验证硬规则」：验证优先（修改/生成文件后必须读回验证，交付前自查变量名/路径/参数/列名），三次失败即升级（同一操作失败 3 次即停止并向用户请求更明确指令，指令不明时主动追问）

## v1.0-beta.1

### 新增
- 将 `gapit-expert` 稳定为 `workspace skill` 形态，主维护副本位于 `.trae/skills/gapit-expert/`
- 新增基于真实邮件与 GitHub issues 的题库机制
- 新增题库说明：`QUESTION_BANK_GUIDE.md`
- 新增邮件学习沉淀：
  - `EMAIL_LEARNING_RULES.md`
  - `EMAIL_ITERATION_2026-07-14.md`
- 新增版本文件：`VERSION`
- 新增两类反馈目录：
  - `feedback_data/experience/`：用户使用体验反馈
  - `feedback_data/satisfaction/`：针对回答/结题结果的满意度反馈

### 数据与知识库
- 合并 34 个邮件分页压缩包，完成邮件语料构建、线程化和问答对齐
- 补抓 `jiabowang/GAPIT` GitHub issues 评论，显著降低未回答条目数
- 生成统一题库：
  - 内部题库：`data/gapit-resources/question_bank.jsonl`
  - 脱敏题库：`data/gapit-resources/question_bank_public.jsonl`

### 技能规则更新
- 新增邮件驱动的第一轮稳定规则：
  - 数值型基因型优先使用 `GD/GM`
  - HapMap 手动读入时必须核对 `header`
  - 安装或结果异常时优先重载最新 `gapit_functions.txt`
  - FarmCPU 报错优先排查重复/无变异 SNP
  - 个体数不一致优先检查样本 ID 对齐
  - `Geno.View.output=FALSE` 可作为卡顿排查开关
  - LD decay 异常需要检查函数版本
  - PVE 低值或 `NA` 需结合模型机制解释
  - BLINK/FarmCPU 不应机械追问传统单标记效应量
  - 单染色体与全基因组多位点结果差异不一定是错误

### 发布相关
- 生成带题库的发布压缩包
- 生成详细用户手册（另见用户手册文件）
- 打包修订：在压缩包内同步提供 `data/gapit-resources/code/gapit_functions.txt`，并将示例代码默认改为 `source()` 加载函数（不再推荐 `library(GAPIT)`）
- 规则修订：禁止默认回退到 demo data；GS / GAGBLUP 交叉验证模板禁止生成 `GAPIT.CV(...)`，统一改为手动 CV 循环；新增 `examples/gagblup_manual_cv_template.R`
