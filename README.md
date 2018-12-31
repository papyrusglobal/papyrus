## Papyrus network


Papyrus network is a public blockchain for developers designed for mass adoption and enterprise usage. This is the first Ethereum-based scalable universal blockchain network with various smart contracts capabilities which can be successfully used in all industries, especially in data centric applications. Papyrus Network utilizes Proof-of-Authority (PoA) as its consensus mechanism. We provide the flexibility to code in Ethereum standards with the added benefits of Papyrus Network solutions to scalability and interoperability in blockchain networks.

[![API Reference](
https://camo.githubusercontent.com/915b7be44ada53c290eb157634330494ebe3e30a/68747470733a2f2f676f646f632e6f72672f6769746875622e636f6d2f676f6c616e672f6764646f3f7374617475732e737667
)](https://godoc.org/github.com/ethereum/papyrus)
[![Go Report Card](https://goreportcard.com/badge/github.com/ethereum/papyrus)](https://goreportcard.com/report/github.com/ethereum/papyrus)
[![Travis](https://travis-ci.org/ethereum/papyrus.svg?branch=master)](https://travis-ci.org/ethereum/papyrus)
[![Discord](https://img.shields.io/badge/discord-join%20chat-blue.svg)](https://discord.gg/nthXNEv)


## Building the source

For prerequisites and detailed build instructions please read the
[Installation Instructions](https://github.com/ethereum/papyrus/wiki/Building-Ethereum)
on the wiki.

Building geth requires both a Go (version 1.9 or later) and a C compiler.
You can install them using your favourite package manager.
Once the dependencies are installed, run

    make geth

or, to build the full suite of utilities:

    make all

## Executables

The papyrus project comes with several wrappers/executables found in the `cmd` directory.

| Command    | Description |
|:----------:|-------------|
| **`geth`** | Main Ethereum CLI client. It is the entry point into the Papyrus network (main-, test- or private net), capable of running as a full node (default), archive node (retaining all historical state) or a light node (retrieving data live). It can be used by other processes as a gateway into the Papyrus network via JSON RPC endpoints exposed on top of HTTP, WebSocket and/or IPC transports. `geth --help` and the [CLI Wiki page](https://github.com/ethereum/papyrus/wiki/Command-Line-Options) for command line options. |
| `abigen` | Source code generator to convert Ethereum contract definitions into easy to use, compile-time type-safe Go packages. It operates on plain [Ethereum contract ABIs](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI) with expanded functionality if the contract bytecode is also available. However it also accepts Solidity source files, making development much more streamlined. Please see our [Native DApps](https://github.com/ethereum/papyrus/wiki/Native-DApps:-Go-bindings-to-Ethereum-contracts) wiki page for details. |
| `bootnode` | Stripped down version of our Ethereum client implementation that only takes part in the network node discovery protocol, but does not run any of the higher level application protocols. It can be used as a lightweight bootstrap node to aid in finding peers in private networks. |
| `evm` | Developer utility version of the EVM (Ethereum Virtual Machine) that is capable of running bytecode snippets within a configurable environment and execution mode. Its purpose is to allow isolated, fine-grained debugging of EVM opcodes (e.g. `evm --code 60ff60ff --debug`). |
| `gethrpctest` | Developer utility tool to support our [ethereum/rpc-test](https://github.com/ethereum/rpc-tests) test suite which validates baseline conformity to the [Ethereum JSON RPC](https://github.com/ethereum/wiki/wiki/JSON-RPC) specs. Please see the [test suite's readme](https://github.com/ethereum/rpc-tests/blob/master/README.md) for details. |
| `rlpdump` | Developer utility tool to convert binary RLP ([Recursive Length Prefix](https://github.com/ethereum/wiki/wiki/RLP)) dumps (data encoding used by the Ethereum protocol both network as well as consensus wise) to user friendlier hierarchical representation (e.g. `rlpdump --hex CE0183FFFFFFC4C304050583616263`). |
| `swarm`    | Swarm daemon and tools. This is the entrypoint for the Swarm network. `swarm --help` for command line options and subcommands. See [Swarm README](https://github.com/ethereum/papyrus/tree/master/swarm) for more information. |
| `puppeth`    | a CLI wizard that aids in creating a new Ethereum network. |

## Running geth

Going through all the possible command line flags is out of scope here (please consult our
[CLI Wiki page](https://github.com/ethereum/papyrus/wiki/Command-Line-Options)), but we've
enumerated a few common parameter combos to get you up to speed quickly on how you can run your
own Geth instance.

### Full node on the Papyrus test network
-------------

Prerequisites
-------------

1. You need to have a machine capable of running ethereum client
   [geth](https://geth.ethereum.org/).

2. Your network firewall should allow connection to at least one TCP and UDP
   port. This manual uses port number 30301 but you can change it to any other
   number.

3.  You need docker installed on your machine.

    To quickly install docker on Ubuntu, follow these steps:

        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh

    I also recommend adding your user to the docker group so you can run
    following docker commands without sudo prefix.

        sudo usermod -aG docker $USER

    ⚠ Note that you need to log out all you existing sessions. Then log in
    again.
    
Run the node
------------

    sudo docker run -d --name=my-node -p 32303:32303 -p 32303:32303/udp papyrusglobal/geth-papyrus:test2-latest --port 32303 --ethstats='My node:ante litteram@head.papyrus.network:3500'

This command downloads and runs the docker container
"papyrusglobal/geth-papyrus:test-latest" that will use ports 30301/tcp and
30301/udp for peer communication and report statistics to public server as "My
node".

You may use standard docker commands (start/stop/rm/exec) to operate the
container. For example, to see logs, run `docker logs my-node`.

For more useful parameters that you may want to add, see sections below.
   
Optional parameters
-------------------

You can use any geth command line options
(https://github.com/ethereum/go-ethereum/wiki/Command-Line-Options).

I recommend the following useful additions to your command line:

To allow rpc interface, to use it for your application, consider adding the
following options:

    --rpc --rpcaddr='0.0.0.0'
    --rpccorsdomain="*"

⚠ Note that you need to add `-p 8545:8545` option to the docker part of the
command to expose the port to your machine network.

⚠ Note also that if you want to connect Metamask or other software from the
outside of your machine, make sure that your firewall accepts incoming
8545/tcp port connections. Port number may be changed with `--rpcport` option.

The same for websocket interface.

    --ws  --wsaddr='0.0.0.0'
    --wsorigins="*"

Same notes above apply to the default websocket port 8546/tcp.

To add much more verbose logs, add the following. Remember to remove this as
you don't need it anymore to save space.

    --verbosity=5


### Configuration

As an alternative to passing the numerous flags to the `geth` binary, you can also pass a configuration file via:

```
$ geth --config /path/to/your_config.toml
```

To get an idea how the file should look like you can use the `dumpconfig` subcommand to export your existing configuration:

```
$ geth --your-favourite-flags dumpconfig
```

*Note: This works only with geth v1.6.0 and above.*

Commands
--------

To add a new account:

    docker exec -it my-node geth account new

Or to import the existing account:

    docker cp path/to/account.json my-node:/root/.ethereum/keystore/

To check accounts you have:

    docker exec -it my-node geth account list

To unlock the account the first account with password "password" for unlimited
time:

    docker exec -it my-node ./console.sh 'personal.unlockAccount(eth.accounts[0], "password", 0)'

To check the sealers, run:

    docker exec -it my-node ./console.sh 'papyrus.getSigners()'

To vote for the new sealer, run:

    docker exec -it my-node ./console.sh 'papyrus.propose("0x123...321", true)'

To start mining, using your first account for the coin-base, run:

    docker exec -it my-node ./console.sh 'miner.setEtherbase(eth.accounts[0]); miner.start()'


## License

The papyrus library (i.e. all code outside of the `cmd` directory) is licensed under the
[GNU Lesser General Public License v3.0](https://www.gnu.org/licenses/lgpl-3.0.en.html), also
included in our repository in the `COPYING.LESSER` file.

The papyrus binaries (i.e. all code inside of the `cmd` directory) is licensed under the
[GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html), also included
in our repository in the `COPYING` file.
