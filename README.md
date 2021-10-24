# RPMLauncher

![RWL_Dev_Version](https://img.shields.io/badge/dynamic/json?label=RWL%20%E6%9C%80%E6%96%B0%E9%96%8B%E7%99%BC%E7%89%88%E6%9C%AC&query=dev.latest_version_full&url=https%3A%2F%2Fraw.githubusercontent.com%2FRPMTW%2FRPMTW-website-data%2Fmain%2Fdata%2FRPMLauncher%2Fupdate.json)
![RWL_Dev_Version](https://img.shields.io/badge/dynamic/json?label=RWL%20Latest%20Version&query=dev.latest_version_full&url=https%3A%2F%2Fraw.githubusercontent.com%2FRPMTW%2FRPMTW-website-data%2Fmain%2Fdata%2FRPMLauncher%2Fupdate.json)
![RWL_Visits_Count](https://img.shields.io/badge/dynamic/json?label=Visits%20Count&query=value&url=https%3A%2F%2Fapi.countapi.xyz%2Fhit%2Fgithub.rpmlauncher%2Fvisits)
[![Build](https://github.com/RPMTW/RPMLauncher/actions/workflows/Build.yml/badge.svg)](https://github.com/RPMTW/RPMLauncher/actions/workflows/Build.yml)
[![codecov](https://codecov.io/gh/RPMTW/RPMLauncher/branch/main/graph/badge.svg?token=5J25PUERID)](https://codecov.io/gh/RPMTW/RPMLauncher)
## 介紹

這是一個使用 Flutter 框架與 Dart語言製成的 Minecraft啟動器，主要目的是要簡化安裝 Minecraft 的麻煩。

[巴哈姆特文章](https://forum.gamer.com.tw/C.php?bsn=18673&snA=193012&tnum=1)

## 特色功能
- 自動安裝並設定對應版本的Java
- 自動安裝模組載入器
- 從CurseForge、Modrinth下載模組與模組包
- 即時監控遊戲日誌
- 支援多國語言
- 提供黑暗模式與淺色模式的主題選項
- 快速導入地圖、資源包、光影
- 支援模組包安裝
- 支援微軟帳號與Mojang帳號登入
- 自動安裝前置模組
- 同時開啟多個遊戲
- 還有許多實用與方便的功能

## 翻譯
協助我們將 RPMLauncher 翻譯成其他語言 [點我前往翻譯網站](https://crowdin.com/project/siong-sngs-fantasy-world)

## Build
Build RPMLauncher 需要 Flutter SDK 與 Dart SDK  
[下載 SDK](https://flutter.dev/docs/get-started/install)  
[Flutter 官方教學](https://flutter.dev/desktop)
```
flutter pub get
flutter config --enable-<您的作業系統>-desktop
flutter build <您的作業系統>
```

## 安裝
### Windows
[Windows 10/11 Portable](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Windows10_11.zip)  
[Windows 7/8 Portable](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Windows7.zip)
### Linux
[Linux Portable](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Linux.zip)   

#### Arch Linux
[Arch Linux AUR (Git)](https://aur.archlinux.org/packages/rpmlauncher-git/)  
[Arch Linux AUR (Bin)](https://aur.archlinux.org/packages/rpmlauncher-bin/)  
```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
paru rpmlauncher bin
```
#### Snap
[Snap Store](https://snapcraft.io/rpmlauncher)  
```bash
sudo snap install rpmlauncher
```
### MacOS
[MacOS El Capitan (10.11) 以上版本](https://github.com/RPMTW/RPMLauncher/releases/latest/download/rpmlauncher.tar.bz2)  

備註：RPMLauncher 自動更新功能暫不支援 MacOS

[從官方網站檢視版本變更](https://www.rpmtw.ga/RWL/Version)
## 銘謝
### 主要開發者：菘菘#8663
#### 貢獻者: 3X0DUS - ChAoS#6969、sunny.ayyl#2932
