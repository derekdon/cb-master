#!/bin/bash
set -e
set -x
set -m

if [ -z "$CLUSTER_PORT" ]; then
    echo "CLUSTER_PORT environment variable not set"
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

SERVICE_IPS=$(getent hosts $DOCKERCLOUD_SERVICE_HOSTNAME | awk '{print $1}' | sort -V)
echo "SERVICE_IPS are $SERVICE_IPS"

FIRST_IP=$(getent hosts $DOCKERCLOUD_SERVICE_HOSTNAME | awk '{print $1}' | sort -V | head -1)
echo "FIRST_IP in the service is $FIRST_IP"

LAST_IP=$(getent hosts $DOCKERCLOUD_SERVICE_HOSTNAME | awk '{print $1}' | sort -V | tail -1)
echo "LAST_IP in the service is $LAST_IP"

THIS_IP=$(getent hosts $DOCKERCLOUD_CONTAINER_HOSTNAME | awk '{print $1}' | sort -V | head -1)
echo "THIS_IP $THIS_IP"

if [ -z "$CLUSTER" ]; then
    CLUSTER_IP=$FIRST_IP
else
    CLUSTER_IP=$(getent hosts $CLUSTER | awk '{print $1}' | sort -V | head -1)
fi

echo "CLUSTER_IP $CLUSTER_IP"

CLUSTER_IP_PORT="${CLUSTER_IP}:$CLUSTER_PORT"
echo "CLUSTER_IP_PORT $CLUSTER_IP_PORT"

THIS_IP_PORT="${THIS_IP}:$CLUSTER_PORT"
echo "THIS_IP_PORT $THIS_IP_PORT"

if [ $THIS_IP == $FIRST_IP ]; then
    
    if [ -z "$CLUSTER_RAM_SIZE" ]; then
        echo "CLUSTER_RAM_SIZE environment variable not set"
        exit 4
    fi
    
    if [ -z "$CLUSTER_INDEX_RAM_SIZE" ]; then
        echo "CLUSTER_INDEX_RAM_SIZE environment variable not set"
        exit 5
    fi
    
    if [ -z "$BUCKET" ]; then
        echo "BUCKET environment variable not set"
        exit 6
    fi
    
    if [ -z "$BUCKET_TYPE" ]; then
        echo "BUCKET_TYPE environment variable not set"
        exit 7
    fi
        
    if [ -z "$BUCKET_PORT" ]; then
        echo "BUCKET_PORT environment variable not set"
        exit 8
    fi 
        
    if [ -z "$BUCKET_RAM_SIZE" ]; then
        echo "BUCKET_RAM_SIZE environment variable not set"
        exit 9
    fi 
    
    if [ -z "$BUCKET_REPLICA" ]; then
        echo "BUCKET_REPLICA environment variable not set"
        exit 10
    fi
    
    set +e
    
    echo "pinging cluster ($CLUSTER_IP_PORT)"
    curl --silent --show-error $CLUSTER_IP_PORT > /dev/null
    
    while [ $? -ne 0 ];  do
        sleep 1
        echo 'retrying'
        curl --silent --show-error $CLUSTER_IP_PORT > /dev/null
    done
    
    set -e
                  
    echo "initializing cluster ($CLUSTER_IP_PORT)"
    
    couchbase-cli cluster-init \
        -c $CLUSTER_IP_PORT \
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
        -c $CLUSTER_IP_PORT \
        -u $USERNAME \
        -p $PASSWORD \
        --bucket=$BUCKET \
        --bucket-type=$BUCKET_TYPE \
        --bucket-port=$BUCKET_PORT \
        --bucket-ramsize=$BUCKET_RAM_SIZE \
        --bucket-replica=$BUCKET_REPLICA
    
    echo "created ($BUCKET) bucket"
    
else
    
    set +e
        
    echo "pinging cluster ($CLUSTER_IP_PORT)"
    curl --silent --show-error $CLUSTER_IP_PORT > /dev/null
    
    while [ $? -ne 0 ];  do
        sleep 1
        echo 'retrying'
        curl --silent --show-error $CLUSTER_IP_PORT > /dev/null
    done
    
    set -e
    
    echo "joining cluster ($CLUSTER_IP_PORT) from ($THIS_IP_PORT)"
    
    couchbase-cli server-add -c $CLUSTER_IP_PORT -u $USERNAME -p $PASSWORD --server-add=$THIS_IP_PORT --server-add-username=$USERNAME --server-add-password=$PASSWORD --services=data,index,query
    
    echo "cluster joined"
    
    echo "auto rebalance ($AUTO_REBALANCE), note only the last container can trigger a rebalance"
    
    if [ $THIS_IP == $LAST_IP ] && [ "$AUTO_REBALANCE" = "true" ]; then
        
        echo "attempting a rebalance in 60 seconds"
        
        sleep 60
        
        couchbase-cli rebalance -c $CLUSTER_IP_PORT -u $USERNAME -p $PASSWORD
        
        echo "rebalancing in progress, please wait"
        
    else
        echo "not rebalancing"
    fi

fi

fg 1