#!/bin/bash

mkdir -p /cifs
wget -O /cifs/cifs https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/cifs
chmod a+x /cifs/cifs
