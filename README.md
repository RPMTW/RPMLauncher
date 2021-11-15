# RPMLauncher

![RWL_Dev_Version](https://img.shields.io/badge/dynamic/json?label=RPMLauncher%20Latest%20Version&query=dev.latest_version_full&url=https%3A%2F%2Fraw.githubusercontent.com%2FRPMTW%2FRPMTW-website-data%2Fmain%2Fdata%2FRPMLauncher%2Fupdate.json)
![RWL_Visits_Count](https://img.shields.io/badge/dynamic/json?label=Visits%20Count&query=value&url=https%3A%2F%2Fapi.countapi.xyz%2Fhit%2Fgithub.rpmlauncher%2Fvisits)
[![Build](https://github.com/RPMTW/RPMLauncher/actions/workflows/Build.yml/badge.svg)](https://github.com/RPMTW/RPMLauncher/actions/workflows/Build.yml)
[![codecov](https://codecov.io/gh/RPMTW/RPMLauncher/branch/main/graph/badge.svg?token=5J25PUERID)](https://codecov.io/gh/RPMTW/RPMLauncher)

#### 🌐 README Languages
- English (Current Language)
- [繁體中文](https://github.com/RPMTW/RPMLauncher/blob/develop/assets/README/zh_tw.md)
- [简体中文](https://github.com/RPMTW/RPMLauncher/blob/develop/assets/README/zh_cn.md)

## Introduction

 A better Minecraft Launcher that supports multiple platforms and many functionalities for you to explore!

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
[Windows 10/11 Installer](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Windows10_11.zip)  
[Windows 7/8 Portable](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Windows7.zip)
### Linux
[Linux Portable](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Linux.zip)   
[Linux AppImage](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-Linux.Appimage)   
#### Arch Linux
[Arch Linux AUR (Git)](https://aur.archlinux.org/packages/rpmlauncher-git/)  
[Arch Linux AUR (Bin)](https://aur.archlinux.org/packages/rpmlauncher-bin/)  
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
### MacOS
[MacOS Installer (.dmg)](https://github.com/RPMTW/RPMLauncher/releases/latest/download/RPMLauncher-MacOS-Installer.dmg)  

Note: The RPMLauncher auto-update function is not supported for MacOS at this time.

[View version changes from the official website](https://www.rpmtw.ga/RWL/Version)

## Code Coverage
![Code Coverage](https://codecov.io/gh/RPMTW/RPMLauncher/branch/develop/graphs/sunburst.svg)
## Thanks
- SiongSng (菘菘#8663)
- sunny.ayyl#2932
- 3X0DUS - ChAoS#6969
- KyleUltimate
- 嗡嗡#5428 (RPMLauncher Logo Design)
