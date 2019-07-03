Bios smart contract
===================

Compile
-------

    solc --bin-runtime --optimize contracts/Versioner.sol

and put the resulting binary data to config/genesis.json.


Bios upgrade and Versioner contract
-----------------------------------

To track the current address of the Bios contract, there is a
[Versioner](Versioner.sol) contract located at fixed address
0x0000000000000000000000000000000000000022. To query it for the Bios contract
address, use `bios` public method. Here is an example in javascript:

    const versionerAbi = [
      {
        constant: true,
        inputs: [],
        name: 'bios',
        outputs: [{ name: '', type: 'address' }],
        payable:false,
        stateMutability: 'view',
        type: 'function'
      }
    ];
    const versionerAddress = '0x0000000000000000000000000000000000000022';
    const versioner = new web3.eth.Contract(versionerAbi, versionerAddress);
    const biosAddress = await versioner.methods.bios().call({ from: account });

Note that the resulting address may be zero, this means that the Bios contract
is not yet installed.


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
