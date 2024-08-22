#!/usr/bin/env bash

LEMMY_HELP=lemmy-help

if test -f ./lemmy-help; then
    LEMMY_HELP=./lemmy-help
fi

DOC_FILE=doc/bracket-repeat.txt

INPUT_FILES=(
    lua/bracket-repeat/init.lua
)

$LEMMY_HELP --prefix-func --prefix-alias --prefix-class --prefix-type ${INPUT_FILES[*]} > $DOC_FILE
