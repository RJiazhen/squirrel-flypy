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

### 5) 文档与规划

- `README.md`
- `PROJECT_STRUCTURE.md`
- `docs/flypy-optional-features-deferred.md`
