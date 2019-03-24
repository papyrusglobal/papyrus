//
// Consensus specific contract for staking accounts.
//
// Compile with `solc --bin-runtime contracts/Bios.sol` and put the
// resulting binary data to config/genesis.json.
//
// To read status of the given address, run
// `eth.getStorageAt("0x0000000000000000000000000000000000000022", hash)`,
// where hash is `u = require('web3-utils')`,
// `u.keccak256("0x000000000000000000000000fe61af93f93e578f3986584a91443d5b1378d04b0000000000000000000000000000000000000000000000000000000000000000")` (2 x 32 bytes).
// See more details about mapping layout at
// https://solidity.readthedocs.io/en/latest/miscellaneous.html#mappings-and-dynamic-arrays.
//
pragma solidity ^0.5.1;


import "./QueueHelper.sol";


contract Bios is QueueHelper {
    uint constant public version = 1;

    uint32 constant freezeGap = 5 seconds;

    mapping(address=>uint) public stakes;
    mapping(address=>Queue) public melting;

    function freeze() payable public {
        require(msg.value > 0);
        stakes[msg.sender] += msg.value;
    }

    function melt(uint224 val) public {
        require(val != 0 && stakes[msg.sender] >= val);
        QueueHelper.push(melting[msg.sender], Entry(val, uint32(now)));
        stakes[msg.sender] -= val;
    }

    function withdraw() public {
        QueueHelper.Entry storage entry = QueueHelper.head(melting[msg.sender]);
        require(now >= entry.timestamp + freezeGap);
        msg.sender.transfer(entry.stake);
        QueueHelper.pop(melting[msg.sender]);
    }

    function getFreeMeltingSlots() view public returns (uint8) {
        return QueueHelper.queueLen - QueueHelper.size(melting[msg.sender]);
    }

    function getMeltingHead() view public returns (uint224 stake, uint32 timestamp) {
        QueueHelper.Entry storage entry = QueueHelper.head(melting[msg.sender]);
        return (entry.stake, entry.timestamp);
    }
}
