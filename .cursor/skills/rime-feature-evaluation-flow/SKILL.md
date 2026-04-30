---
name: rime-feature-evaluation-flow
description: Evaluate how to implement new Rime/Flypy features with a config-first workflow. Use when assessing new feature feasibility, deciding between config-only changes vs code changes, checking upstream support, or choosing whether to modify this repo or upstream repositories.
---

# Rime Feature Evaluation Flow

## Core Rule (verbatim)

当需要评估新功能如何实现时，应当遵循尽可能使用已有的接口进行实现,需要先考虑程序本身是否提供了可配置项,如果能够通过配置项实现,就可以只修改 flypy-rime-config 目录中的文件来实现,如果不确定是否支持该配置项,应当优先阅读https://github.com/rime/home/wiki/CustomizationGuide 和https://rimeinn.github.io/rime/ ,如果没看到相关说明,还可以搜索https://github.com/rime/home/issues 中是否存在相关 issue,或者https://github.com/orgs/rime/discussions 中是否存在相关的讨论.而不要直接去阅读代码尝试实现。如果发现无法通过配置实现，则要评估是需要改当前项目即可实现，当时需要去改该项目依赖的上游 git 仓库。然后和我进行确认后再进行后续工作。

## Workflow

1. Prefer existing interfaces and config first.
2. Check whether the feature can be implemented via config in this project.
3. If config support is uncertain, read:
   - https://github.com/rime/home/wiki/CustomizationGuide
   - https://rimeinn.github.io/rime/
4. If still unclear, search GitHub with `gh` first:
   - `gh issue list --repo rime/home --search "<keyword>" --state all`
   - `gh issue list --repo rime/home --search "<keyword in:title,body>" --state all`
   - `gh search issues "<keyword> repo:rime/home"`
   - `gh search discussions "<keyword> org:rime"`
   - Only use web pages as fallback:
     - https://github.com/rime/home/issues
     - https://github.com/orgs/rime/discussions
5. Do not start by reading code to force an implementation.
6. If config cannot solve it, evaluate whether:
   - changes in current project are enough, or
   - upstream dependency repositories must be modified.
7. Before any subsequent implementation work, confirm the chosen path with the user.

## Scope Guardrails

- Config-only path: modify files under `flypy-rime-config` only.
- Code path is allowed only after config/documentation/community checks fail to provide a solution.
- Upstream change decisions must be explicitly reported and confirmed with the user first.
