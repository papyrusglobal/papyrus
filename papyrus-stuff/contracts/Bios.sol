pragma solidity >=0.4.0 <0.6.0;


import "./QueueHelper.sol";


/// @author The Papyrus team.
/// @title Main consensus and staking contract.
/// @dev Based on QueueHelper that brings queue implementation code.
contract Bios is QueueHelper {
    uint constant kFreezeStake = 5 seconds;  // time gap before withdrawing melted stake
    uint constant kNewAuthorityPollTime = 1 minutes;
    uint constant kBlacklistAuthorityPollTime = 1 minutes;
    uint constant kMinWinVotes = 2;          // threshold votes for new authority
    uint constant kSealerBets = 7;           // bets each participant has
    uint constant kFreezeBet = 1 minutes;

    /// Public data shared with client code.
    mapping(address=>uint) public stakes;    // stakes map reside in slot #0
    address[] public sealers;                // sealers array reside in slot #1

    /// Public contract state.
    uint constant public version = 1;        // contract code version
    mapping(address=>Queue) public melting;  // melting stakes queues
    bool public initialized = false;         // function init() called

    /// Poll status for the new authority.
    struct NewAuthorityPollStatus {
        uint closeTime;
        uint votes;
    }
    mapping(address=>NewAuthorityPollStatus) public addNewPoll;
    address[] public addNewPollAddresses;

    /// Poll status for the authority blacklisting.
    struct AuthorityBlacklistPollStatus {
        uint closeTime;
        uint votes;
        mapping(address=>bool) voted;
    }
    mapping(address=>AuthorityBlacklistPollStatus) public authorityBlacklistPoll;
    address[] public authorityBlacklistPollAddresses;

    /// Poll state of the authority.
    struct SealerState {
        uint votes;
        address[kSealerBets] bet;
        uint[kSealerBets] betFrozenUntil;  // should be a struct, but UnimplementedFeatureError:
                                           // Copying of type struct memory to storage not yet supported.
    }
    mapping(address=>SealerState) public sealerStates;

    /// Black lists
    mapping(address=>bool) public authorityBlackList;

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
        require(val != 0 && stakes[msg.sender] >= val, "not enough stake");
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
        require(now >= entry.timestamp + kFreezeStake, "not yet ready");
        msg.sender.transfer(entry.stake);
        QueueHelper.pop(melting[msg.sender]);
    }

    /// Service function, calculates the number of queue elements (slots)
    /// is aviable in the melting conveyer for the sender's account.
    /// @dev Every unstake call consumes a slot, every withdrawal releases it.
    function getFreeMeltingSlots() view public returns (uint8) {
        return QueueHelper.kQueueLen - QueueHelper.size(melting[msg.sender]);
    }

    /// Service function, calculates the latest melting conveyer slot to be
    /// withdrawn first.
    /// @return Stake and timestamp pair, where stake is the amount of money unstaked
    ///         and timestamp is the time of the unstake call.
    function getMeltingHead() view public returns (uint224 stake, uint32 timestamp) {
        QueueHelper.Entry storage entry = QueueHelper.head(melting[msg.sender]);
        return (entry.stake, entry.timestamp);
    }

    /// Service function, returns all melting convayer content.
    /// @return array of melting stakes and array of their timestaps
    function getMeltingSlots() view public returns (uint224[] memory, uint32[] memory) {
        return QueueHelper.all(melting[msg.sender]);
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

    /// Service function
    /// @return array of addresses that participate in authority pools
    function getAddNewPollAddresses() public view returns (address[] memory) {
        return addNewPollAddresses;
    }

    /// Service function
    /// @return array of addresses that participate in blacklist authority pools
    function getAuthorityBlacklistPollAddresses() public view returns (address[] memory) {
        return authorityBlacklistPollAddresses;
    }

    /// Propose a poll for a new authority.
    /// @param participant - new authority address.
    function proposeNewAuthority(address participant) public {
        require(sealerStates[msg.sender].votes != 0, "must be authority");
        require(sealerStates[participant].votes == 0, "already authority");
        require(addNewPoll[participant].closeTime == 0, "already proposed");
        require(authorityBlackList[participant] == false, "in authority black list");
        addNewPoll[participant] = NewAuthorityPollStatus(now + kNewAuthorityPollTime, 0);
        addNewPollAddresses.push(participant);
    }

    /// Propose a poll for blacklisting the authority to the authority black list.
    /// @param participant - new authority address.
    function proposeBlacklistAuthority(address participant) public {
        require(authorityBlacklistPoll[participant].closeTime == 0, "already proposed");
        require(authorityBlackList[participant] == false, "in authority black list");
        authorityBlacklistPoll[participant] = AuthorityBlacklistPollStatus(now + kBlacklistAuthorityPollTime, 0);
        authorityBlacklistPollAddresses.push(participant);
    }

    /// Vote for the new authority.
    /// @param slot - number of voting slot to bet.
    /// @param participant - address of the proposed authority.
    function voteForNewAuthority(uint slot, address participant) public {
        require(slot < kSealerBets, "slot too big");
        require(addNewPoll[participant].closeTime != 0, "no poll");
        require(addNewPoll[participant].closeTime > now, "poll closed");
        SealerState storage state = sealerStates[msg.sender];
        require(state.votes != 0, "must be sealer");
        require(state.betFrozenUntil[slot] < now, "bet frozen");
        for (uint i = 0; i < kSealerBets; i++) {
            require(state.bet[i] != participant, "already bet");
        }
        // Reset current bet.
        address old = state.bet[slot];
        if (addNewPoll[old].closeTime != 0) {
            addNewPoll[old].votes--;
        } else {
            sealerStates[old].votes--;
        }
        // Set new bet.
        state.bet[slot] = participant;
        state.betFrozenUntil[slot] = uint32(now) + kFreezeBet;
        addNewPoll[participant].votes++;
    }

    /// Vote for adding the participant into authority black list.
    /// @param participant - address of the proposed authority.
    function voteForBlackListAuthority(address participant) public {
        require(authorityBlacklistPoll[participant].closeTime != 0, "no poll");
        require(authorityBlacklistPoll[participant].closeTime > now, "poll closed");
        require(authorityBlacklistPoll[participant].voted[msg.sender] == false, "already voted");
        SealerState storage state = sealerStates[msg.sender];
        require(state.votes != 0, "must be sealer");
        authorityBlacklistPoll[participant].voted[msg.sender] = true;
        authorityBlacklistPoll[participant].votes++;
    }

    /// Handle all pollings where time is up.
    /// @dev Anyone may call it.
    function handleClosedPolls() public {
        for (uint i = 0; i < addNewPollAddresses.length; ++i) {
            NewAuthorityPollStatus storage poll = addNewPoll[addNewPollAddresses[i]];
            if (poll.closeTime <= now) {
                if (poll.votes >= kMinWinVotes) {
                    // TODO: shift out excess sealers.
                    sealers.push(addNewPollAddresses[i]);
                    SealerState memory sealer;
                    sealer.votes = poll.votes + 1;
                    sealerStates[addNewPollAddresses[i]] = sealer;
                }
                delete(addNewPoll[addNewPollAddresses[i]]);
            }
            delete(addNewPollAddresses);
        }
        // Repeat for authority blacklist poll. Wish Solidity had pointers.
        for (uint i = 0; i < authorityBlacklistPollAddresses.length; ++i) {
            address candidat = authorityBlacklistPollAddresses[i];
            AuthorityBlacklistPollStatus storage poll =
                authorityBlacklistPoll[candidat];
            if (poll.closeTime <= now) {
                if (poll.votes >= sealers.length / 2) {
                    authorityBlackList[candidat] = true;
                    if (sealerStates[candidat].votes != 0) {
                        delete(sealerStates[candidat]);
                        for (uint j = 0; j < sealers.length; ++j) {
                            if (sealers[j] == candidat) {
                                sealers[j] = sealers[sealers.length - 1];
                                --sealers.length;
                            break;
                            }
                        }
                    }
                }
                delete(authorityBlacklistPoll[authorityBlacklistPollAddresses[i]]);
            }
            delete(authorityBlacklistPollAddresses);
        }
    }
}
