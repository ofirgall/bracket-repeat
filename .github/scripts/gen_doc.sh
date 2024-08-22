#!/usr/bin/env bash

LEMMY_HELP=lemmy-help

if test -f ./lemmy-help; then
    LEMMY_HELP=./lemmy-help
fi

DOC_FILE=doc/{PLUGIN_NAME}.txt

INPUT_FILES=(
    lua/{PLUGIN_NAME}/init.lua
)

$LEMMY_HELP --prefix-func --prefix-alias --prefix-class --prefix-type ${INPUT_FILES[*]} > $DOC_FILE
