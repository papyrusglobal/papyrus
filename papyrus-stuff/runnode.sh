#! /bin/bash
cd $(dirname $0)
. config/config.sh

NUM=${1:-1}
EXTRA=${@:2}

if [[ ! "$NUM" =~ ^[1-9]+$ ]]; then
    echo "Incorrect argument" >&2
    exit 1
fi

GETH="${FULLGETH} --datadir=$DATADIR.$NUM"
if pgrep -f "$GETH"; then
    echo "The process is already running" >&2
    exit 2
fi

$GETH init config/genesis.json
cp config/nodekey.$NUM $DATADIR.$NUM/geth/nodekey
cp config/static-nodes.json $DATADIR.$NUM/
if [ -f config/account.$NUM.json ]; then
    cp config/account.$NUM.json $DATADIR.$NUM/keystore/
    EXTRA+=('--unlock 0 --password /dev/null')
fi

$GETH --verbosity 5 \
      --port 3130$NUM \
      --networkid=323138 \
      --syncmode='full' \
      --nodiscover \
      --ethstats="Local-Papyrus-test-$NUM:papyrus@localhost:4000" \
      ${EXTRA[@]} \
      >log.$NUM 2>&1 &
