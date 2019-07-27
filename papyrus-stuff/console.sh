#! /bin/bash
cd $(dirname $0)
. config/config.sh

GETH="${GOPATH:-~}/src/github.com/ethereum/go-ethereum/build/bin/geth"
$GETH attach $DATADIR.${1:-1}/geth.ipc "${@:2}"
