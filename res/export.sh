#!/bin/bash
cd tool
rm -rf ../package
./simplepacker ../raw -o ../package -n dawn -np -v
