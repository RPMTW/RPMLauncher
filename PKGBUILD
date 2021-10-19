pkgname=RPMLauncher
pkgver=1.0.0.625
pkgrel=1
pkgdesc="A multi-functional Minecraft Launcher power by the RPMTW Team, made with Flutter and Dart"
license=('GPL')
depends=('git')
makedepends=('ninja' 'cmake' 'clang' 'dart' 'flutter-git')
arch=('x86_64')
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
changelog=
source=('RPMLauncher::git+https://github.com/RPMTW/RPMLauncher')
md5sums=('SKIP')
pkgver(){
  cd "$pkgname"
  git describe --tags | sed 's/^v//;s/-/+/g'
}
prepare(){
  cd "$pkgname"
  flutter config --enable-linux-desktop
}
build(){
  cd "$srcdir/$pkgname/"
  build_id=`git describe --tags --abbrev=0 | sed 's/[0-9]*\.[0-9]*\.[0-9]*\.//'`
  version_id=`git describe --tags --abbrev=0 | sed "s/\.$build_id//"`
  flutter build linux --dart-define="build_id=$build_id" --dart-define="version_type=debug" --dart-define="version=$version_id"
  chmod +x "$srcdir/$pkgname/build/linux/x64/release/bundle/RPMLauncher"
  cd "$srcdir/$pkgname/scripts/Updater"
  dart pub get
  dart compile exe bin/main.dart --output "$srcdir/$pkgname/build/linux/x64/release/bundle/updater"
  chmod +x "$srcdir/$pkgname/build/linux/x64/release/bundle/updater"
}
package() {
  cd "$srcdir/$pkgname/build/linux/x64/release/bundle/"
  mkdir -p "$pkgdir/usr/share/applications"
  mkdir "$pkgdir/usr/bin"
  mkdir -p "$pkgdir/opt/RPMLauncher"
  cp -r * "$pkgdir/opt/RPMLauncher"
  cd "$pkgdir/usr/share/applications"
  echo "[Desktop Entry]
Categories=Game;ArcadeGame;
Comment=Edit
Encoding=UTF-8
Exec="/opt/RPMLauncher/RPMLauncher"
Icon="/opt/RPMLauncher/data/flutter_assets/images/Logo.png"
Name=RPMLauncher
Path=/opt/RPMLauncher
StartupNotify=false
Terminal=true
Type=Application
Version=$PKGVER" >> RPMLauncher.desktop
}
