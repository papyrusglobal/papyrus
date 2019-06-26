pragma solidity >=0.4.0 <0.6.0;


/// @author The Papyrus team.
/// @title Locator contract that points to the current Bios contract address.
/// @dev Minimal contract residing at fixed address
///      0x0000000000000000000000000000000000000022.
contract Versioner {
    address public bios;

    event BiosUpgreded(address indexed bios);

    function upgrade(address candidate) public {
        require(msg.sender == bios || bios == address(0));
        bios = candidate;
        emit BiosUpgreded(bios);
    }
}
