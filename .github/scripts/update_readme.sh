#!/usr/bin/env bash

DOC_FILE=doc/{PLUGIN_NAME}.txt

extract_usage() {
    local found_setup=false
    local found_usage=false

    while IFS= read -r line; do
        if [[ $line == *"M.setup"* ]]; then
            found_setup=true
        fi

        if [ "$found_setup" = false ] ; then
            continue
        fi

        if [[ $line == ">lua"* ]]; then
            found_usage=true
            continue
        fi

        if [ "$found_usage" = false ] ; then
            continue
        fi

        if [[ $line == "<"* ]]; then
            break
        fi

        # Remove first indentation
        echo "${line:8}"
    done < $DOC_FILE
}

usage=$(extract_usage)

put_usage() {
    local found_usage=false
    local found_block=false
    local usage_placed=false

    while IFS= read -r line; do
        if [[ "$usage_placed" = false && $line == "## Usage"* ]]; then
            found_usage=true
        fi

        if [[ "$found_usage" = true && $line == '```lua'* ]]; then
            found_block=true
            continue
        fi

        # Don't echo lines in block
        if [ "$found_block" = true ] ; then
            if [[ $line == '```'* ]]; then
                found_block=false
                usage_placed=true
                found_usage=false
                echo '```lua'
                echo "$usage"
                echo '```'
            fi
            continue
        fi

        echo $line
    done < README.md
}

new_readme=$(put_usage)
echo "$new_readme" > README.md
