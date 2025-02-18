// SPDX-FileCopyrightText: © 2023 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.14;

interface DSPauseLike {
    function plans(bytes32) external view returns (bool);
    function drop(address, bytes32, bytes calldata, uint256) external;
}

interface DSSpellLike {
    function action() external view returns (address);
    function tag() external view returns (bytes32);
    function sig() external view returns (bytes memory);
    function eta() external view returns (uint256);
}

contract Spell {
    Protego            immutable protego; //NOTE
    DSPauseLike public immutable pause;
    address     public immutable action;
    bytes32     public immutable tag;
    bytes       public           sig;
    uint256     public immutable eta;

    constructor(address _protego, address _pause, address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta) {
        protego = Protego(_protego);
        pause   = DSPauseLike(_pause);
        action  = _usr;
        tag     = _tag;
        sig     = _fax;
        eta     = _eta;
    }

    function description() external view returns (bytes32) {
        return protego.id(action, tag, sig, eta);
    }

    function planned() external view returns (bool) {
        return protego.planned(action, tag, sig, eta);
    }

    function cast() external {
        pause.drop(action, tag, sig, eta);
    }
}

contract Protego {

    address public immutable pause;

    event DropSpellCreated(address spell);
    event DroppedPlan(bytes32 id);

    constructor(address _pause) {
        pause = _pause;
    }

    // Target a single plan

    // Deploy a drop spell to drop a conformant DssSpell's corresponding plan
    function deploy(DSSpellLike _spell) external returns (address) {
        return _deploy(_spell.action(), _spell.tag(), _spell.sig(), _spell.eta());
    }

    // Deploy a drop spell to drop a specific plan based on its attributes
    function deploy(address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta) external returns (address) {
        return _deploy(_usr, _tag, _fax, _eta);
    }

    function _deploy(address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta) internal returns (address _spell) {
        _spell = address(new Spell(address(this), pause, _usr, _tag, _fax, _eta));
        emit DropSpellCreated(_spell);
    }

    // Calculate a plan's id / hash based on its attributes
    function id(address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta) public pure returns (bytes32) {
        return keccak256(abi.encode(_usr, _tag, _fax, _eta));
    }

    // Calculate a conformant DssSpell's plan id / hash
    function id(DSSpellLike _spell) public view returns (bytes32) {
        return id(_spell.action(), _spell.tag(), _spell.sig(), _spell.eta());
    }

    // Return true if a plan matching the set of attributes is currently scheduled for execution
    function planned(address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta) public view returns (bool) {
        return planned(id(_usr, _tag, _fax, _eta));
    }

    // Return true if a conformant DssSpell is scheduled for execution
    function planned(DSSpellLike _spell) public view returns (bool) {
        return planned(id(_spell));
    }

    // Return true if a plan with the given id / hash is scheduled for execution
    function planned(bytes32 _id) public view returns (bool) {
        return DSPauseLike(pause).plans(_id);
    }

    // Permissionlessly block everything
    // Note: In some cases, due to a governance attack or other unforseen
    //       causes, it may be necessary to block any spell that is entered
    //       into the pause proxy. In this extreme case, the system can be
    //       protected during the pause delay by lifting the Protego contract
    //       to the hat role, which will allow any user to permissionlessly
    //       drop any id from the pause.
    //       This function is expected to revert if it does not have the
    //       authority to perform this function.

    // Drop a specific plan based on its attributes
    function drop(address _usr, bytes32 _tag, bytes memory _fax, uint256 _eta) public {
        DSPauseLike(pause).drop(_usr, _tag, _fax, _eta);
        emit DroppedPlan(id(_usr, _tag, _fax, _eta));
    }

    // Drop a conformant DssSpell's corresponding plan
    function drop(DSSpellLike _spell) external {
        drop(_spell.action(), _spell.tag(), _spell.sig(), _spell.eta());
    }
}
