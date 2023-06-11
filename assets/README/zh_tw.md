# RPMLauncher

[![RWL_Dev_Version](https://img.shields.io/badge/dynamic/json?label=RPMLauncher%20最新開發版本&query=dev.latest_version_full&url=https://raw.githubusercontent.com/RPMTW/RPMTW-website-data/main/data/RPMLauncher/update.json)](../../../../releases)
![RWL_Visits_Count](https://hits.sh/github.com/RPMTW/RPMLauncher.svg?label=瀏覽次數)
[![Build](../../../../actions/workflows/build.yml/badge.svg)](../../../../actions/workflows/Build.yml)
[![codecov](https://codecov.io/gh/RPMTW/RPMLauncher/branch/main/graph/badge.svg?token=5J25PUERID)](https://codecov.io/gh/RPMTW/RPMLauncher)

#### 🌐 說明檔案語言  
- [English](../../README.md)
- 繁體中文（目前語言）
- [简体中文](../README/zh_cn.md)

## 介紹

更好的 Minecraft 啟動器支援多個平台，有許多功能等您來探索！

[巴哈姆特文章](https://forum.gamer.com.tw/C.php?bsn=18673&snA=193012&tnum=1)

## 特色功能
- 自動安裝並設定對應版本的 Java
- 自動安裝模組載入器
- 從 CurseForge、Modrinth 下載模組與模組包
- 即時監控遊戲記錄檔
- 支援多國語言
- 提供暗色模式與淺色模式的主題選項
- 快速導入地圖、資源包和光影
- 支援模組包安裝
- 支援 Microsoft、Xbox 和 Mojang 帳戶登入
- 自動安裝前置模組
- 同時開啟多個遊戲
- 還有許多實用與方便的功能

![圖片](https://user-images.githubusercontent.com/48402225/139568860-b3dd0246-5e7c-4442-bb3c-7fa5cbc7bafc.png)


## 翻譯
協助我們將 RPMLauncher 翻譯成其他語言 [點我前往翻譯網站](https://crowdin.com/project/siong-sngs-fantasy-world)

## 編譯
編譯 RPMLauncher 需要 Flutter SDK 與 Dart SDK
[下載 SDK](https://flutter.dev/docs/get-started/install)
[Flutter 官方教學](https://flutter.dev/desktop)
```
flutter pub get
flutter config --enable-<您的作業系統>-desktop
flutter build <您的作業系統>
```

## 安裝
### Windows
[Windows 安裝程式版](../../../../releases/latest/download/RPMLauncher-Windows-Installer.exe)
[Windows 免安裝版](../../../../releases/latest/download/RPMLauncher-Windows.zip)
### Linux
[Linux 免安裝版](../../../../releases/latest/download/RPMLauncher-Linux.zip)
[Linux AppImage](../../../../releases/latest/download/RPMLauncher-Linux.Appimage)
#### Arch Linux
[Arch Linux AUR（原始碼）](https://aur.archlinux.org/packages/rpmlauncher-git)
[Arch Linux AUR（二進位檔案）](https://aur.archlinux.org/packages/rpmlauncher-bin)
```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/rpmlauncher-bin.git
cd rpmlauncher-bin
makepkg -si
```
#### Snap
[Snap Store](https://snapcraft.io/rpmlauncher)
```bash
### 穩定版本

sudo snap install rpmlauncher --channel=stable

### 開發版本

sudo snap install rpmlauncher --channel=beta
```
### macOS
[macOS 安裝程式（.dmg）](../../../../releases/latest/download/RPMLauncher-MacOS-Installer.dmg)

備註：RPMLauncher 自動更新功能暫不支援 macOS

[從官方網站檢視版本變更](https://www.rpmtw.com/RWL/Version)

## 程式碼測試覆蓋率
![Code Coverage](https://codecov.io/gh/RPMTW/RPMLauncher/branch/develop/graphs/sunburst.svg)
## 銘謝
- 菘菘#8663
- sunny.ayyl#2932
- 3X0DUS - ChAoS#6969
- KyleUltimate
- 嗡嗡#5428（RPMLauncher Logo 設計）