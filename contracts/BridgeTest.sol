// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@uniswap/universal-router/contracts/interfaces/external/IWETH9.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ZkgmLib.sol";

/**
 * @title BridgeTest
 * @notice Test contract for cross-chain message bridging; not for production use.
 */
contract BridgeTest is Ownable {
    using ZkgmLib for *;

    /*///////////////////////////////////////////////////////////////
                              STRUCTS & ENUMS
    //////////////////////////////////////////////////////////////*/

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

    struct IBCPacket {
        uint32 sourceChannelId;
        uint32 destinationChannelId;
        bytes data;
        uint64 timeoutHeight;
        uint64 timeoutTimestamp;
    }

    /*///////////////////////////////////////////////////////////////
                              STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IWETH9 public immutable WETH;
    uint256 public fee = 100; // 1% in basis points
    address public feeReceiver;
    address public ibcHandler;

    mapping(uint256 => Intent) public pendingIntents;
    mapping(bytes32 => bool) public validPaths;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event IntentCreated(Intent intent);
    event IntentFulfilled(Intent intent);
    event IntentRepaid(Intent intent);
    event IntentTimedOut(uint256 intentId);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MsgValueDoesNotMatchInputAmount();
    error UnauthorizedRelayer();

    /*///////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyIBC() {
        if (msg.sender != ibcHandler) revert ZkgmLib.ErrNotIBC();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param _wrappedNativeToken Address of WETH9 token
    /// @param _ibcHandler Address of the IBC handler contract
    constructor(
        IWETH9 _wrappedNativeToken,
        address _ibcHandler
    ) Ownable(msg.sender) {
        WETH = _wrappedNativeToken;
        ibcHandler = _ibcHandler;
        feeReceiver = 0xBdc3f1A02e56CD349d10bA8D2B038F774ae22731;
    }

    /*///////////////////////////////////////////////////////////////
                         OWNER-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a valid path mapping between a source contract and a destination contract
    function addValidPath(
        bytes calldata sourceContract,
        bytes calldata destContract
    ) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(sourceContract, destContract));
        validPaths[key] = true;
    }

    /// @notice Remove an existing valid path mapping between a source contract and a destination contract
    function removeValidPath(
        bytes calldata sourceContract,
        bytes calldata destContract
    ) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(sourceContract, destContract));
        delete validPaths[key];
    }

    /// @notice Adjust the bridging fee (in basis points)
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /// @notice Change the fee recipient address
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    /*///////////////////////////////////////////////////////////////
                            CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a bridge intent and lock funds
     * @param sender Address initiating the bridge
     * @param receiver Address on destination chain
     * @param relayer Relayer address authorized to fulfill
     * @param inputToken Token to lock
     * @param outputToken Token to release on destination
     * @param inputAmount Amount to lock
     * @param outputAmount Amount to release
     * @param destinationChainId Destination Chain ID
     */
    function bridge(
        address sender,
        address receiver,
        address relayer,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint32 destinationChainId
    ) external payable {
        uint256 id = uint256(
            keccak256(
                abi.encodePacked(
                    sender,
                    receiver,
                    relayer,
                    inputToken,
                    outputToken,
                    inputAmount,
                    outputAmount,
                    destinationChainId,
                    block.timestamp
                )
            )
        );

        Intent memory intent = Intent({
            sender: sender,
            receiver: receiver,
            relayer: relayer,
            inputToken: inputToken,
            outputToken: outputToken,
            inputAmount: inputAmount,
            outputAmount: outputAmount,
            id: id,
            originChainId: uint32(block.chainid),
            destinationChainId: destinationChainId,
            filledStatus: FilledStatus.NOT_FILLED
        });

        if (intent.inputToken == address(WETH)) {
            if (msg.value != intent.inputAmount)
                revert MsgValueDoesNotMatchInputAmount();
            WETH.deposit{value: msg.value}();
        } else {
            IERC20(intent.inputToken).transferFrom(
                msg.sender,
                address(this),
                intent.inputAmount
            );
        }

        pendingIntents[id] = intent;
        emit IntentCreated(intent);
    }

    /**
     * @notice Locks a user’s base tokens and sends a 0x03 – FungibleAssetOrder packet via Union ZKGM
     * @param receiver        Address on the destination chain that will receive the output
     * @param baseToken       Address of the token to lock on this chain
     * @param baseAmount      Amount of baseToken to lock
     * @param baseSymbol      Symbol of the base token (for wrapped-token metadata)
     * @param baseName        Name of the base token (for wrapped-token metadata)
     * @param baseDecimals    Decimals of the base token (for wrapped-token metadata)
     * @param quoteToken      Identifier of the token requested on the destination chain (as bytes)
     * @param quoteAmount     Minimum amount of quoteToken requested
     * @param channelID  IBC channel ID / target chain identifier
     */
    function bridgeAssetOrder(
        address receiver,
        address baseToken,
        uint256 baseAmount,
        string calldata baseSymbol,
        string calldata baseName,
        uint8 baseDecimals,
        uint256 baseTokenPath,
        bytes calldata quoteToken,
        uint256 quoteAmount,
        uint32 channelID,
        bytes calldata targetContract
    ) external payable {
        ZkgmLib.FungibleAssetOrder memory order = ZkgmLib.FungibleAssetOrder({
            sender: abi.encodePacked(msg.sender),
            receiver: abi.encodePacked(receiver),
            baseToken: abi.encodePacked(baseToken),
            baseAmount: baseAmount,
            baseTokenSymbol: baseSymbol,
            baseTokenName: baseName,
            baseTokenDecimals: baseDecimals,
            baseTokenPath: baseTokenPath,
            quoteToken: quoteToken,
            quoteAmount: quoteAmount
        });

        IERC20(baseToken).approve(ZkgmLib.ZKGM_ADDRESS, baseAmount);

        ZkgmLib.sendZkgmAssetOrder(channelID, targetContract, order);
    }

    /**
     * @notice Relayer fulfills the intent and sends cross-chain message
     * @param intent Data describing the bridge intent
     * @param channelId IBC channel identifier
     */
    function fulfill(
        Intent calldata intent,
        uint32 channelId,
        bytes calldata targetContract
    ) external payable {
        if (msg.sender != intent.relayer) revert UnauthorizedRelayer();

        if (intent.outputToken == address(WETH)) {
            // Aşağıdaki gibi yapıyoruz:
            _sendWETH(intent.receiver, intent.outputAmount);
        } else {
            IERC20(intent.outputToken).transferFrom(
                intent.relayer,
                intent.receiver,
                intent.outputAmount
            );
        }

        emit IntentFulfilled(intent);
        ZkgmLib.sendZkgmMessage(channelId, targetContract, intent.id);
    }

    /**
     * @notice Relayer fulfills multiple intents atomically and sends a batch cross-chain message
     */
    function fulfillBatch(
        Intent[] calldata intents,
        uint32 channelId,
        bytes calldata targetContract
    ) external payable {
        uint256 len = intents.length;
        require(len > 1, "Batch requires at least 2 intents");

        IZkgm.Instruction[] memory instrs = new IZkgm.Instruction[](len);
        for (uint256 i; i < len; ++i) {
            Intent calldata intent = intents[i];
            if (msg.sender != intent.relayer) revert UnauthorizedRelayer();

            if (intent.outputToken == address(WETH)) {
                _sendWETH(intent.receiver, intent.outputAmount);
            } else {
                IERC20(intent.outputToken).transferFrom(
                    intent.relayer,
                    intent.receiver,
                    intent.outputAmount
                );
            }

            emit IntentFulfilled(intent);

            ZkgmLib.Multiplex memory mux = ZkgmLib.Multiplex({
                sender: abi.encodePacked(address(this)),
                eureka: true,
                contractAddress: targetContract,
                contractCalldata: abi.encode(intent.id)
            });

            bytes memory data = ZkgmLib.encodeMultiplex(mux);

            instrs[i] = IZkgm.Instruction({
                version: ZkgmLib.ZKGM_VERSION_0,
                opcode: ZkgmLib.OP_MULTIPLEX,
                operand: data
            });
        }

        ZkgmLib.sendZkgmBatch(channelId, targetContract, instrs);
    }

    /**
     * @notice Handles incoming IBC packets for repayment
     */
    function onRecvPacket(
        address /*caller*/,
        IBCPacket calldata packet,
        address /*relayer*/,
        bytes calldata /*relayerMsg*/
    ) external onlyIBC returns (bytes memory) {
        (, bytes memory senderBytes, bytes memory messageData) = abi.decode(
            packet.data,
            (uint256, bytes, bytes)
        );

        bytes32 pathKey = keccak256(abi.encodePacked(abi.encode(address(this)), senderBytes));

        if (!validPaths[pathKey]) {
            revert ZkgmLib.ErrInvalidMultiplexSender();
        }

        uint256 intentId = abi.decode(messageData, (uint256));
        Intent storage intent = pendingIntents[intentId];
        if (intent.sender == address(0)) {
            return abi.encode(ZkgmLib.ACK_FAILURE);
        }

        _repay(intent);
        delete pendingIntents[intentId];
        return abi.encode(ZkgmLib.ACK_SUCCESS);
    }

    function onTimeoutPacket(
        address /*caller*/,
        IBCPacket calldata packet,
        address /*relayer*/,
    ) external onlyIBC returns (bytes memory) {
        (, bytes memory senderBytes, bytes memory messageData) = abi.decode(
            packet.data,
            (uint256, bytes, bytes)
        );

        uint256 intentId = abi.decode(messageData, (uint256));
        
        emit IntentTimedOut(intentId);
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _sendWETH(address to, uint256 amount) internal {
        // unwrap and transfer
        WETH.withdraw(amount);
        payable(to).transfer(amount);
    }

    function _repay(Intent memory intent) internal {
        uint256 feeAmount = (intent.inputAmount * fee) / 10000;
        uint256 repayAmount = intent.inputAmount - feeAmount;

        if (intent.inputToken == address(WETH)) {
            _sendWETH(intent.relayer, repayAmount);
            if (feeAmount > 0) {
                _sendWETH(feeReceiver, feeAmount);
            }
        } else {
            IERC20(intent.inputToken).transfer(intent.relayer, repayAmount);
            if (feeAmount > 0) {
                IERC20(intent.inputToken).transfer(feeReceiver, feeAmount);
            }
        }

        emit IntentRepaid(intent);
    }

    /*///////////////////////////////////////////////////////////////
                           FALLBACK RECEIVER
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}
}
