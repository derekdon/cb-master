#!/bin/bash
set -e

[[ "$1" == "cluster-join" ]] && {

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
    
    if [ -z "$CLUSTER_JOINER" ]; then
        echo "CLUSTER_JOINER environment variable not set"
        exit 5
    fi
    
    echo "($CLUSTER_JOINER) is joining and rebalancing cluster ($CLUSTER)"
    couchbase-cli rebalance \
        -c "$CLUSTER" \
        -u "$USERNAME" \
        -p "$PASSWORD" \
        "--server-add=$CLUSTER_JOINER"
    
    echo "cluster $CLUSTER_JOINER joined and rebalancing"

}

exec "$@"