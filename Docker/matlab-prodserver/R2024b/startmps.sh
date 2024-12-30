#!/bin/bash

# set -euo pipefail
set -eo pipefail

# Redis server variable:
echo "START_REDIS_SERVER == ${START_REDIS_SERVER}"
echo "PROD_SERVER_ROOT == ${PROD_SERVER_ROOT}"
echo "PROD_SERVER_INSTANCE == ${PROD_SERVER_INSTANCE}"

if [ -e /opt/mpsinstanc/mps ]
then
        echo "mps have been setup"
	else
        echo "start the new mps setup"
	${PROD_SERVER_ROOT}/script/mps-new ${PROD_SERVER_INSTANCE} -v
        cp -p /opt/main_config /opt/mpsinstance/mps/config
        cp -p /opt/mps_cache_config /opt/mpsinstance/mps/config
fi

echo "start mps instance"
${PROD_SERVER_ROOT}/script/mps-start -C ${PROD_SERVER_INSTANCE}

# Start the redis server if we have START_REDIS_SERVER defined to true
if [ "true" = "$START_REDIS_SERVER" ]
then
echo "Starting the Redis server"
    # First, start the cache
    ${PROD_SERVER_ROOT}/script/mps-cache start -C ${PROD_SERVER_INSTANCE} --all
    # Now turn off protected mode, to allow access from MOS
    ${PROD_SERVER_ROOT}/bin/glnxa64/redis-cli -p 4321 CONFIG SET protected-mode no
else
    echo "Redis server is not used"
fi


#echo "start mps instance"

tail -f /opt/mpsinstance/mps/log/main.log
