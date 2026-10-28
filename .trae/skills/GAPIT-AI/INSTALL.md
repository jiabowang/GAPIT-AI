# GAPIT专家技能安装与维护指南

## 定位
`GAPIT-AI` 已改为 `TRAE workspace` 可直接调用的本地技能。对当前这台电脑和当前账户而言，主维护副本就是项目内的这个目录：

`/Users/Jiabo/Documents/trae_projects/GAPIT-Agent/.trae/skills/GAPIT-AI`

只要你在 `TRAE` 中打开本项目工作区，这个技能就应作为工作区技能被加载和调用。

## 使用方式

### 方式一：当前电脑作为主理人工作区
这是推荐方式，也是默认方式。

1. 用 `TRAE` 打开项目根目录：
   `/Users/Jiabo/Documents/trae_projects/GAPIT-Agent`
2. 确认项目内存在：
   `.trae/skills/GAPIT-AI/SKILL.md`
3. 在 `TRAE Chat` 或工作区对话中直接提问 GAPIT 相关问题
4. 必要时明确点名 `GAPIT-AI`

示例：

```text
请用 GAPIT-AI 帮我检查 GAPIT 的 BLINK 参数设置
```

```text
我想做 GAGBLUP，请调用 GAPIT-AI 帮我设计分析流程
```

### 方式二：分发给其他电脑或其他账户
如果需要把当前技能副本分发到别的环境，可复制到用户级技能目录：

```bash
mkdir -p ~/.trae/skills
cp -R ./.trae/skills/GAPIT-AI ~/.trae/skills/
```

或打包后分发，再由对方解压到：

```text
~/.trae/skills/GAPIT-AI
```

## 用户侧 R 代码默认写法（重要）
很多用户环境下 `library(GAPIT)` 并不成立。对外生成的 GAPIT 运行脚本，应默认从本技能包自带的函数文件加载：

```r
# 设为你解压后的 gapit-ai-trae-v1.0-beta.1.3 目录
skill_dir <- "path/to/gapit-ai-trae-v1.0-beta.1.3"

# 直接加载 GAPIT 函数集合（推荐路径：本次已随 zip 同步到 data 目录）
source(file.path(skill_dir, "data/gapit-resources/code/gapit_functions.txt"))

# 然后正常调用
myGAPIT <- GAPIT(Y=myY, GD=myGD, GM=myGM, PCA.total=3, model="BLINK")
```

## 代码生成补充约束（重要）
- 不要生成 `library(gapit_function.txt)`、`library(GAPIT)` 这类写法。
- 不要在未获用户确认时默认切换到 demo data 文件名。
- 当前发布包里不要生成 `GAPIT.CV(...)`。交叉验证请用手动循环方式：划分训练/验证集后，循环调用 `GAPIT(...)`，再从返回的 `Pred` 中提取预测结果。

## 主理人模式

### 主维护原则
- 当前项目内的 `.trae/skills/GAPIT-AI/` 是唯一主维护源
- 本机和当前账户负责升级、修订、验证和打包
- 外部分发副本不直接作为真源修改
- 新反馈先回收到主维护源，再统一迭代版本

### 升级流程
1. 在本项目工作区内修改 `SKILL.md` 或相关支持文件
2. 用当前账户在 `TRAE` 中实际对话验证效果
3. 整理更新点，确认没有引入错误信息
4. 再打包输出新的 `skill` 版本给其他人使用

### 代码修改限制
如果需要调整 `gapit_functions.txt` 或涉及 GAPIT 原始函数行为：
- 必须先获得用户确认
- 必须保留原始备份
- 必须记录修改原因、风险和测试结果

## 技能触发建议
以下场景建议直接调用 `GAPIT-AI`：
- GAPIT 安装和依赖排查
- GWAS/GS 模型选择
- BLINK、FarmCPU、MLMM、GAGBLUP 参数咨询
- 曼哈顿图、QQ 图、Kansas/NYC 文件解读
- 多性状分析、交叉验证、结果文件覆盖问题
- GAPIT 代码生成、代码检查和函数定位

## 验证方法

### 检查目录
```bash
ls /Users/Jiabo/Documents/trae_projects/GAPIT-Agent/.trae/skills/GAPIT-AI
```

### 检查关键文件
至少应包含：
- `SKILL.md`
- `INSTALL.md`
- `FEEDBACK_TEMPLATE.md`
- `GAPIT_FUNCTION_SUMMARY.md`
- `FEEDBACK_REPORT_TEMPLATE.md`

GAPIT 函数文件位于 `data/gapit-resources/code/gapit_functions.txt`，不在技能目录内重复存放。

### 在 TRAE 中验证
建议测试以下问题：

```text
请调用 GAPIT-AI，解释 GAPIT 中 Multi_iter 的作用
```

```text
请调用 GAPIT-AI，给我一个 BLINK 的标准 GWAS 代码模板
```

```text
请调用 GAPIT-AI，解释 GAPIT.Association.Prediction_results.BLINK.Sim.GAGBLUP.csv 的 RefInf 列
```

## 对外分发建议

### 推荐版本策略
- 开发版：当前工作区中的主维护版本
- 稳定版：验证后打包给测试者或其他用户的版本

### 推荐命名
- `gapit-ai-trae-v1.0-beta.1.3.zip`
- `gapit-ai-v1.0-beta.1.3.zip`
- `gapit-ai-v1.0-beta.1.3.zip`

## 常见问题

### Q1：为什么在普通 Chat 能用，进入独立 Agent 反而模型受限？
答：`Chat` 和独立 `Agent` 可能使用不同的模型池。改成 `workspace skill` 后，更适合在普通 `Chat` 中继承当前可用模型。

### Q2：为什么我改了 skill 但别人的版本没变化？
答：因为当前项目目录才是主维护源，外部分发副本不会自动同步，需要重新打包发布。

### Q3：技能没有自动加载怎么办？
答：
1. 确认打开的是本项目根目录
2. 确认 `.trae/skills/GAPIT-AI/SKILL.md` 存在
3. 重启 `TRAE`
4. 重新打开当前工作区

### Q4：训练还没结束，能不能持续升级？
答：可以。推荐做法是持续在这个主维护目录里迭代，再按版本打包对外分发。
3. 联系维护者获取支持

## 更新和维护

### 检查更新
```bash
# 查看当前版本
trae skill info GAPIT-AI

# 检查更新（如果支持）
trae skill update GAPIT-AI
```

### 手动更新
1. 下载最新版本的技能包
2. 备份原有技能
3. 解压新版本覆盖原有文件
4. 重启Trae IDE

## 反馈和支持

### 反馈渠道
1. **GAPIT交流群**：主要反馈渠道
2. **GitHub Issues**：问题跟踪
3. **Email支持**：紧急问题联系

### 反馈模板
```
## 问题类型
- [ ] 安装问题
- [ ] 功能建议
- [ ] 错误报告
- [ ] 知识补充

## 具体描述
[请详细描述问题或建议]

## 期望结果
[你期望智能体如何回应或改进]

## 环境信息
- Trae IDE版本： [填写]
- 操作系统： [填写]
- 技能版本： [填写]
```

## 版本历史

### v1.0.0 (2026-06-04)
- 初始版本发布
- 包含GAPIT基础使用指导
- 支持常见问题解答
- 提供分析策略建议

## 注意事项
1. 本技能需要Trae IDE环境支持
2. 建议定期检查更新
3. 使用过程中遇到问题请及时反馈
4. 技能知识库会持续更新和完善

## 联系信息
- **维护团队**：GAPIT开发团队
- **主要联系人**：Jiabo Wang
- **更新频率**：每月至少一次
- **支持时间**：工作日 9:00-18:00

---

*如有任何问题或建议，请通过GAPIT交流群反馈。感谢您的使用！*
