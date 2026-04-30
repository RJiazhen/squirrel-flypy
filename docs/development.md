# 开发文档（AI 参考版）

> 本文档用于开发阶段快速上手与定位关键目录，内容由 AI 生成，仅供参考。

## 说明

1. 本项目添加了大量 AI 相关工作流文档，详见 `.cursor` 目录。
2. 本文档也是使用 AI 生成的，仅供参考，请结合实际代码与构建日志判断。

## 如何快速启动

### 环境准备

- macOS 13.0+
- Xcode 14.0+
- `cmake`

### 获取代码

```sh
git clone --recursive <your-repo-url>
cd squirrel-flypy
```

### 常用开发启动方式

```sh
# 常规编译
make

# 快速本地开发重编译（不走打包流程）
bash scripts/dev-rebuild.sh
```

如需查看更多参数：

```sh
bash scripts/dev-rebuild.sh --help
```

## 项目结构

- `sources`：macOS 前端主代码（输入控制、候选交互、上屏行为）
- `librime`：输入引擎与依赖（核心逻辑、部署流程、插件能力）
- `data`：内置配置资源
- `plum`：方案与词库安装管理
- `scripts`：开发与部署辅助脚本
- `package`：打包相关资源与流程文件
- `resources`、`Assets.xcassets`、`Rime.icon`：应用资源
- `Squirrel.xcodeproj`：Xcode 工程
- `.cursor`：AI 工作流与协作相关文档、规则、技能

## 相关功能开发时涉及到的目录和文件

### 1) 输入行为与前端交互

- `sources/SquirrelInputController.swift`
- `sources/SquirrelApplicationDelegate.swift`

### 2) 引擎能力与部署逻辑

- `librime/src/rime`
- `librime/src/rime/lever/deployment_tasks.cc`
- `librime/src/rime_api.h`
- `librime/src/rime_api_impl.h`

### 3) 配置与方案接入

- `data`
- `flypy-rime-config`
- `plum`
- `docs/config-files.md`

### 4) 本地调试、构建、打包

- `scripts/dev-rebuild.sh`
- `Makefile`
- `action-build.sh`
- `action-install.sh`
- `package`
- `.github/workflows/release-ci.yml`

### 5) 文档与规划

- `README.md`
- `PROJECT_STRUCTURE.md`
- `docs/roadmap.md`

## 发布须知

当前发布目标是让用户可以从 GitHub Release 下载 `pkg` 安装包，暂不启用应用内自动更新。

### 正式版本发布

- 推送任意 Git tag 会触发 `.github/workflows/release-ci.yml`。
- 发布流程会运行 `./action-build.sh archive`，最终生成 `package/SquirrelFlypy-*.pkg`。
- tag 发布会创建 draft GitHub Release，并上传 `package/SquirrelFlypy-*.pkg`。
- `action-changelog.sh` 会根据当前 tag 与上一个 tag 之间的 Git 历史生成 release body。

### Nightly 版本发布

- 推送到 `master` 分支会触发 nightly 发布。
- nightly 发布仅在仓库为 `RJiazhen/squirrel-flypy` 且 ref 为 `refs/heads/master` 时执行。
- nightly release 使用固定 tag `latest`，并标记为 prerelease。
- nightly 产物同样上传 `package/SquirrelFlypy-*.pkg`，标题为 `Squirrel Flypy nightly build`。
- 如果只想验证分支构建，不要把代码直接推到 `master`；普通分支会走 `commit-ci`，只上传 Actions artifact。

### 产物命名与包名

- `Makefile` 中的 `PACKAGE` 为 `package/SquirrelFlypy.pkg`。
- `package/make_archive` 会把安装包复制为 `SquirrelFlypy-${app_version}.pkg`。
- GitHub Release 与 nightly release 都匹配 `package/SquirrelFlypy-*.pkg`。

### 自动更新与 appcast

- `resources/Info.plist` 中的 `SUFeedURL` 是 Sparkle 自动更新 feed 地址，不是普通下载地址。
- 当前 `SUEnableAutomaticChecks` 设为 `false`，表示暂不自动检查更新。
- `package/make_archive` 仍保留 appcast 生成逻辑，但如果本地或 CI 没有 Sparkle `ed25519` 私钥，`sign_update` 会失败并跳过 appcast，不阻塞 `pkg` 发布。
- 暂不需要配置 `SPARKLE_PRIVATE_KEY`。后续如果要启用应用内自动更新，再补充 Sparkle 私钥管理、`appcast.xml` 上传和 `SUPublicEDKey` 更新流程。
