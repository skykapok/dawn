#!/bin/bash

rm -rf assets
mkdir assets
cp -rv ../../src assets
cp -rv ../../res/package assets

ndk-build
ant debug

adb uninstall com.poags.dawn
adb install bin/dawn-debug.apk
