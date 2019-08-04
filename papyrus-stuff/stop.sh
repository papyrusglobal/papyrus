#! /bin/bash
cd $(dirname $0)
. config/config.sh

NUM=$1

if [ "$NUM" == "all" ]; then
    KILLPATTERN="${FULLGETH} --datadir=$DATADIR"
    DIRPATTERN="$DATADIR*"
elif [[ "$NUM" =~ ^[1-9]+$ ]]; then
    KILLPATTERN="${FULLGETH} --datadir=$DATADIR.$NUM"
    DIRPATTERN="$DATADIR.$NUM/"
else
    echo "Specify node number to stop or 'all'" >&2
    exit 1
fi

pkill -f "$KILLPATTERN"
rm -rf "$DIRPATTERN"
