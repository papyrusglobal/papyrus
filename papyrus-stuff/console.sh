#! /bin/bash
cd $(dirname $0)
. config/config.sh
$GETH attach $DATADIR.${1:-1}/geth.ipc "${@:2}"
