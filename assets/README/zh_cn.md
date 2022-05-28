# RPMLauncher

![RWL_Dev_Version](https://img.shields.io/badge/dynamic/json?label=RPMLauncher%20最新开发版本&query=dev.latest_version_full&url=https%3A%2F%2Fraw.githubusercontent.com%2FRPMTW%2FRPMTW-website-data%2Fmain%2Fdata%2FRPMLauncher%2Fupdate.json)
![RWL_Visits_Count](https://img.shields.io/badge/dynamic/json?label=浏览次数&query=value&url=https%3A%2F%2Fapi.countapi.xyz%2Fhit%2Fgithub.rpmlauncher%2Fvisits)
[![Build](https://github.com/RPMTW/RPMLauncher/actions/workflows/Build.yml/badge.svg)](https://github.com/RPMTW/RPMLauncher/actions/workflows/Build.yml)
[![codecov](https://codecov.io/gh/RPMTW/RPMLauncher/branch/main/graph/badge.svg?token=5J25PUERID)](https://codecov.io/gh/RPMTW/RPMLauncher)

#### 🌐 说明文件语言  
- [English](https://github.com/RPMTW/RPMLauncher/blob/develop/README.md)
- [繁体中文](https://github.com/RPMTW/RPMLauncher/blob/develop/assets/README/zh_tw.md)
- 简体中文 (当前语言)

## 介绍

更好的 Minecraft 启动器支援多个平台，有许多功能等您来探索！。

[巴哈姆特文章](https://forum.gamer.com.tw/C.php?bsn=18673&snA=193012&tnum=1)

## 特色功能
- 自动安装并设定对应版本的Java
- 自动安装 MOD 载入器
- 从CurseForge、Modrinth 下载 MOD 与整合包
- 即时监控游戏日志
- 支援多国语言
- 提供黑暗模式与浅色模式的主题选项
- 快速导入地图、资源包、光影包
- 支援模组包安装
- 支援微软/Xbox/Mojang账号登入
- 自动安装前置 MOD
- 同时开启多个游戏
- 还有许多实用与方便的功能

![图片](https://user-images.githubusercontent.com/48402225/139568860-b3dd0246-5e7c-4442-bb3c-7fa5cbc7bafc.png)


## 翻译
协助我们将 RPMLauncher 翻译成其他语言 [点我前往翻译网站](https://crowdin.com/project/siong-sngs-fantasy-world)

## 编译
编译 RPMLauncher 需要 Flutter SDK 与 Dart SDK  
[下载 SDK](https://flutter.dev/docs/get-started/install)  
[Flutter 官方教程](https://flutter.dev/desktop)
```
flutter pub get
flutter config --enable-<您的操作系统>-desktop
flutter build <您的操作系统>
```

## 安装
### Windows
[Windows 安装程序](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Windows-Installer.exe)  
[Windows 免安装版](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Windows.zip)   
### Linux
[Linux 免安装版](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Linux.zip)   
[Linux AppImage](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Linux.Appimage)   
#### Arch Linux
[Arch Linux AUR (源代码)](https://aur.archlinux.org/packages/rpmlauncher-git/)  
[Arch Linux AUR (二进制文件)](https://aur.archlinux.org/packages/rpmlauncher-bin/)  
```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/rpmlauncher-bin.git
cd rpmlauncher-bin
makepkg -si
```
#### Snap
[Snap Store](https://snapcraft.io/rpmlauncher)  
```bash
### 稳定版本

sudo snap install rpmlauncher --channel=stable

### 开发版本

sudo snap install rpmlauncher --channel=beta
```
### MacOS
[MacOS 安装程序 (.dmg)](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-MacOS-Installer.dmg)  

备注：RPMLauncher 自动更新功能暂不支援 MacOS

[从官方网站检视版本变更](https://www.rpmtw.com/RWL/Version)

## 源代码测试覆盖率
![Code Coverage](https://codecov.io/gh/RPMTW/RPMLauncher/branch/develop/graphs/sunburst.svg)
## 铭谢
- 菘菘#8663
- sunny.ayyl#2932
- 3X0DUS - ChAoS#6969
- KyleUltimate
- 嗡嗡#5428 (RPMLauncher Logo 设计)