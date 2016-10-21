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
    
    if [ -z "$BUCKET" ]; then
        echo "BUCKET environment variable not set"
        exit 5
    fi
    
    if [ -z "$BUCKET_TYPE" ]; then
        echo "BUCKET_TYPE environment variable not set"
        exit 6
    fi
        
    if [ -z "$BUCKET_PORT" ]; then
        echo "BUCKET_PORT environment variable not set"
        exit 7
    fi 
        
    if [ -z "$BUCKET_RAM_SIZE" ]; then
        echo "BUCKET_RAM_SIZE environment variable not set"
        exit 8
    fi 
    
    if [ -z "$BUCKET_REPLICA" ]; then
        echo "BUCKET_REPLICA environment variable not set"
        exit 9
    fi
                  
    echo "initializing cluster ($CLUSTER)"
    couchbase-cli cluster-init \
        -c "$CLUSTER" \
        -u "$USERNAME" \
        -p "$PASSWORD" \
        "--cluster-init-ramsize=$RAM_SIZE"
    
    echo "cluster initialized"
    echo "creating bucket"
    
    couchbase-cli bucket-create \
        -c "$CLUSTER" \
        -u "$USERNAME" \
        -p "$PASSWORD" \
        "--bucket=$BUCKET --bucket-type=$BUCKET_TYPE --bucket-port=$BUCKET_PORT --bucket-ramsize=$BUCKET_RAM_SIZE --bucket-replica=$BUCKET_REPLICA"
    
    echo "created ($BUCKET) bucket"

}

exec "$@"