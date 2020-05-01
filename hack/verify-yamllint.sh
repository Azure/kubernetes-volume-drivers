#!/bin/bash

if [[ -z "$(command -v yamllint)" ]]; then
  sudo apt update && sudo apt install yamllint -y
fi

LOG=/tmp/yamllint.log

for path in "flexvolume/smb/*.yaml" "flexvolume/blobfuse/*.yaml"
do
    echo "checking yamllint under path: $path ..."
    yamllint -f parsable $path | grep -v "line too long" > $LOG
    cat $LOG
    linecount=`cat $LOG | grep -v "line too long" | wc -l`
    if [ $linecount -gt 0 ]; then
        echo "yaml files under $path are not linted, failed with: "
        cat $LOG
        exit 1
    fi
done

echo "Congratulations! All Yaml files have been linted."
