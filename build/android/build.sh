#!/bin/bash

set -e

rm -rf assets
mkdir -p assets/files
cp -rv ../../src assets/files
cp -rv ../../res/package assets/files
cp -rv ../../engine/ejoy2d assets/files

ndk-build
ant debug

adb uninstall com.poags.dawn
adb install bin/dawn-debug.apk
