# M2 子计划：内置小鹤音形配置文件（最小接入）

本文件是 `M2` 的独立子计划，用于指导后续实现与验收。本阶段只做“把配置文件打进安装包并随部署编译”，不做方案规则细化。

## 目标

- 打包产物中的 `Squirrel.app/Contents/SharedSupport` 内置你提供的小鹤音形配置文件（原样接入）。
- 安装后 `scripts/postinstall` 触发的 `Squirrel --build` 能正常完成部署编译（不因缺失文件或路径错误失败）。
- 不在本阶段追求默认方案切换、候选体验、反查细节等行为调优（这些另开需求）。

## 现状基线（仓库内已确认）

- `Makefile` 通过 `plum-data` 生成 `plum/output/*`，再 `cp` 到 `data/plum/`。
- `package/add_data_files` 会扫描 `data/plum/*` 并把每个文件写入 `Squirrel.xcodeproj/project.pbxproj` 的 “Copy Shared Support Files” 资源拷贝阶段（路径固定为 `data/plum/<file>`）。
- `scripts/postinstall` 会在 `Contents/SharedSupport` 下执行 `Squirrel --build` 进行部署编译。

## 实施路线（高层）

### A. 配置文件落点与版本策略

- 约定“内置小鹤配置”的仓库落点（建议仍落在 `data/plum/`，以复用现有 Xcode 资源拷贝链路）。
- 约定你提供配置文件的交付形态（目录树 / zip / git submodule），以及更新方式（替换文件 + 重新生成工程引用）。

### B. 构建链路接入

- 在 `make data` / `make release` 路径上，确保小鹤配置文件在 `xcodebuild` 之前已出现在 `data/plum/`。
- 若不走 `plum` 生成，则需要新增一个明确的拷贝步骤（例如 `copy-flypy-data`）并由 `data` 目标依赖它。

### C. Xcode 资源引用一致性

- 在新增/替换 `data/plum/*` 文件后，运行 `bash package/add_data_files`，确保 `project.pbxproj` 中出现对应 `PBXFileReference` 与 `Copy Shared Support Files` 条目。
- 对“删除文件”的情况定义处理策略（避免工程引用残留）。

### D. 安装与部署验证

- 验证安装后的 `SharedSupport` 目录包含小鹤相关 `*.yaml` / `*.txt` / `opencc` 等资源（以你提供的包为准）。
- 验证 `Squirrel --build` 能完成（日志/退出码），并能在输入法菜单中看到对应 schema（最低要求：方案存在且可切换；默认方案是否切换由后续需求决定）。

## 验收清单（M2 Done 的定义）

- [ ] 产物内 `SharedSupport` 含你提供的小鹤音形配置文件（与交付清单一致）。
- [ ] `package/add_data_files` 后工程文件无缺失引用（能成功 `xcodebuild`）。
- [ ] `postinstall` 路径下 `Squirrel --build` 成功。
- [ ] 明确记录：本阶段不做哪些事（默认方案、按键、候选、反查等），避免范围蔓延。

## 风险与注意事项

- `data/plum` 同时承载 plum 预设输出与小鹤配置时，需要避免 `make clean` 误删用户尚未入库的临时文件；建议把小鹤配置放到受控子目录或单独拷贝目标，但仍需满足 `add_data_files` 的路径假设。
- 若小鹤包体依赖额外资源（例如 opencc 配置、二进制模型、外挂词典），需要一并纳入内置与部署验证范围。

## 关联文档

- 仓库结构基线：`PROJECT_STRUCTURE.md`
