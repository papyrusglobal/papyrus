#! /bin/sh
DATADIR=data
GETH="${GOPATH:-~}/src/github.com/ethereum/go-ethereum/build/bin/geth"
GETH1="${GETH} --datadir=$DATADIR.1"
GETH2="${GETH} --datadir=$DATADIR.2"
GETH3="${GETH} --datadir=$DATADIR.3"
GETH4="${GETH} --datadir=$DATADIR.4"
GETH5="${GETH} --datadir=$DATADIR.5"
