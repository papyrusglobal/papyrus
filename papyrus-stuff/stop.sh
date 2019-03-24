#! /bin/sh
cd $(dirname $0)
. config/config.sh

pkill -f "geth --datadir=$DATADIR"
rm -rf $DATADIR*
