pragma solidity ^0.8.27;

import "./union/apps/Base.sol";
import "./union/core/25-handler/IBCHandler.sol";

enum FilledStatus {
    NOT_FILLED,
    FILLED
}

struct Intent {
    address sender;
    address receiver;
    address relayer;
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 outputAmount;
    uint256 id;
    uint32 originChainId;
    uint32 destinationChainId;
    FilledStatus filledStatus;
}

interface BridgeTestInterface {
    // EVENTS
    event IntentFulfilled(Intent intent);
    event IntentCreated(Intent intent);
    event IntentRepaid(Intent intent);

    // FUNCTIONS
    function bridge(
        address sender,
        address receiver,
        address relayer,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint32 destinationChainId
    ) external payable;

    function fulfill(Intent calldata intent, uint32 channelId) external payable;

    // ERRORS
    error MsgValueDoesNotMatchInputAmount();
    error UnauthorizedRelayer();
}
