pragma solidity >=0.4.0 <0.6.0;


import "./QueueHelper.sol";


/// @author The Papyrus team.
/// @title Main consensus and staking contract.
/// @dev Based on QueueHelper that brings queue implementation code.
contract Bios is QueueHelper {
    uint32 constant freezeGap = 5 seconds;   // time gap before withdrawing melted stake

    /// Public data shared with client code.
    mapping(address=>uint) public stakes;    // stakes map reside in slot #0
    address[] public sealers;                // sealers array reside in slot #1

    /// Public contract state.
    uint constant public version = 1;        // contract code version
    mapping(address=>Queue) public melting;  // melting stakes queues


    /// Stake the specified amount of money.
    /// @dev The value is on the contract account and thus inaccessible to the sender.
    /// @dev msg.value the value to be staked.
    function freeze() payable public {
        require(msg.value > 0);
        stakes[msg.sender] += msg.value;
    }

    /// Unstake the specified value of money.
    /// @dev The value is put to the melting queue and can be withdrawn after `freezeGap`.
    /// @param val value to unstake.
    function melt(uint224 val) public {
        require(val != 0 && stakes[msg.sender] >= val);
        QueueHelper.push(melting[msg.sender], Entry(val, uint32(now)));
        stakes[msg.sender] -= val;
    }

    /// Withdraw the previously unstaked amount of money provided the `freezeGap` time
    /// had passed since its unstake.
    /// @notice Every 'unstake' call must match 'withdraw' call.
    /// @dev Takes the latest melting queue element and transfers its money amount
    ///      to the sender's account.
    function withdraw() public {
        QueueHelper.Entry storage entry = QueueHelper.head(melting[msg.sender]);
        require(now >= entry.timestamp + freezeGap);
        msg.sender.transfer(entry.stake);
        QueueHelper.pop(melting[msg.sender]);
    }

    /// Service function, calculates the number of queue elements (slots)
    /// is aviable in the melting conveyer for the sender's account.
    /// @dev Every unstake call consumes a slot, every withdrawal releases it.
    function getFreeMeltingSlots() view public returns (uint8) {
        return QueueHelper.queueLen - QueueHelper.size(melting[msg.sender]);
    }

    /// Service function, calculates the latest melting conveyer slot to be
    /// withdrawn first.
    /// @return Stake and timestamp pair, where stake is the amount of money unstaked
    ///         and timestamp is the time of the unstake call.
    function getMeltingHead() view public returns (uint224 stake, uint32 timestamp) {
        QueueHelper.Entry storage entry = QueueHelper.head(melting[msg.sender]);
        return (entry.stake, entry.timestamp);
    }

    /// @dev Work in progress.
    function addSealer(address sealer) public {
        sealers.push(sealer);
    }

    /// @dev Work in progress.
    function removeSealer(uint i) public {
        sealers[i] = sealers[sealers.length - 1];
        sealers.length --;
    }
}
