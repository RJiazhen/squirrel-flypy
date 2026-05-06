# 快速加词弹窗扩展开发分档说明

本文档用于记录 roadmap §4 的实现分档、验收要点与对应代码位置，便于后续维护与回归。

## 分档 1：弹窗布局与交互基线

- 目标
  - 弹窗改为顶部对齐布局与动态高度；
  - 词条输入升级为多行文本域（约 10 行）并支持占位；
  - 勾选项同一行、按钮顺序为「确定在左 / 取消在右」。
- 主要改动
  - `sources/QuickAddWordPanel.swift`
- 验收
  - 弹窗展示稳定，无双弹窗；
  - 词条多行输入、滚动与占位提示正常。

## 分档 2：固项写入与剪贴板造词

- 目标
  - 固项开关将词条写入 `flypy_top.txt` 或 `flypy_user.txt`；
  - 剪贴板造词开启时即时填充词条，关闭时恢复勾选前快照；
  - 剪贴板为空时不弹窗，直接清空词条与编码。
- 主要改动
  - `sources/SquirrelApplicationDelegate.swift`
  - `sources/QuickAddWordPanel.swift`
- 验收
  - 勾选固项后新增词条进入 `flypy_top.txt`；
  - 剪贴板流程符合预期，空剪贴板不阻塞。

## 分档 3：最近上屏默认词条 + 方向键长度调节

- 目标
  - 记录最近上屏文本，快速加词默认预填最近尾部词条；
  - 在弹窗内按 `↑/↓` 调整默认取词长度，并让当前输入控件失焦后生效。
- 主要改动
  - `sources/SquirrelInputController.swift`
  - `sources/SquirrelApplicationDelegate.swift`
  - `sources/QuickAddWordPanel.swift`
- 验收
  - 默认词条随最近上屏变化；
  - 焦点在词条或编码时，`↑/↓` 仍可调节长度而非仅移动光标。

## 分档 4：flypydz 自动编码补全

- 目标
  - 基于 `flypydz.dict.yaml` 构建内存单字索引；
  - 支持 1/2/3/4+ 字词自动编码规则：
    - 1 字：单字完整编码；
    - 2 字：各取前 2 位；
    - 3 字：第 1 字前 1 + 第 2 字前 1 + 第 3 字前 2；
    - 4 字及以上：第 1/2/3 字前 1 + 最后 1 字前 1。
- 主要改动
  - `sources/FlypydzSingleCharCodeIndex.swift`
  - `sources/SquirrelApplicationDelegate.swift`
  - `sources/QuickAddWordPanel.swift`
- 验收
  - 词条变化时可自动填充编码；
  - 手工覆盖编码后不被强制改写，清空编码可再次触发自动补全。

## 分档 5：安装脚本兜底（开发调试兼容）

- 目标
  - 当 `SharedSupport/flypy-rime-config` 不存在时，`postinstall` 可回退复制平铺配置文件，避免安装失败。
- 主要改动
  - `scripts/postinstall`
- 验收
  - Debug/开发安装路径下执行安装脚本不再因目录缺失失败。
