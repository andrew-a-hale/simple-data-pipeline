#!/bin/bash
pid=$(ss -tulpn | grep "$1" | grep -o "pid=[[:digit:]]*" | cut -d = -f2)

if [[ $(wc -w <<< $pid) -eq 0 ]]
then
    echo "No process found... use ss -tulpn to find the process"
    exit 1
fi

kill -9 $pid