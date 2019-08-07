#! /bin/sh
cd $(dirname $0)
. config/config.sh

./stop.sh all
rm -rf data.*
./runnode.sh 1 --mine
./runnode.sh 2 --mine
./runnode.sh 3 --mine
./runnode.sh 4
./runnode.sh 5 \
             --rpc \
             --rpcaddr='0.0.0.0' \
             --rpcport=18545 \
             --rpccorsdomain='*' \
             --rpcvhosts='*' \
             --ws \
             --wsaddr='0.0.0.0' \
             --wsport=18546 \
             --wsorigins='*'
