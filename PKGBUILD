pkgname=RPMLauncher
pkgver=1.0.0.603
pkgrel=1
epoch=
pkgdesc="smth"
license=('GPL')
makedepends=('ninja' 'cmake' 'clang' 'dart')
arch=('x86_64')
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
changelog=
pkgver(){
  git describe --tags | sed 's/^v//;s/-/+/g'
}
prepare(){
  git pull
  package=flutter
if pacman -Qs $package > /dev/null ; then
  echo "Flutter is installed."
else
  git clone https://aur.archlinux.org/flutter.git
  cd flutter
  git pull
  makepkg -si --asdeps
  sudo gpasswd -a $USER flutterusers
  sudo chown -R :flutterusers /opt/flutter
  sudo chmod -R g+w /opt/flutter
  sudo chown -R $USER /opt/flutter
fi
  flutter config --enable-linux-desktop
}
build(){
  build_id=`git describe --tags --abbrev=0 | sed 's/[0-9]*\.[0-9]*\.[0-9]*\.//'`
  version_id=`git describe --tags --abbrev=0 | sed "s/\.$build_id//"`
  flutter build linux --dart-define="build_id=$build_id" --dart-define="version_type=debug" --dart-define="version=$version_id"
  chmod +x ../build/linux/x64/release/bundle/RPMLauncher
  cd "$srcdir/../scripts/Updater"
  dart pub get
  dart compile exe lib/main.dart --output "$srcdir/../build/linux/x64/release/bundle/updater"
}
check(){
  ls  
}
package() {
  cd ../build/linux/x64/release/bundle/
  mkdir "$pkgdir/usr"
  mkdir "$pkgdir/usr/share"
  mkdir "$pkgdir/usr/share/applications"
  mkdir "$pkgdir/usr/bin"
  mkdir "$pkgdir/opt"
  mkdir "$pkgdir/opt/RPMLauncher"
  cp -r * "$pkgdir/opt/RPMLauncher"
  cd "$pkgdir/usr/share/applications"
  echo "[Desktop Entry]
Categories=Game;ArcadeGame;
Comment=Edit
Encoding=UTF-8
Exec=/usr/bin/rpmlauncher
Icon="/opt/RPMLauncher/data/flutter_assets/images/Logo.png"
Name=RPMLauncher
Path=/opt/RPMLauncher
StartupNotify=false
Terminal=true
Type=Application
Version=$PKGVER" >> RPMLauncher.desktop
ln -s "/opt/RPMLauncher/RPMLauncher" "$pkgdir/usr/bin/rpmlauncher"
}
