#!/bin/bash
MPS=$(echo $HOME/samd/mps/apps/R2022b)
dockerid=`docker ps -aqf "name=matlab-prodserver"`
# if no production server running, do nothing
[[ ! -z "$dockerid" ]] && docker kill ${dockerid}
[[ ! -z "$dockerid" ]] && docker rm ${dockerid}
#rm -rf $HOME/samd/mps/mps
