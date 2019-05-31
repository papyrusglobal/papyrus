Bios smart contract
===================

Compile
-------

    solc --bin-runtime contracts/Bios.sol

and put the resulting binary data to config/genesis.json.


Storage
-------

Stakes is a map residing in the first slot of storage space. To read stakes of
the given address, run

    eth.getStorageAt("0x0000000000000000000000000000000000000022", hash)

where hash is

    u = require('web3-utils');
    u.keccak256("0x000000000000000000000000fe61af93f93e578f3986584a91443d5b1378d04b0000000000000000000000000000000000000000000000000000000000000000")

(2 x 32 bytes) where fe..4b is the address of the stake we want. `GetStaked()`
in `state_processor.go` implements this algorithm.

Sealers is an array residing in the second slot of storage space. To read it,
use `GetSigners` in `state_processor.go`.

See more details about mapping and array layouts at
https://solidity.readthedocs.io/en/latest/miscellaneous.html#mappings-and-dynamic-arrays.
