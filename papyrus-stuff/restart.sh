#! /bin/sh
cd $(dirname $0)
. config/config.sh

./stop.sh

$GETH1 init config/genesis.json
cp config/account.1.json $DATADIR.1/keystore/
cp config/nodekey.1 $DATADIR.1/geth/nodekey
cp config/static-nodes.json $DATADIR.1/

$GETH2 init config/genesis.json
cp config/account.2.json $DATADIR.2/keystore/
cp config/nodekey.2 $DATADIR.2/geth/nodekey
cp config/static-nodes.json $DATADIR.2/

$GETH3 init config/genesis.json
cp config/nodekey.3 $DATADIR.3/geth/nodekey
cp config/static-nodes.json $DATADIR.3/

$GETH4 init config/genesis.json
cp config/nodekey.4 $DATADIR.4/geth/nodekey
cp config/static-nodes.json $DATADIR.4/

$GETH1 --verbosity 5 \
       --port 31301 \
       --networkid=323138 \
       --syncmode='full' \
       --nodiscover \
       --unlock 0 \
       --password /dev/null \
       --mine \
       --ethstats='Local-Papyrus-test-1:papyrus@localhost:4000' \
       >log.1 2>&1 &

$GETH2 --verbosity 5 \
       --port 31302 \
       --networkid=323138 \
       --syncmode='full' \
       --nodiscover \
       --unlock 0 \
       --password /dev/null \
       --mine \
       --ethstats='Local-Papyrus-test-2:papyrus@localhost:4000' \
       >log.2 2>&1 &

$GETH3 --verbosity 5 \
       --port 31303 \
       --networkid=323138 \
       --syncmode='full' \
       --nodiscover \
       --ethstats='Local-Papyrus-test-3:papyrus@localhost:4000' \
       >log.3 2>&1 &

$GETH4 --verbosity 5 \
       --port 31304 \
       --networkid=323138 \
       --syncmode='full' \
       --nodiscover \
       --rpc \
       --rpcaddr='0.0.0.0' \
       --rpcport=18545 \
       --rpccorsdomain='*' \
       --rpcvhosts='*' \
       --ethstats='Local-Papyrus-test-4:papyrus@localhost:4000' \
       >log.4 2>&1 &
