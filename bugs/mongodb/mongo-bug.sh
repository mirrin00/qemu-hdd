#!/usr/bin/bash

#=====

MONGO_V="4.0"

#=====

DISK="/dev/sdb"

MOUNT_PATH="/mnt"
MONGO_PATH="${MOUNT_PATH}/slow-mongo"
MONGO_DATA_PATH="${MONGO_PATH}/data"

CONTAINER_PRIM="mongo-primary"
CONTAINER_SEC1="mongo-sec1"
CONTAINER_SEC2="mongo-sec2"

MONGO_NET="mongo-net"

#=====

DOCKER_IMAGE_ARG=""

if [[ $MONGO_V == "4.2" ]]; then
	DOCKER_IMAGE_ARG="--setParameter watchdogPeriodSeconds=60"
fi

#=====

RS_LOG="/tmp/mongo_rs.log"
WRITE_LOG="/tmp/mongo_write.log"

> "$RS_LOG"
> "$WRITE_LOG"

#=====

sudo mkdir -p ${MOUNT_PATH}
sudo mkdir -p ${MONGO_PATH}

mountpoint -q ${MONGO_PATH} || sudo mount ${DISK} ${MONGO_PATH}

docker volume prune -f >/dev/null

docker rm -f ${CONTAINER_PRIM} ${CONTAINER_SEC1} ${CONTAINER_SEC2} 2>/dev/null
sudo rm -rf ${MONGO_DATA_PATH}

docker network rm ${MONGO_NET} 2>/dev/null
docker network create ${MONGO_NET}

docker run -d --name ${CONTAINER_PRIM} --net ${MONGO_NET} -p 27017:27017 -v ${MONGO_DATA_PATH}:/data/db mongo:${MONGO_V} --replSet rs0 ${DOCKER_IMAGE_ARG}

docker run -d --name ${CONTAINER_SEC1} --net ${MONGO_NET} -p 27018:27017 mongo:${MONGO_V} --replSet rs0 ${DOCKER_IMAGE_ARG}

docker run -d --name ${CONTAINER_SEC2} --net ${MONGO_NET} -p 27019:27017 mongo:${MONGO_V} --replSet rs0 ${DOCKER_IMAGE_ARG}

#=====

sleep 5

echo "rs.initiate({_id: 'rs0', members: [{_id: 0, host: '${CONTAINER_PRIM}:27017', priority: 2}, {_id: 1, host: '${CONTAINER_SEC1}:27017', priority: 1}, {_id: 2, host: '${CONTAINER_SEC2}:27017', priority: 1}]})" | docker exec -i ${CONTAINER_PRIM} mongo --quiet 

sleep 15

#=====

(
while true; do
    	docker exec ${CONTAINER_SEC1} mongo --quiet --eval "printjson(rs.status().members.map(m => ({id: m._id, name: m.name, state: m.state, stateStr: m.stateStr, uptime: m.uptime})))" > "$RS_LOG.tmp" 2>/dev/null
	
	if [ -s "${RS_LOG}.tmp" ]; then
     		 mv "${RS_LOG}.tmp" "$RS_LOG"
    	fi

	sleep 1
done
) &
MONITOR_PID=$!

(
while true; do
	start_time=$(date +%s%3N)
    	output=$(docker exec ${CONTAINER_PRIM} mongo --quiet --eval "db.test.insert({t: new Date()}, {writeConcern: {j: true}})" 2>&1 | tr -d '\n')
    	end_time=$(date +%s%3N)

    	echo "$output | $((end_time - start_time)) ms" >> "$WRITE_LOG"
    	sleep 1
done
) &
WRITER_PID=$!

trap 'kill $MONITOR_PID $WRITER_PID 2>/dev/null; rm -f "$RS_LOG" "$WRITE_LOG"; exit 0' SIGINT EXIT

#=====

while true; do
	clear
	echo "STATUS:"
  	cat "$RS_LOG"

	echo ""

	echo "LOG:"
  	tail -n 10 "$WRITE_LOG"
	
	sleep 1
done

