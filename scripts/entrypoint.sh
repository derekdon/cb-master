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
    
    set +e
    
    echo "pinging cluster ($CLUSTER)"
    curl --silent --show-error $CLUSTER > /dev/null
    
    while [ $? -ne 0 ];  do
        sleep 1
        echo 'retrying'
        curl --silent --show-error $CLUSTER > /dev/null
    done
    
    set -e
    echo "initializing cluster ($CLUSTER)"
    couchbase-cli cluster-init \
        -c "$CLUSTER" \
        -u "$USERNAME" \
        -p "$PASSWORD" \
        "--cluster-init-ramsize=$RAM_SIZE"
    
    echo "cluster initialized"

}

exec "$@"