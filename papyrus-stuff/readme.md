Test network
============

The network consists of 5 nodes:

1. Local-Papyrus-test-1 - miner with address
   `fe61af93f93e578f3986584a91443d5b1378d04b`.
2. Local-Papyrus-test-2 - miner with address
   `4d7ce34437695e6a615ff1e28265c7e46daeaf1e`.
3. Local-Papyrus-test-2 - miner with address
   `e04db742d1b83dd1d03225617f4ded5c9d210fbd`.
4. Local-Papyrus-test-4 - no function, just watches.
5. Local-Papyrus-test-gw - gateway with rpc on http://localhost:18545.

Logs of every node are saved in `log.N` file.


Setup
-----

1.  Run the ethstats server. You need to do it only once.

        docker run --name=local-ethstats -d -p 4000:3000 -e WS_SECRET="papyrus" papyrusglobal/netstats:test-latest

    Browse it on http://localhost:4000.

2.  Run or restart the network.

        ./restart.sh

    Logs of every node will go to `log.N` file.

3.  Connect your metamask to http://localhost:18545.

    **Important!** For the first time only, make sure that the network
    (`localhost:18545`) did not exist in your Metamask settings
    before. Otherwise you are likely to see `Error: invalid sender` when you
    run any transaction.

    **Important!** Every time after you restarted the network, reset the account
    (Metamask - settings - reset account), otherwise your transactions will be
    pending until timeout.

4.  Go to https://remix.ethereum.org/ and choose environment "Injected Web3"
    option.

    Upload the Bios contract from [Bios.sol](contracts/Bios.sol) and set it
    "At address" `0x0000000000000000000000000000000000000022`.

    As a test, click on `version` function and you should see 1.

    Also you may do the following:
    * stake some amount for the current account - specify the "Value" and
      click on `freeze`,
    * query currently staked value for any given account - click on `stakes`,
    * unstake some amount for the current account - click on `melt`,
    * withdraw the melted amount if it "freeze gap" has elapsed since you
      melted this amount - click on `withdraw`.

5.  To get the current limit of some account, run either

        echo '{"jsonrpc":"2.0","method":"eth_getLimit","params":["0x24b8fb159ef175c5d17cb883f87b6ca0699b56b6", "latest"],"id":1}' | nc -Uq0 data.1/geth.ipc

    or

        curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getLimit","params":["0x24b8fb159ef175c5d17cb883f87b6ca0699b56b6", "latest"],"id":1}' http://localhost:18545

    This command queries the limit of account with address
    `0x24b8fb159ef175c5d17cb883f87b6ca0699b56b6` from the first (`data.1`) node.
