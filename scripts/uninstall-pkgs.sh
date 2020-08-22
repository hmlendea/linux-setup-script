#!/bin/bash
UNUSED_DEPS=$(pacman -Qdtq)
UNUSED_DEPS_COUNT=$(echo ${UNUSED_DEPS} | wc -w)

if [ ${UNUSED_DEPS_COUNT} -gt 0 ]; then
    echo "Uninstalling unused dependencies ($UNUSED_DEPS_COUNT):"
    echo ${UNUSED_DEPS}

    pacman --noconfirm -Rns ${UNUSED_DEPS}
fi
