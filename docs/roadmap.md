# Squirrel Flypy 路线图

> 本文档是项目级路线图，记录已暂缓、待补回、分阶段实现的功能项与实现约束。

## 读取约定（面向人和 agent）

- 按章节编号执行，默认优先级从小到大。
- “暂缓”表示仅记录方案与依赖，不进入当前开发迭代。
- 关联构建流程的条目，必须先在 staging 验证再进入打包链路。

`flypy-rime-config/` 目录中的文件作为**官方/上游配置的只读参考**，在构建时不要直接修改。  
当前 M2 精简接入在**构建 staging** 中做了与下列功能相关的裁剪，以便后续按顺序补回。

## 1. 计算器 translator

- **作用**：通过 Lua 翻译器处理表达式输入（常见为以 `=` 开头的计算或相关模式）。
- **与上游参考的关联**（在 `flypy-rime-config/rime/flypy.schema.yaml` 中仍可查到）：
  - `engine/translators` 中的 `lua_translator@calculator_translator`
  - `recognizer/patterns/expression` 中与 `=` 相关的匹配（例如 `^(=.*|ok[a-z']*)$` 中的 `=.`* 部分是否单独服务于计算器，需与 ok 引导模式一并核对）
- **补回时需检查**：
  - `rime.lua` 中是否提供 `calculator_translator` 实现（当前参考树中仅有日期/时间 Lua 示例）。
  - `librime-lua` 是否已随发行构建启用（否则 Lua translator 不会生效）。

## 2. 二重简码（flypydz）

- **作用**：独立 `flypydz` 方案及相关反查/辅助能力。
- **参考文件**（仍保留在 `flypy-rime-config/rime/`，仅**不打入** `data/plum` 产物）：
  - `flypydz.schema.yaml`
  - `flypydz.dict.yaml`
- **主方案中的关联点**（参考 `flypy.schema.yaml`）：
  - `schema/dependencies` 中的 `flypydz`
  - `reverse_lookup` 段（`dictionary: flypydz`）
  - `engine/translators` 中的 `reverse_lookup_translator`
- **补回顺序建议**：先恢复 `flypydz` 词库与方案文件进入打包目录，再恢复 `flypy.schema.yaml` 中上述段落，最后验证反查与方案依赖编译无误。

## 3. 全码字字典（custom_phraseQMZ / 主码表）

- **作用**：全码相关词条或短语表（在参考 `flypy.schema.yaml` 中表现为 `table_translator@custom_phraseQMZ`；通常还需对应的 `custom_phraseQMZ:` 配置段及词库文件）。
- **当前状态说明**：
  - 参考 `flypy.schema.yaml` 中仍列出 `table_translator@custom_phraseQMZ`，但未附带同名 `custom_phraseQMZ:` 段落；构建 staging 会**移除该 translator 行**以免部署阶段引用缺失配置。
  - 若上游完整包中包含主码表 `flypy.dict.yaml`（或等价命名），本仓库参考树中可能已省略；`rime/build/` 下的 `flypy.*.bin` 为预编译产物，可作为对照，但长期仍应以可重建的 `*.dict.yaml` 源文件为准。
- **补回时需准备**：
  - `custom_phraseQMZ` 的 YAML 配置段与对应用户词典/码表文件；
  - 或恢复完整 `flypy.dict.yaml`（及依赖的 opencc/encoder 等配置），并确认 `translator/dictionary: flypy` 能由源码完整重建。

## 4. 快速加词弹窗扩展功能（M3 后续）

- **范围说明**：以下能力在 M3 基础“快速加词”可用后，再按优先级逐步补齐。
- **扩展项清单**：
  - “将新添加词条固项”勾选框。
  - “剪贴板造词”勾选框。
  - 自动读取最近输入的两个字作为“词条”默认值。
  - 自动查询首选字词字典中对应编码作为“编码”默认值。
  - 支持上下方向键调整自动读取字的长度。
- **实现备注**：
  - 默认写入目标与“固项”逻辑需要与 `flypy_user.txt` / `flypy_top.txt` 写入策略联动定义。
  - “最近输入字串”与“默认编码推断”依赖运行时输入上下文与词典查询接口，建议单独评估可用 API 与失败兜底。

### 4.1 快速加词：自动编码与主码表首选对齐（待办）

- **问题**：单字存在多条编码时，当前快速加词自动填码取自 `flypydz.dict.yaml`（解析顺序上**最靠前**的一条），与主输入方案里由权重/排序决定的**常用首选**可能不一致。
- **方向**：改为从主词典编译产物（例如部署目录下的 `flypy.table.bin`，或经 librime / 与引擎一致的查询路径）取得与打字时一致的单字首选码；与 §3 主码表、`flypy.dict.yaml` 是否在参考树中可得联动评估。
- **实现约束**：需评估 macOS 客户端内复用 librime 查表、或独立读取 `*.table.bin` 的可行性与维护成本；无可用主表或查询失败时的兜底（例如仍回退 `flypydz.dict.yaml`）。

### 4.2 快速加词：支持词条中的换行（待办）

- **问题**：快速加词面板/提交流程当前不支持在词条中输入或保留换行（例如多行短语、从剪贴板粘贴的段落）。
- **方向**：在 `QuickAddWordPanel` 词条编辑区与 `appendQuickAddWord` 等持久化路径上明确是否允许 `\n`/`\r`；若允许，需与 Rime 用户词表行格式（通常为单行 `词条<TAB>编码`）及校验逻辑一并调整。

### 4.3 快速加词：自动编码跳过无 flypydz 码的字符（待办）

- **问题**：生成自动编码时，若词条中含符号、拉丁字母等 `flypydz` 无条目的字符，当前 `quickAddAutoCode(forWord:)` 会因「任一字缺码」整段返回 `nil`，编码框被清空，无法为剩余有码字符生成部分编码。
- **方向**：对无码字符跳过（仅拼接有码字符的编码规则），或明确提示「仅对汉字等可编码部分生成」；多行/混合内容时需与 §4.2 行为一致。

## 构建行为说明（避免误改参考目录）

- 构建时使用 `scripts/stage-flypy-for-data-plum.sh`：从 `flypy-rime-config/rime` 复制到 `build/flypy-staged`，在 staging 中应用补丁后再同步到 `data/plum/`。
- 功能开发全部结束后，可按计划删除 `flypy-rime-config/`；删除前请确认上述可选能力已在正式配置与文档中有替代说明或已合并入主配置树。

## 5. 码表优化：暂缓实现项

- **来源文档**：`docs/code-table-optimization-notes.md`
- **状态**：先记录实现方案，暂不进入本轮开发

### 5.1 分号引导的快捷符号（暂缓项）

- `;I`：撤销上次输入
- `;F`：重复上屏词条
- 说明：建议与现有分号引导快符机制统一设计输入上下文读取与动作执行时机，再落地实现。

### 5.2 直通车（暂缓）

- 参考：[flypy 帮助 - 常用组合直通](https://flypy.cc/help/#/pc?id=%e4%b8%89%e3%80%81%e5%b8%b8%e7%94%a8%e7%bb%84%e5%90%88%e7%9b%b4%e9%80%9a)
- 说明：先补齐现有基础符号与快符能力，再评估直通车功能的引导键位与冲突策略。

### 5.3 便捷输入（暂缓）

- 参考：[flypy 帮助 - 便捷输入](https://flypy.cc/help/#/pc?id=%e5%85%ad%e3%80%81%e4%be%bf%e6%8d%b7%e8%be%93%e5%85%a5)
- 说明：待现有码表优化项稳定后，单独评估与现有词库和用户习惯兼容性。

### 5.4 智能标点（暂缓）

- 参考：[flypy 帮助 - 智能标点](https://flypy.cc/help/#/pc?id=%e4%b8%83%e3%80%81%e6%99%ba%e8%83%bd%e6%a0%87%e7%82%b9)
- 说明：该能力对输入状态机和标点规则影响较大，建议独立成一个阶段实现并配套回归测试。
