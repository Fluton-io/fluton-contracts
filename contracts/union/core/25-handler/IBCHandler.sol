pragma solidity ^0.8.23;

import "../24-host/IBCHost.sol";
import "./IBCClientHandler.sol";
import "./IBCConnectionHandler.sol";
import "./IBCChannelHandler.sol";
import "./IBCPacketHandler.sol";
import "./IBCQuerier.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev IBCHandler is a contract that implements [ICS-25](https://github.com/cosmos/ibc/tree/main/spec/core/ics-025-handler-interface).
 */
abstract contract IBCHandler is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IBCHost,
    IBCClientHandler,
    IBCConnectionHandler,
    IBCChannelHandler,
    IBCPacketHandler,
    IBCQuerier
{
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev The arguments of constructor must satisfy the followings:
     * @param _ibcClient is the address of a contract that implements `IIBCClient`.
     * @param _ibcConnection is the address of a contract that implements `IIBCConnectionHandshake`.
     * @param _ibcChannel is the address of a contract that implements `IIBCChannelHandshake`.
     * @param _ibcPacket is the address of a contract that implements `IIBCPacket`.
     */
    function initialize(
        address _ibcClient,
        address _ibcConnection,
        address _ibcChannel,
        address _ibcPacket,
        address admin
    ) public virtual initializer {
        __Ownable_init(admin);
        __UUPSUpgradeable_init();
        ibcClient = _ibcClient;
        ibcConnection = _ibcConnection;
        ibcChannel = _ibcChannel;
        ibcPacket = _ibcPacket;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function upgradeImpls(
        address _ibcClient,
        address _ibcConnection,
        address _ibcChannel,
        address _ibcPacket
    ) public onlyOwner {
        ibcClient = _ibcClient;
        ibcConnection = _ibcConnection;
        ibcChannel = _ibcChannel;
        ibcPacket = _ibcPacket;
    }
}
