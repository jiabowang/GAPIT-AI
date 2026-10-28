# GAPIT函数代码摘要

## 概述
本文档提供了GAPIT核心函数的摘要信息，帮助智能体理解GAPIT的内部实现，以便更好地诊断问题和解释功能。

## 主函数：`GAPIT()`

### 函数签名
```r
`GAPIT` <- function(
  Y = NULL,           # 表型数据
  G = NULL,           # HapMap格式基因型
  GD = NULL,          # 数值型基因型
  GM = NULL,          # SNP信息
  KI = NULL,          # 亲缘关系矩阵
  Z = NULL,           # MLM的Z矩阵
  CV = NULL,          # 协变量矩阵
  buspred = FALSE,    # 是否进行预测
  cutOff = 0.05,      # 显著性阈值
  file.output = TRUE, # 是否输出文件
  h2 = NULL,          # 遗传力（模拟）
  lmpred = FALSE,     # 线性模型预测选项
  model = "MLM",      # 分析模型
  Multi_iter = TRUE,  # 多步迭代
  NQTN = NULL,        # QTN数量（模拟）
  PCA.total = 0,      # PCA数量
  pv.cut = 0.2,       # 标记排除阈值
  QTN.position = NULL # QTN位置（模拟）
)
```

### 关键参数说明

#### 1. 数据输入参数
- **`Y`**: 表型数据，必须包含Taxa列和性状列
- **`G`**: HapMap格式基因型数据
- **`GD`**: 数值型基因型数据（0,1,2编码）
- **`GM`**: SNP信息（染色体、位置等）
- **`KI`**: 亲缘关系矩阵，用于混合线性模型

#### 2. 分析控制参数
- **`model`**: 关联分析模型
  - `"GLM"`: 广义线性模型
  - `"MLM"`: 混合线性模型
  - `"CMLM"`: 压缩混合线性模型
  - `"FarmCPU"`: FarmCPU模型
  - `"BLINK"`: BLINK模型
- **`PCA.total`**: PCA主成分数量，用于群体结构校正
- **`cutOff`**: 显著性阈值，影响曼哈顿图阈值线

#### 3. 基因组选择参数
- **`buspred`**: 是否在GWAS后进行预测
- **`lmpred`**: 预测方法选择
  - `FALSE`: 使用GAGBLUP（GWAS Assisted GBLUP）
  - `TRUE`: 使用MAS（标记辅助选择）
- **`pv.cut`**: 排除标记的比例阈值（默认0.2）

#### 4. 模拟参数
- **`h2`**: 遗传力，用于表型模拟
- **`NQTN`**: QTN数量，用于表型模拟
- **`QTN.position`**: QTN位置，用于表型模拟

### 函数内部逻辑

#### 1. 初始化阶段
```r
# 版本信息
GAPIT.Version=GAPIT.0000()

# 模型处理
model_store=append(model[!model%in%c("gBLUP","cBLUP","sBLUP")],
                   model[model%in%c("gBLUP","cBLUP","sBLUP")])
```

#### 2. 模型选择逻辑
```r
if(model=="GLM") {
  # GLM模型处理
} else if(model=="MLM") {
  # MLM模型处理
} else if(model=="CMLM") {
  # CMLM模型处理
} else if(model=="FarmCPU") {
  # FarmCPU模型处理
} else if(model=="BLINK") {
  # BLINK模型处理
}
```

#### 3. 文件输出控制
```r
if(file.output) {
  # 生成PDF图和CSV文件
  GAPIT.Manhattan(...)
  GAPIT.QQ(...)
  utils::write.table(...)
}
```

## 函数 API 速查表（每函数：签名 → 返回）

> 用途：让 AI / 新手无需 `source()` 整个 `gapit_functions.txt` 再 grep，即可快速定位函数签名与返回字段。函数按功能分组；用户直接调用或需关心返回结构的关键函数标注返回字段，内部辅助函数仅列签名。详细逻辑仍以 `code/R/` 子函数源码为准（优先用「函数名 + 片段」定位，不依赖行号）。

### 1. 主函数
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT` | `Y, G, GD, GM, KI, Z, CV, buspred, cutOff, file.output, h2, lmpred, model, Multi_iter, NQTN, PCA.total, pv.cut, QTN.position, ...` | `$GWAS, $Pred, $h2, $PCA, $Compression, $kinship, $Power` |

### 2. 数据输入与转换
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.HapMap` | `G, SNP.effect, SNP.impute, heading, Create.indicator, Major.allele.zero` | `$GD, $GM, $GT` |
| `GAPIT.HMP2Num` | `nLines, fileHMP, fileNum, bit, SNP.effect, SNP.impute, ...` | 数值型 GD/GM 文件 |
| `GAPIT.HMP.Amplification` | `x` | 扩增后的 HapMap |
| `GAPIT.Numericalization` | `x, bit, effect, impute, Create.indicator, Major.allele.zero, byRow` | 数值基因型矩阵 |
| `GAPIT.Genotype` | `G, GD, GM, KI, kinship.algorithm, SNP.effect, SNP.impute, PCA.total, ...` | `$GD, $GM, $KI, $PC` |
| `GAPIT.Fragment` | `file.path, file.from, file.to, file.total, file.G, ...` | 大文件分块 |
| `GAPIT.FilterByTaxa` | `taxa, Data` | 按 Taxa 过滤后的数据 |
| `GAPIT.RemoveDuplicate` | `Y` | 去重后的表型 |
| `GAPIT.Imputation` | `x, GI, impute, byRow` | 填充缺失后的矩阵 |
| `GAPIT.replaceNaN` | `LL` | 替换 NaN 后的矩阵 |
| `GAPIT.Create.Indicator` | `xs, SNP.impute` | 指示矩阵 |

### 3. 数据质控
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.QC` / `GAPIT.QC2` | `Y, KI, GT, CV, Z, GK` | `$Y, $KI, $GT, $CV` |
| `GAPIT.MAF` | `MAF, P, E, trait, threshold.output, plot.style` | MAF 统计与图 |
| `GAPIT.Remove.outliers` | `x, na.rm, pro, size` | 去除离群值后数据 |
| `GAPIT.Licols` | `X, tol` | 共线性列 |

### 4. 亲缘矩阵
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.kinship.VanRaden` | `snps, hasInbred` | K 矩阵（二倍体假设） |
| `GAPIT.kinship.Zhang` | `snps, hasInbred` | K 矩阵 |
| `GAPIT.kinship.loiselle` | `snps, method, use` | K 矩阵 |
| `GAPIT.kinship.separation` | `PCs, EV, nPCs` | 分离后的亲缘矩阵 |
| `GAPIT.Compress` | `KI, kinship.cluster, kinship.group, GN` | 压缩后的 K |
| `GAPIT.ZmatrixCompress` | `Z, GAU` | 压缩 Z |
| `GAPIT.ZmatrixFormation` | `Z, Y` | Z 矩阵 |

### 5. 主成分 / 协变量
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.PCA` | `X, taxa, PC.number, file.output, PCA.total, PCA.col, ...` | `$PCs, $EVs` |
| `GAPIT.CVMergePC` | `X, Y` | 按 Taxa 合并协变量与主成分 |
| `GAPIT.Phenotype.PCA.View` | `PC, myY` | 表型-PCA 可视化 |

### 6. GWAS 核心（内部，供诊断定位）
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.DP`（数据预处理） | `G, GD, GM, KI, Z, CV, CV.Extragenetic, GP, GK, ...` | `$GD, $GM, $CV, $Y, ...` |
| `GAPIT.IC`（InitialCall） | `DP` | `$PC, $GM, $GD, $KI, $CV, ...` |
| `GAPIT.SS`（SumStats） | `DP, IC, buspred, lmpred` | `$GWAS, $Pred, $BWS, $h2` |
| `GAPIT.ID`（输出报告） | `DP, IC, SS, RS, cutOff, DPP, ...` | 输出文件与报告 |
| `GAPIT.Main`（MLM 主流程） | `Y, G, GD, GM, KI, Z, CV, SNP.P3D, ...` | `$GWAS, $Pred, $h2` |
| `GAPIT.Log`（MLM log） | `Y, KI, Z, CV, SNP.P3D, group.from, group.to, ...` | `$GWAS, $Pred` |
| `GAPIT.Bus`（FarmCPU） | `Y, CV, Z, GT, KI, GK, GD, GM, DP, WS, alpha, ...` | `$GWAS` |
| `GAPIT.Blink`（BLINK） | `Y, CV, Z, GT, KI, GK, GD, GM, ...` | `$GWAS` |
| `GAPIT.mlmm` / `GAPIT.mlmm_cof`（MLMM） | `...` | `$GWAS` |
| `GAPIT.SUPER.FastMLM` / `GAPIT.Bread`（SUPER） | `...` | `$GWAS` |
| `GAPIT.RandomModel` | `GWAS, GWAS.sig, Y, CV, X, cutOff, ...` | 随机模型结果 |
| `GAPIT.EMMAxP3D` / `GAPIT.emma.REMLE` / `GAPIT.emma` / `GAPIT.emmreml` | `...` | EMMA 求解 |
| `GAPIT.BIPH`（二分类表型） | `x, h2, r` | 二分类表型 |
| `GAPIT.Perform.BH.FDR.Multiple.Correction.Procedure` | `PWI, FDR.Rate, FDR.Procedure` | FDR 校正 P |

### 7. 基因组选择
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.GS` | `KW, KO, KWO, GAU, UW` | 预测值 |
| `GAPIT.SUPER.GS` | `Y, GD, GM, KI, Z, CV, GK, ...` | `$Pred` |
| `GAPIT.Validation` | `Y, G, GD, GM, PCA.total, KI, CV, nfold, acc.type, model` | `$Accuracy` |
| `GAPIT.PagainstP` | `container, Y, testY, model_store, ...` | 预测对比 |
| `GAPIT.Interactive.GS` | `model_store, Y, type, testY` | 交互 GS |
| `GAPIT.GS.Visualization` | `gsBLUP, BINS, name.of.trait` | GS 图 |
| `GAPIT.cross_validation.compare` | `GD, Y, nrep, tc` | 交叉验证对比 |

### 8. 模拟与功效评估
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.Phenotype.Simulation` | `GD, GM, h2, NQTN, QTNDist, effectunit, category, r, CV, cveff, ...` | `$Y, $QTN.position, $effect（真实加性效应）, $u, $e` |
| `GAPIT.Power` | `WS, GM, seqQTN, GWAS, maxOut, alpha, MaxBP` | `$FDR, $Power, $Power.Alpha, $alpha` |
| `GAPIT.FDR.TypeI` | `WS, GM, seqQTN, GWAS, maxOut, MaxBP` | `$FDR, $Power, $TypeI` |
| `GAPIT.Power.compare` | `G, GD, GM, PCA.total, KI, CV, nrep, h2, NQTN, maxOut, model, ...` | Power 对比 |
| `GAPIT.Power.compare.plink` | `myG, myGD, myGM, myKI, myY, myCV, rel, h2, NQTN` | Power 对比 |
| `GAPIT.PCA2Power` | `myGD, myGM, method, myPCA, rep, h2, NQTN, seed` | PCA-Power |

### 9. 可视化
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.Manhattan` | `GI.MP, GD, name.of.trait, plot.type, cutOff, seqQTN, ...` | 曼哈顿图 |
| `GAPIT.QQ` | `P.values, plot.type, name.of.trait, DPP, plot.style` | QQ 图 |
| `GAPIT.Multiple.Manhattan` / `GAPIT.Multiple.QQ` | `...` | 多模型图 |
| `GAPIT.Circle.Manhattan.Plot` | `Pmap, col, bin.size, ...` | 环形曼哈顿图 |
| `GAPIT.Interactive.Manhattan` | `GWAS, MAF.threshold, cutOff, DPP, ...` | 交互图 |
| `GAPIT.Genotype.View` | `GI, X, chr, cut.dis, n.select, ...` | 基因型可视化 |
| `GAPIT.Phenotype.View` | `myY, traitname, memo` | 表型可视化 |
| `GAPIT.ROC` | `t, se, Vp, trait, plot.style` | ROC 图 |

### 10. 工具 / 其他
| 函数 | 签名 | 返回 |
|---|---|---|
| `GAPIT.0000` | 无 | 版本信息 |
| `GAPIT.Memory` / `GAPIT.Memory.Object` | `...` | 内存统计 |
| `GAPIT.Timmer` | `Timmer, Infor` | 计时 |
| `GAPIT.Report` | `name.of.trait, GWAS, pred, tvalue, stderr, Vp, ...` | GWAS 报告 |
| `GAPIT.Table` | `final.table, name.of.trait, SNP.FDR` | 结果表 |
| `GAPIT.Specify` | `GI, GP, bin.size, inclosure.size, MaxBP` | 区间定位 |
| `GAPIT.Block` / `GAPIT.Fragment` / `GAPIT.LD.decay` | `...` | LD / 区块 |
| `GAPIT.AUC` | `beta, alpha` | AUC |
| `GAPIT.Cor.matrix` | `a, b` | 相关矩阵 |
| `GAPIT.Compression.Visualization` | `Compression, name.of.trait, file.output` | 压缩可视化 |
| `GAPIT.Phenotype.afterGWAS` | `GWAS, GD, G, GM, Y, model, cutOff, ...` | 后处理 |
| `GAPIT.Pruning` | `values, DPP` | LD 剪枝 |

## 常见问题定位索引（按函数名）

> 遵循「行号定位改函数名 + 片段」原则，以下用函数名定位排查入口。

### 1. 内存不足错误
- 亲缘矩阵计算：`GAPIT.kinship.VanRaden` / `GAPIT.kinship.Zhang`
- 大矩阵运算与统计量：`GAPIT.SS`、`GAPIT.emma.REMLE`、`GAPIT.Main`

### 2. 收敛问题
- REML/方差组分估计：`GAPIT.emma.REMLE`、`GAPIT.Log`
- 模型稳定性：`GAPIT.mlmm`、`GAPIT.mlmm_cof`

### 3. 文件输出问题
- 输出与报告生成：`GAPIT.Report`、`GAPIT.ID`
- 输出开关控制：`GAPIT.Main` 中的 `file.output` 门控

### 4. 参数验证错误
- 入口参数检查：`GAPIT` 主函数开头
- 数据预处理校验：`GAPIT.DP`

## 错误处理机制

### 1. 参数验证
```r
# 检查必要参数
if(is.null(Y)) stop("Phenotype data (Y) is required!")
if(is.null(GD) & is.null(G)) stop("Genotype data (GD or G) is required!")
```

### 2. 数据质量检查
```r
# 检查缺失值
if(any(is.na(Y[, -1]))) warning("Phenotype data contains missing values!")

# 检查基因型数据格式
if(!is.numeric(as.matrix(GD[, -1]))) stop("GD must be numeric genotype data!")
```

### 3. 计算错误处理
```r
tryCatch({
  # 尝试计算
  result <- some_computation()
}, error = function(e) {
  # 错误处理
  cat("Computation error:", e$message, "\n")
  return(NULL)
})
```

## 关键算法逻辑

### 1. BLINK算法核心
```r
# BLINK核心迭代逻辑
for(iteration in 1:max_iterations) {
  # 步骤1: 使用当前固定效应进行关联分析
  GWAS_result <- association_analysis(fixed_effects)
  
  # 步骤2: 选择显著标记作为新的固定效应
  significant_markers <- select_significant(GWAS_result, threshold)
  
  # 步骤3: 更新固定效应
  fixed_effects <- update_fixed_effects(significant_markers)
  
  # 步骤4: 检查收敛
  if(converged(fixed_effects)) break
}
```

### 2. GAGBLUP算法
```r
# GAGBLUP核心步骤
gagblup_algorithm <- function() {
  # 步骤1: 进行GWAS分析
  gwas_result <- run_gwas()
  
  # 步骤2: 根据GWAS结果筛选标记
  selected_markers <- filter_markers(gwas_result, pv.cut = 0.2)
  
  # 步骤3: 使用筛选后的标记构建亲缘关系矩阵
  kinship_matrix <- calculate_kinship(selected_markers)
  
  # 步骤4: 运行GBLUP模型
  gebv <- run_gblup(kinship_matrix)
  
  return(gebv)
}
```

## 调试和诊断指南

### 1. 常见错误诊断

| 错误信息 | 可能原因 | 解决方案 |
|----------|----------|----------|
| "object 'X' not found" | 变量名错误或数据未加载 | 检查变量名和数据加载步骤 |
| "cannot allocate vector of size X" | 内存不足 | 增加内存限制或减少数据量 |
| "subscript out of bounds" | 数据维度不匹配 | 检查数据维度和索引 |
| "convergence failed" | 模型参数不当 | 调整模型参数或简化模型 |

### 2. 性能优化建议

1. **内存管理**:
   ```r
   # 增加内存限制
   memory.limit(size = 16000)
   
   # 清理不需要的对象
   rm(list = ls())
   gc()
   ```

2. **并行计算**:
   ```r
   # 使用多核CPU
   library(parallel)
   cl <- makeCluster(detectCores() - 1)
   ```

3. **分批处理**:
   ```r
   # 分批处理大数据
   batch_size <- 1000
   for(i in seq(1, nrow(data), batch_size)) {
     batch <- data[i:min(i+batch_size-1, nrow(data)), ]
     process_batch(batch)
   }
   ```

## 版本兼容性说明

### 1. 函数命名约定
- 主函数：`` `GAPIT` ``
- 子函数：`GAPIT.XXXX()`（XXXX为功能描述）

### 2. 参数变化历史
- **GAPIT 3.x**: 引入`Multi_iter`参数
- **GAPIT 4.x**: 引入`buspred`和`lmpred`参数
- **GAPIT 5.x**: 优化内存管理和并行计算

### 3. 向后兼容性
- 旧版本参数在新版本中通常保持兼容
- 新增参数有默认值，不影响旧代码运行
- 重大变化会在版本说明中明确标注

## 使用示例

### 1. 基本GWAS分析
```r
skill_dir <- "path/to/gapit-expert-v1.0-beta.1"
source(file.path(skill_dir, "data/gapit-resources/code/gapit_functions.txt"))

# 运行BLINK模型
myGAPIT <- GAPIT(
  Y = myY,
  GD = myGD,
  GM = myGM,
  PCA.total = 3,
  model = "BLINK",
  file.output = TRUE
)
```

### 2. 基因组选择分析
```r
# 运行GAGBLUP分析
myGAPIT_GS <- GAPIT(
  Y = myY[, c(1, 2)],  # 仅参考群体表型
  GD = myGD,           # 全部基因型数据
  GM = myGM,
  PCA.total = 3,
  model = "BLINK",
  buspred = TRUE,
  lmpred = c(FALSE),   # 使用GAGBLUP
  file.output = TRUE
)
```

### 3. 表型模拟和验证
```r
# 模拟表型数据
mysimulation <- GAPIT.Phenotype.Simulation(
  h2 = 0.25,
  NQTN = 5,
  GD = myGD,
  GM = myGM
)

# 使用模拟数据进行GWAS
myGAPIT_sim <- GAPIT(
  Y = mysimulation$Y,
  GD = myGD,
  GM = myGM,
  PCA.total = 3,
  model = "BLINK",
  file.output = TRUE
)
```

## 关键返回结构与命名说明（2026-10 反馈汇总新增）

### 1. `Pred` 返回结构（GS 预测提取）
- `buspred=TRUE` 时 `GAPIT()` 返回的 `$Pred` 数据框，常见列：
  - `Taxa`：个体 ID（首列）。
  - `RefInf`：`1` = 参考群体（有表型，用于训练）；`2` = 预测群体（表型被掩盖，等待预测）。
  - `Prediction`：对观测表型的预测值。
  - `gBreedingValue`：估计育种值（与真实育种值比对时用它）。
- 提取预测值时动态识别列名（`gBreedingValue` / `Prediction` / `BLUP`），禁止硬编码列号。

### 2. Manhattan 图 `(Kansas)` / `(NYC)` 后缀
- GAPIT 输出的曼哈顿图文件名可能带 `(Kansas)` 或 `(NYC)`：
  - `(Kansas)`：逐步回归剔除后的"零星信号"版本。
  - `(NYC)`：传统连续信号的版本。
- 两者是同一分析的不同呈现口径，不是两个模型；新手常误以为是两种方法，解读时按需选用。

### 3. "CV" 与主成分/协变量函数区分
- GAPIT 中**没有** `GAPIT.CV` 函数；旧教程里的 `GAPIT.CV(...)` 是命名混淆（误把 CV 当 cross-validation）。
- "CV" 在 GAPIT 命名里指 **Covariates（协变量）**：
  - 计算主成分 → `GAPIT.PCA`。
  - 已有协变量要并入主成分 → `GAPIT.CVMergePC(CV, PC)`（按样本 ID 合并，`GAPIT.IC.R` 内部即如此调用）。
- 交叉验证没有内置接口，统一"手动分折 + 循环 `GAPIT()` + 提取 `Pred`"。

## 总结

本文档提供了GAPIT核心函数的摘要信息，包括：

1. **主函数签名和参数说明**：详细解释了`GAPIT()`函数的各个参数
2. **核心子函数功能**：描述了关键子函数的作用和位置
3. **常见问题索引**：提供了常见错误的相关代码位置
4. **算法逻辑说明**：解释了BLINK和GAGBLUP等核心算法
5. **调试和诊断指南**：提供了错误诊断和性能优化建议

通过本文档，智能体可以：
- 理解GAPIT的内部实现逻辑
- 快速定位常见问题的代码位置
- 解释函数参数的作用和影响
- 提供更准确的问题诊断和建议

**最后更新**: 2026-06-17  
**数据来源**: `gapit_functions.txt`（21,125行，762KB）  
**维护者**: GAPIT开发团队
