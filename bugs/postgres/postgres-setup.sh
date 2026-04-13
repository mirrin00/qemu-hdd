#!/usr/bin/bash

#=====

PG_V="9.6.10"

#=====

DISK="/dev/sdb"

MOUNT_PATH="/mnt"
PG_PATH="${MOUNT_PATH}/pg-test"
PG_DATA_PATH="${PG_PATH}/pgdata"

CONTAINER="pg-test"

#=====

sudo fsck -t ext4 -MT ${DISK} > /dev/null || sudo mkfs.ext4 ${DISK}

sudo mkdir -p ${MOUNT_PATH}
sudo mkdir -p ${PG_PATH}

mountpoint -q ${PG_PATH} || sudo mount ${DISK} ${PG_PATH}

docker volume prune -f >/dev/null

docker rm -f ${CONTAINER} 2>/dev/null
sudo rm -rf ${PG_DATA_PATH}

docker run --name ${CONTAINER} -e POSTGRES_PASSWORD=postgres -v ${PG_DATA_PATH}:/var/lib/postgresql/data -d postgres:${PG_V}

sleep 10

#=====

docker exec -i ${CONTAINER} psql -U postgres -c "CREATE TABLE t(id serial, data text);" >/dev/null 2>&1
docker exec -i ${CONTAINER} psql -U postgres -c "INSERT INTO t(data) VALUES ('init'); CHECKPOINT;" >/dev/null 2>&1

REL_T_PATH=$(docker exec -i ${CONTAINER} psql -U postgres -t -c "SELECT pg_relation_filepath('t');" | tr -d ' ' | tr -d '\n' | tr -d '\r')
FULL_T_PATH="${PG_DATA_PATH}/${REL_T_PATH}"

echo "==="
echo $(sudo filefrag -v "${FULL_T_PATH}" | awk '$1 ~ /^[0-9]+:/ {gsub(/\.\./, "", $4); block=$4; sector=block*8; print "Сектор: " sector}')
echo "==="

