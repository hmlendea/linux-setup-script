#!/bin/bash
export DOTNET_ROOT=/usr/share/dotnet
export DOTNET_VERSION=$("${DOTNET_ROOT}/dotnet" --version)
export MSBuildSDKsPath="${DOTNET_ROOT}/sdk/${DOTNET_VERSION}/Sdks"
export PATH="${PATH}:${DOTNET_ROOT}"
