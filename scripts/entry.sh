#!/bin/bash
set -e
set -x
set -m

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

/entrypoint.sh couchbase-server &

sleep 15

[[ "$1" == "cluster-init" ]] && {    
    
    if [ -z "$CLUSTER_RAM_SIZE" ]; then
        echo "CLUSTER_RAM_SIZE environment variable not set"
        exit 4
    fi
    
    if [ -z "$CLUSTER_INDEX_RAM_SIZE" ]; then
        echo "CLUSTER_INDEX_RAM_SIZE environment variable not set"
        exit 5
    fi
    
    if [ -z "$CLUSTER_PORT" ]; then
        echo "CLUSTER_PORT environment variable not set"
        exit 6
    fi
    
    if [ -z "$BUCKET" ]; then
        echo "BUCKET environment variable not set"
        exit 7
    fi
    
    if [ -z "$BUCKET_TYPE" ]; then
        echo "BUCKET_TYPE environment variable not set"
        exit 8
    fi
        
    if [ -z "$BUCKET_PORT" ]; then
        echo "BUCKET_PORT environment variable not set"
        exit 9
    fi 
        
    if [ -z "$BUCKET_RAM_SIZE" ]; then
        echo "BUCKET_RAM_SIZE environment variable not set"
        exit 10
    fi 
    
    if [ -z "$BUCKET_REPLICA" ]; then
        echo "BUCKET_REPLICA environment variable not set"
        exit 11
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
        -c $CLUSTER \
        -u $USERNAME \
        -p $PASSWORD \
        --cluster-username=$USERNAME \
        --cluster-password=$PASSWORD \
        --cluster-port=$CLUSTER_PORT \
        --services=data,index,query \
        --cluster-ramsize=$CLUSTER_RAM_SIZE \
        --cluster-index-ramsize=$CLUSTER_INDEX_RAM_SIZE 
    
    echo "cluster initialized"
    
    sleep 15
    
    echo "creating bucket"
    
    couchbase-cli bucket-create \
        -c $CLUSTER \
        -u $USERNAME \
        -p $PASSWORD \
        --bucket=$BUCKET \
        --bucket-type=$BUCKET_TYPE \
        --bucket-port=$BUCKET_PORT \
        --bucket-ramsize=$BUCKET_RAM_SIZE \
        --bucket-replica=$BUCKET_REPLICA
    
    echo "created ($BUCKET) bucket"

}

[[ "$1" == "cluster-join" ]] && {

    if [ -z "$SERVER_ADD_HOST" ]; then
        echo "SERVER_ADD_HOST environment variable not set"
        exit 4
    fi
    
    sleep 15

    echo "joining cluster ($CLUSTER) from ($SERVER_ADD_HOST)"
    
    echo "auto rebalance ($AUTO_REBALANCE)"
        
    if [ "$AUTO_REBALANCE" = "true" ]; then
        couchbase-cli rebalance -c $CLUSTER -u $USERNAME -p $PASSWORD --server-add=$SERVER_ADD_HOST --server-add-username=$USERNAME --server-add-password=$PASSWORD --services=data,index,query
    else
        couchbase-cli server-add -c $CLUSTER -u $USERNAME -p $PASSWORD --server-add=$SERVER_ADD_HOST --server-add-username=$USERNAME --server-add-password=$PASSWORD --services=data,index,query
    fi;
    
    echo "cluster joined"
    
}

fg 1