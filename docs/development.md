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

### 本地一键打包（新流程，生成可安装的 pkg）

在仓库根目录执行，需已安装 **Xcode**（默认使用 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`，可通过环境变量覆盖）且 **cmake** 在 `PATH` 中。

```sh
# 完整流程：拉取/校验依赖（action-install.sh）+ Release 构建 + 打 pkg
bash scripts/prod-package.sh
```

若本地依赖与 plum 资源已就绪、只想跳过安装脚本以加快重复打包，可使用：

```sh
bash scripts/prod-package.sh --no-install
```

与 CI 发布类似的「带版本号的 pkg 等」请使用 `bash scripts/prod-package.sh --archive`（对应 `make archive`）。

成功后在 **`package/SquirrelFlypy.pkg`**（`--archive` 时另有 `SquirrelFlypy-*.pkg` 等）得到安装包；在 Finder 中双击用「安装器」安装即可。同一流程连续打包得到的 `.pkg` 文件哈希未必逐字节相同（包元数据会变化），属正常现象。

## 项目树（目录/文件职责）

```text
squirrel-flypy/
├─ sources/                         # macOS 输入法前端主代码
│  ├─ Main.swift                    # 应用入口与启动参数分流（安装/重载/主程序）
│  ├─ SquirrelApplicationDelegate.swift  # 生命周期、部署、通知、快速加词入口
│  ├─ SquirrelInputController.swift # 输入事件处理、上屏、与 Rime 会话交互
│  ├─ QuickAddWordPanel.swift       # 快速加词弹窗 UI 与交互逻辑
│  └─ FlypydzSingleCharCodeIndex.swift  # flypydz 单字编码内存索引
├─ librime/                         # 输入引擎源码与 API（子模块）
├─ flypy-rime-config/               # flypy 参考配置（上游/只读参考）
├─ data/                            # 打包进应用的配置与资源（含 plum/opencc）
├─ scripts/                         # 开发、部署、安装辅助脚本
│  ├─ dev-rebuild.sh                # 本地快速重编译与重载
│  ├─ prod-package.sh               # 本地一键生产打包（依赖检查 + make package/archive）
│  ├─ postinstall                   # pkg 安装后注册与配置复制
│  └─ stage-flypy-for-data-plum.sh  # flypy 配置 staging 与裁剪同步
├─ package/                         # 安装包构建脚本与产物目录
├─ resources/                       # Info.plist、entitlements 等应用资源
├─ Assets.xcassets/                 # App 图标与资源集
├─ Squirrel.xcodeproj/              # Xcode 工程与 target 配置
├─ docs/                            # 项目文档（开发、配置、路线图）
│  ├─ development.md                # 开发总文档（本文件）
│  ├─ config-files.md               # 配置文件说明
│  └─ roadmap.md                    # 功能路线图与阶段规划
├─ .github/workflows/               # CI/CD 工作流（commit/release/nightly）
├─ .cursor/                         # Cursor 规则、技能、工作流文档
├─ Makefile                         # 常用构建入口
├─ action-build.sh                  # CI 本地一致的构建入口
├─ action-install.sh                # 安装流程入口（CI/本地复用）
└─ README.md                        # 项目说明与使用/开发入口
```

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
