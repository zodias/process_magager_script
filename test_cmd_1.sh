#!/usr/bin/env bash

CNT=0
MAX=600

#if [ ${1} ]

while [ 1 ]; do
    echo "${0} Working cnt: $((CNT++))"
    sleep 1
    if [ ${CNT} == ${MAX} ]; then
        echo "Done"
        exit 0
    fi
done
