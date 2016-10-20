#!/bin/bash
set -e

[[ "$1" == "cluster-init" ]] && {

    if [ -z "$CLUSTER" ]; then
        echo "CLUSTER environment variable not set"
        exit 1
    fi
    
    if [ -z "$USERNAME" ]; then
        echo "USERNAME environment variable not set"
        exit 2
    fi
    
    if [ -z "$PASSWORD" ]; then
        echo "PASSWORD environment variable not set"
        exit 3
    fi
    
    if [ -z "$RAM_SIZE" ]; then
        echo "RAM_SIZE environment variable not set"
        exit 4
    fi
    
    echo "initializing cluster ($CLUSTER)"
    couchbase-cli cluster-init \
        -c "$CLUSTER" \
        -u "$USERNAME" \
        -p "$PASSWORD" \
        "--cluster-init-ramsize=$RAM_SIZE"
    
    echo "cluster initialized"

}

exec "$@"