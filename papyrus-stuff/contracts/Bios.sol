pragma solidity 0.5.1;


import "./Versioner.sol";
import "./QueueHelper.sol";
import "./Ownable.sol";


/// @author The Papyrus team.
/// @title Main consensus and staking contract.
/// @dev Based on QueueHelper that brings queue implementation code.
contract Bios is QueueHelper, Ownable {
    uint constant kFreezeStake = 10 minutes; // time gap before withdrawing melted stake
    uint constant kNewAuthorityPollTime = 5 minutes;
    uint constant kBlacklistAuthorityPollTime = 5 minutes;
    uint constant kMinWinVotes = 3;          // threshold votes for new authority
    uint constant kSealerBets = 7;           // bets each participant has
    uint constant kFreezeBet = 2 minutes;    // time gap between updating the authority bet

    /// Public data shared with client code.
    mapping(address=>uint) public stakes;    // stakes map reside in slot #0
    address[] sealers;                       // sealers array reside in slot #1

    /// Public contract state.
    uint constant public version = 2;        // contract code version
    mapping(address=>Queue) public melting;  // melting stakes queues

    /// Poll status for the new authority.
    struct NewAuthorityPollStatus {
        uint closeTime;
        uint votes;
    }
    mapping(address=>NewAuthorityPollStatus) public addNewPoll;
    address[] addNewPollAddresses;

    /// Poll status for the authority blacklisting.
    struct AuthorityBlacklistPollStatus {
        uint closeTime;
        uint votes;
        mapping(address=>bool) voted;
    }
    mapping(address=>AuthorityBlacklistPollStatus) public authorityBlacklistPoll;
    address[] authorityBlacklistPollAddresses;

    /// Poll state of the authority.
    struct AuthorityState {
        uint votes;
        address[kSealerBets] bet;
        uint[kSealerBets] betFrozenUntil;  // should be a struct, but
                                           // UnimplementedFeatureError:
                                           // Copying of type struct memory to storage
                                           // not yet supported.
    }
    mapping(address=>AuthorityState) public authorityStates;

    /// Black lists
    mapping(address=>bool) public authorityBlackList;

    constructor(address[] memory _sealers) public {
        AuthorityState memory state;
        state.votes = 1;
        for (uint i = 0; i < _sealers.length; ++i) {
            sealers.push(_sealers[i]);
            authorityStates[_sealers[i]] = state;
        }
    }

    /// Stake the specified amount of money.
    /// @dev The value is on the contract account and thus inaccessible to the sender.
    /// @dev msg.value the value to be staked.
    function freeze() payable public {
        require(msg.value > 0);
        stakes[msg.sender] += msg.value;
    }

    /// Unstake the specified value of money.
    /// @dev The value is put to the melting queue and can be withdrawn after `kFreezeStake`.
    /// @param val value to unstake.
    function melt(uint224 val) public {
        require(val != 0 && stakes[msg.sender] >= val, "not enough stake");
        QueueHelper.push(melting[msg.sender], Entry(val, uint32(now)));
        stakes[msg.sender] -= val;
    }

    /// Withdraw the previously unstaked amount of money provided the `kFreezeStake` time
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
    /// is available in the melting conveyer for the sender's account.
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

    /// Service function, returns all melting conveyer content.
    /// @return array of melting stakes and array of their timestamps.
    function getMeltingSlots() view public returns (uint224[] memory, uint32[] memory) {
        return QueueHelper.all(melting[msg.sender]);
    }

    /// Service function to show all current authorities.
    /// @return array of authority addresses.
    function getAuthorities() public view returns (address[] memory) {
        return sealers;
    }

    /// Service function.
    /// @return array of addresses that participate in authority pools.
    function getAddNewPollAddresses() public view returns (address[] memory) {
        return addNewPollAddresses;
    }

    /// Service function.
    /// @return array of addresses that participate in blacklist authority pools.
    function getAuthorityBlacklistPollAddresses() public view returns (address[] memory) {
        return authorityBlacklistPollAddresses;
    }

    /// Service function inspects authority bets.
    /// @return votes number currently bet for this authority,
    ///         and pair of arrays: bets and their frozen times.
    function getAuthorityState(address authority)
        public
        view
        returns (uint votes, address[kSealerBets] memory, uint[kSealerBets] memory)
    {
        AuthorityState storage state = authorityStates[authority];
        return (state.votes, state.bet, state.betFrozenUntil);
    }

    /// Propose a poll for a new authority.
    /// @param participant - new authority address.
    function proposeNewAuthority(address participant) public {
        require(authorityStates[msg.sender].votes != 0, "must be authority");
        require(authorityStates[participant].votes == 0, "already authority");
        require(addNewPoll[participant].closeTime == 0, "already proposed");
        require(authorityBlackList[participant] == false, "in authority black list");
        addNewPoll[participant] = NewAuthorityPollStatus(now + kNewAuthorityPollTime, 0);
        addNewPollAddresses.push(participant);
    }

    /// Propose a poll for blacklisting the authority to the authority black list.
    /// @param participant - new authority address.
    function proposeBlacklistAuthority(address participant) public {
        require(authorityStates[msg.sender].votes != 0, "must be authority");
        require(authorityBlacklistPoll[participant].closeTime == 0, "already proposed");
        require(authorityBlackList[participant] == false, "in authority black list");
        authorityBlacklistPoll[participant] =
            AuthorityBlacklistPollStatus(now + kBlacklistAuthorityPollTime, 0);
        authorityBlacklistPollAddresses.push(participant);
    }

    /// Vote for the new authority.
    /// @param slot - number of voting slot to bet.
    /// @param participant - address of the proposed authority.
    function voteForNewAuthority(uint slot, address participant) public {
        require(slot < kSealerBets, "slot too big");
        require(addNewPoll[participant].closeTime != 0, "no poll");
        require(addNewPoll[participant].closeTime > now, "poll closed");
        AuthorityState storage state = authorityStates[msg.sender];
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
            authorityStates[old].votes--;
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
        AuthorityState storage state = authorityStates[msg.sender];
        require(state.votes != 0, "must be sealer");
        authorityBlacklistPoll[participant].voted[msg.sender] = true;
        authorityBlacklistPoll[participant].votes++;
    }

    /// Handle all pollings where time is up.
    /// @dev Anyone may call it.
    function handleClosedPolls() public {
        uint i = 0;
        while (i < addNewPollAddresses.length) {
            NewAuthorityPollStatus storage poll = addNewPoll[addNewPollAddresses[i]];
            if (poll.closeTime <= now) {
                if (poll.votes >= kMinWinVotes || poll.votes == sealers.length) {
                    addNewAuthority(addNewPollAddresses[i], poll.votes + 1);
                }
                delete(addNewPoll[addNewPollAddresses[i]]);
                addNewPollAddresses[i] = addNewPollAddresses[addNewPollAddresses.length - 1];
                --addNewPollAddresses.length;
            } else {
                ++i;
            }
        }
        // Repeat for authority blacklist poll.
        i = 0;
        while (i < authorityBlacklistPollAddresses.length) {
            address candidate = authorityBlacklistPollAddresses[i];
            AuthorityBlacklistPollStatus storage poll =
                authorityBlacklistPoll[candidate];
            if (poll.closeTime <= now) {
                if (poll.votes >= sealers.length / 2) {
                    blacklistAuthority(candidate);
                }
                delete(authorityBlacklistPoll[authorityBlacklistPollAddresses[i]]);
                authorityBlacklistPollAddresses[i] =
                    authorityBlacklistPollAddresses[authorityBlacklistPollAddresses.length - 1];
                    --authorityBlacklistPollAddresses.length;
            } else {
                ++i;
            }
        }
    }

    /// @dev debug function
    function upgrade(address payable neo) public {
        require(authorityStates[msg.sender].votes != 0, "must be authority");
        Versioner(0x0000000000000000000000000000000000000022).upgrade(neo);
        selfdestruct(neo);
    }
    
    function ownerAddNewAuthority(address candidate) public onlyOwner {
        addNewAuthority(candidate, 1);
    }
    
    function ownerBlacklistAuthority(address candidate) public onlyOwner {
        blacklistAuthority(candidate);
    }
    
    function ownerRemoveFromBlacklist(address candidate) public onlyOwner {
        authorityBlackList[candidate] = false; 
    }
    
    function addNewAuthority(address authority, uint votes) private {
        // TODO: shift out excess sealers.
        sealers.push(authority);
        AuthorityState memory sealer;
        sealer.votes = votes;
        authorityStates[authority] = sealer;        
    }
    
    function blacklistAuthority(address candidate) private {
        authorityBlackList[candidate] = true;
        if (authorityStates[candidate].votes != 0) {
            delete(authorityStates[candidate]);
            for (uint j = 0; j < sealers.length; ++j) {
                if (sealers[j] == candidate) {
                    sealers[j] = sealers[sealers.length - 1];
                    --sealers.length;
                break;
                }
            }
        }
    }
}
