#!/bin/bash
# We need to create the network for kafka only once
#Start MATLAB Prodoction Server image
MPS=$(echo $HOME/samd/mps/apps/R2024b)
umask 000
docker run -d --name matlab-prodserver --network kafka-net -p 9900:9910 -v $MPS:/share/auto_deploy wyu/matlab-prodserver:r2024b
