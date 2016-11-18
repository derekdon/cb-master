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

FIRST_IP=$(getent hosts $DOCKERCLOUD_SERVICE_HOSTNAME | awk '{print $1}' | sort -n | head -1)
echo "FIRST_IP in the service is $FIRST_IP"

LAST_IP=$(getent hosts $DOCKERCLOUD_SERVICE_HOSTNAME | awk '{print $1}' | sort -n | tail -1)
echo "LAST_IP in the service is $LAST_IP"

THIS_IP=$(getent hosts $DOCKERCLOUD_CONTAINER_HOSTNAME | awk '{print $1}' | sort -n | head -1)
echo "THIS_IP $THIS_IP"

if [ -z "$CLUSTER" ]
then
   CLUSTER_IP=$FIRST_IP
else
   CLUSTER_IP=$(getent hosts $CLUSTER | awk '{print $1}' | sort -n | head -1)
fi

echo "CLUSTER_IP $CLUSTER_IP"

CLUSTER_IP_PORT="${CLUSTER_IP}:$CLUSTER_PORT"
echo "CLUSTER_IP_PORT $CLUSTER_IP_PORT"

sleep 15

if [ $THIS_IP == $FIRST_IP ]
then

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

  if [ -z "$SERVER_ADD_HOST" ]; then
      echo "SERVER_ADD_HOST environment variable not set"
      exit 4
  fi
  
  sleep 15

  echo "joining cluster ($CLUSTER_IP_PORT) from ($SERVER_ADD_HOST)"
  
  echo "auto rebalance ($AUTO_REBALANCE), note only the last container can trigger a rebalance"
      
  if [ $THIS_IP == $LAST_IP ] && [ "$AUTO_REBALANCE" = "true" ]; then
      couchbase-cli rebalance -c $CLUSTER_IP_PORT -u $USERNAME -p $PASSWORD --server-add=$SERVER_ADD_HOST --server-add-username=$USERNAME --server-add-password=$PASSWORD --services=data,index,query
  else
      couchbase-cli server-add -c $CLUSTER_IP_PORT -u $USERNAME -p $PASSWORD --server-add=$SERVER_ADD_HOST --server-add-username=$USERNAME --server-add-password=$PASSWORD --services=data,index,query
  fi;
  
  echo "cluster joined"

fi

fg 1