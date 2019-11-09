pragma solidity 0.5.1;


/// @author The Papyrus team.
/// @title Introduces common data interface between Bios contract and geth code.
/// @dev This contract must be the first in inheritance list of Bios contract.
contract BiosHeader {
    mapping(address=>uint) public stakes;    // stakes map reside in slot #0
    address[] sealers;                       // sealers array reside in slot #1
    uint public blockReward;                 // block reward in wei, slot #2
}
