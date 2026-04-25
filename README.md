# Squirrel Flypy

[![Release](https://img.shields.io/badge/Release-更新记录-blue)](./CHANGELOG.md)
[![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![Based on Squirrel](https://img.shields.io/badge/Base-Squirrel-green)](https://github.com/rime/squirrel)

本项目基于 [Rime Squirrel](https://github.com/rime/squirrel) 二次开发，目标是在 macOS 端尽可能还原小鹤音形输入法体验。
同时，本项目兼容原版 Squirrel 的配置方法，已有配置和习惯可继续沿用。

## 已实现功能

- [x] 小鹤音形方向的核心方案整合与适配
- [x] 输入「ojc」进行快速加词功能

## 待实现功能

- [ ] 码表优化；
- [ ] 快速加词弹窗扩展；
- [ ] 词库管理；
- [ ] 计算器 translator 能力；
- [ ] 二重简码 `flypydz` 方案及反查能力补回；
- [ ] 全码字切换；

## 安装输入法

本项目适用于 macOS 13.0+。

初次安装后，如部分应用中无法正常输入，请注销系统并重新登录。

## 使用输入法

从输入法菜单中选择对应图标后即可开始输入。
可通过快捷键 `Ctrl+\`` 或 `F4` 呼出方案菜单并切换输入方式。

## 定制输入法

定制方法可参考 Rime 在线文档：[https://rime.im/docs/](https://rime.im/docs/)。

常用操作：

- 在系统输入法菜单中打开在线文档
- 编辑用户配置后执行“重新部署”使修改生效

## 开发参考

详见 [docs/development.md](/docs/development.md)。

## 原 Squirrel 项目致谢

输入方案设计：

  * 【朙月拼音】系列

    感谢 CC-CEDICT、Android 拼音、新酷音、opencc 等开源项目

程序设计：

  * 佛振
  * Linghua Zhang
  * Chongyu Zhu
  * 雪齋
  * faberii
  * Chun-wei Kuo
  * Junlu Cheng
  * Jak Wings
  * xiehuc

美术：

  * 图标设计 佛振、梁海、雨过之后
  * 配色方案 Aben、Chongyu Zhu、skoj、Superoutman、佛振、梁海

本项目引用了以下开源软件：

  * Boost C++ Libraries (Boost Software License)
  * capnproto (MIT License)
  * darts-clone (New BSD License)
  * google-glog (New BSD License)
  * Google Test (New BSD License)
  * LevelDB (New BSD License)
  * librime (New BSD License)
  * OpenCC / 开放中文转换 (Apache License 2.0)
  * plum / 东风破 (GNU Lesser General Public License 3.0)
  * Sparkle (MIT License)
  * UTF8-CPP (Boost Software License)
  * yaml-cpp (MIT License)

感谢王公子捐赠开发用机。
