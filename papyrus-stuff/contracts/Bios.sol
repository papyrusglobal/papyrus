pragma solidity >=0.4.0 <0.6.0;


import "./QueueHelper.sol";


/// @author The Papyrus team.
/// @title Main consensus and staking contract.
/// @dev Based on QueueHelper that brings queue implementation code.
contract Bios is QueueHelper {
    uint32 constant kFreezeGap = 5 seconds;   // time gap before withdrawing melted stake
    uint constant kNewSealerPollTime = 1 minutes;
    uint constant kMinWinVotes = 2;
    uint constant kSealerVotes = 7;           // votes each participant has

    /// Public data shared with client code.
    mapping(address=>uint) public stakes;    // stakes map reside in slot #0
    address[] public sealers;                // sealers array reside in slot #1

    /// Public contract state.
    uint constant public version = 1;        // contract code version
    mapping(address=>Queue) public melting;  // melting stakes queues
    bool public initialized = false;         // function init() called

    /// Polling data.
    struct Polling {
        uint closeTime;
        uint votes;
    }
    mapping(address=>Polling) public addNewPoll;
    address[] public pollingAddresses;

    /// Voting state of every sealer.
    struct SealerState {
        uint votes;
        address[kSealerVotes] bet;
    }
    mapping(address=>SealerState) public sealerStates;

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
        require(now >= entry.timestamp + kFreezeGap);
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

    /// @dev populate initial sealers
    function init(address[] memory _sealers) public {
        require(initialized == false);
        SealerState memory sealerState;
        sealerState.votes = 1;
        for (uint i = 0; i < _sealers.length; ++i) {
            sealers.push(_sealers[i]);
            sealerStates[_sealers[i]] = sealerState;
        }
        initialized = true;
    }

    /// Propose polling for new sealer.
    /// @param participant - new sealer address.
    function proposeNewSealer(address participant) public {
        require(sealerStates[msg.sender].votes != 0, "must be sealer");
        require(sealerStates[participant].votes == 0, "already sealer");
        require(addNewPoll[participant].closeTime == 0, "already proposed");
        addNewPoll[participant] = Polling(now + kNewSealerPollTime, 0);
        pollingAddresses.push(participant);
    }

    /// Vote for the participant in a poll.
    /// @param slot - number of voting slot to bet.
    /// @param participant - address of the proposed sealer.
    function votePoll(uint slot, address participant) public {
        require(slot < kSealerVotes, "slot too big");
        require(addNewPoll[participant].closeTime != 0, "no polling");
        require(addNewPoll[participant].closeTime > now, "polling already closed");
        SealerState storage state = sealerStates[msg.sender];
        require(state.votes != 0, "must be sealer");
        for (uint i = 0; i < kSealerVotes; i++) {
            require(state.bet[i] != participant, "already bet");
        }
        // TODO: clear current bet
        state.bet[slot] = participant;
        addNewPoll[participant].votes++;
    }

    /// Handle all pollings where time is up.
    /// @dev Anyone may call it.
    function handleClosedPollings() public {
        uint i = 0; 
        do {
            Polling storage poll = addNewPoll[pollingAddresses[i]];
            if (poll.closeTime <= now) {
                if (poll.votes >= kMinWinVotes) {
                    sealers.push(pollingAddresses[i]);
                    SealerState memory sealer;
                    sealer.votes = poll.votes;
                    sealerStates[pollingAddresses[i]] = sealer;
                }
                delete(addNewPoll[pollingAddresses[i]]);
                pollingAddresses[i] = pollingAddresses[pollingAddresses.length - 1];
                --pollingAddresses.length;
            }
        } while (++i < pollingAddresses.length);
    }

    /// @dev Work in progress.
    function removeSealer(uint i) public {
        delete(sealerStates[sealers[i]]);
        sealers[i] = sealers[sealers.length - 1];
        sealers.length --;
    }
}
