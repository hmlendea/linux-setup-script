#!/bin/bash
source "scripts/common/package-management.sh"

NVIDIA_DRIVER="nvidia-390xx"

install-pkg bumblebee
install-dep bbswitch
install-dep primus

install-pkg optiprime

install-pkg mesa
install-pkg xf86-video-intel

install-pkg ${NVIDIA_DRIVER}-dkms
install-pkg ${NVIDIA_DRIVER}-settings
install-dep lib32-${NVIDIA_DRIVER}-utils

install-dep lib32-virtualgl
