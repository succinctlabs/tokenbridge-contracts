pragma solidity 0.4.24;

import "./Ownable.sol";
import "../libraries/SafeMath.sol";
import "../upgradeability/EternalStorage.sol";


contract BaseBridgeValidators is EternalStorage, Ownable {
    using SafeMath for uint256;

    address public constant F_ADDR = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    event RequiredSignaturesChanged (uint256 requiredSignatures);

    function setRequiredSignatures(uint256 _requiredSignatures)
    external
    onlyOwner
    {
        require(validatorCount() >= _requiredSignatures);
        require(_requiredSignatures != 0);
        uintStorage[keccak256(abi.encodePacked("requiredSignatures"))] = _requiredSignatures;
        emit RequiredSignaturesChanged(_requiredSignatures);
    }

    function getBridgeValidatorsInterfacesVersion()
    public
    pure
    returns (uint64 major, uint64 minor, uint64 patch)
    {
        return (2, 1, 0);
    }

    function _addValidator(address _validator) internal {
        require(_validator != address(0) && _validator != F_ADDR);
        require(!isValidator(_validator));

        address firstValidator = getNextValidator(F_ADDR);
        setNextValidator(_validator, firstValidator);
        setNextValidator(F_ADDR, _validator);
        setValidatorCount(validatorCount().add(1));
    }

    function _removeValidator(address _validator) internal {
        require(validatorCount() > requiredSignatures());
        require(isValidator(_validator));
        address validatorsNext = getNextValidator(_validator);
        address index = F_ADDR;
        address next = getNextValidator(index);

        while (next != _validator) {
            index = next;
            next = getNextValidator(index);

            if (next == F_ADDR || next == address(0) ) {
                revert();
            }
        }

        setNextValidator(index, validatorsNext);
        deleteItemFromAddressStorage("validatorsList", _validator);
        setValidatorCount(validatorCount().sub(1));
    }

    function requiredSignatures() public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("requiredSignatures"))];
    }

    function validatorCount() public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("validatorCount"))];
    }

    function isValidator(address _validator) public view returns (bool) {
        return _validator != F_ADDR && getNextValidator(_validator) != address(0);
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("isInitialized"))];
    }

    function deployedAtBlock() public view returns (uint256) {
        return uintStorage[keccak256("deployedAtBlock")];
    }

    function getNextValidator(address _address) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("validatorsList", _address))];
    }

    function deleteItemFromAddressStorage(string _mapName, address _address) internal {
        delete addressStorage[keccak256(abi.encodePacked(_mapName, _address))];
    }

    function setValidatorCount(uint256 _validatorCount) internal {
        uintStorage[keccak256(abi.encodePacked("validatorCount"))] = _validatorCount;
    }

    function setNextValidator(address _prevValidator, address _validator) internal {
        addressStorage[keccak256(abi.encodePacked("validatorsList", _prevValidator))] = _validator;
    }

    function setInitialize(bool _status) internal {
        boolStorage[keccak256(abi.encodePacked("isInitialized"))] = _status;
    }
}
