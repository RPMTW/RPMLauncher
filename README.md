# RPMLauncher

[![RWL_Dev_Version](https://img.shields.io/badge/dynamic/json?label=RPMLauncher%20Latest%20Version&query=dev.latest_version_full&url=https://raw.githubusercontent.com%2FRPMTW%2FRPMTW-website-data%2Fmain%2Fdata%2FRPMLauncher%2Fupdate.json)](../../releases)
![RWL_Visits_Count](https://hits.sh/github.com/RPMTW/RPMLauncher.svg?label=Visits)
[![Build](../../actions/workflows/build.yml/badge.svg)](../../actions/workflows/build.yml)
[![Codecov](https://codecov.io/gh/RPMTW/RPMLauncher/branch/develop/graph/badge.svg?token=5J25PUERID)](https://codecov.io/gh/RPMTW/RPMLauncher)

#### 🌐 README Languages
- English (Current Language)
- [繁體中文](assets/README/zh_tw.md)
- [简体中文](assets/README/zh_cn.md)

## Introduction

 A better Minecraft Launcher that supports cross-platform and many functionalities for you to explore!

## Featured Features
- Automatically installs and sets the corresponding version of Java
- Automatically install mod loaders
- Download mod and modpacks from CurseForge, Modrinth
- Real-time monitoring of game logs
- Multi-language support
- Theme options for dark and light modes
- Quickly import worlds, resourcepack, shaders
- Support for modpack installation
- Support Microsoft/Xbox/Mojang account login
- Automatic installation of front mod
- Open multiple games at the same time
- Many other useful and convenient features

![Image](https://user-images.githubusercontent.com/48402225/139568860-b3dd0246-5e7c-4442-bb3c-7fa5cbc7bafc.png)


## Translation
Help us to translate RPMLauncher into other languages [click me to go to translation](https://crowdin.com/project/siong-sngs-fantasy-world)

## Build
Build RPMLauncher requires Flutter SDK and Dart SDK  
[Download SDK](https://flutter.dev/docs/get-started/install)
[Official Flutter Tutorial](https://flutter.dev/desktop)
```
flutter pub get
flutter config --enable-<your-operating-system>-desktop
flutter build <your-operating-system>
```

## Install
### Windows
[Windows Installer](../../releases/latest/download/RPMLauncher-Windows-Installer.exe)
[Windows Portable](../../releases/latest/download/RPMLauncher-Windows.zip)
### Linux
[Linux Portable](../../releases/latest/download/RPMLauncher-Linux.zip)
[Linux AppImage](../../releases/latest/download/RPMLauncher-Linux.Appimage)
#### Arch Linux
[Arch Linux AUR (Git)](https://aur.archlinux.org/packages/rpmlauncher-git)
[Arch Linux AUR (Bin)](https://aur.archlinux.org/packages/rpmlauncher-bin)
```bash
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/rpmlauncher-bin.git
cd rpmlauncher-bin
makepkg -si
```
#### Snap
[Snap Store](https://snapcraft.io/rpmlauncher)
```bash
### Stable Version

sudo snap install rpmlauncher --channel=stable

### Development Version

sudo snap install rpmlauncher --channel=beta
````
### macOS
[macOS Installer (.dmg)](../../releases/latest/download/RPMLauncher-MacOS-Installer.dmg)

Note: The RPMLauncher auto-update function is not supported for macOS at this time.

[View version changes from the official website](https://www.rpmtw.com/RWL/Version)

## Code Coverage
![Code Coverage](https://codecov.io/gh/RPMTW/RPMLauncher/branch/develop/graphs/sunburst.svg)
## Thanks
- SiongSng (菘菘#8663)
- sunny.ayyl#2932
- 3X0DUS - ChAoS#6969
- KyleUltimate
- 嗡嗡#5428 (RPMLauncher Logo Design)
