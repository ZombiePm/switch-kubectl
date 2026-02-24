#!/bin/bash
set -e

cd "$(dirname "$0")"

VERSION="1.0.0"
DEB_NAME="switch-kubectl_${VERSION}_all.deb"
WIN_NAME="switch-kubectl_${VERSION}_windows.zip"
DIST="dist"

rm -rf "$DIST"
mkdir -p "$DIST"

echo "=== Building .deb ==="
# Copy latest scripts
cp switch.sh  packaging/deb/usr/local/bin/switch-kubectl
cp vswitch.sh packaging/deb/usr/local/bin/vswitch-kubectl
chmod 755 packaging/deb/usr/local/bin/*
dpkg-deb --build packaging/deb "$DIST/$DEB_NAME"
echo "  -> $DIST/$DEB_NAME"

echo "=== Building Windows zip ==="
# Copy latest scripts
cp switch.bat  packaging/win/switch.bat
cp vswitch.bat packaging/win/vswitch.bat
(cd packaging/win && zip -q "../../$DIST/$WIN_NAME" install.bat switch.bat vswitch.bat)
echo "  -> $DIST/$WIN_NAME"

echo ""
echo "Done. Artifacts in $DIST/"
ls -lh "$DIST/"
