// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IZkgm {
    struct Instruction {
        uint8 version;
        uint8 opcode;
        bytes operand;
    }
    function send(
        uint32 channelId,
        uint64 timeoutHeight,
        uint64 timeoutTimestamp,
        bytes32 salt,
        Instruction calldata instruction
    ) external;
}

/**
 * @title ZkgmLib
 * @notice Library to encode and send cross-chain messages via Zkgm protocol
 */
library ZkgmLib {
    uint8 public constant ZKGM_VERSION_0 = 0x00;
    uint8 public constant INSTR_VERSION_1 = 0x01;
    address public constant ZKGM_ADDRESS = 0x5FbE74A283f7954f10AA04C2eDf55578811aeb03;
    uint256 public constant ACK_FAILURE = 0x00;
    uint256 public constant ACK_SUCCESS = 0x01;
    uint8 public constant OP_MULTIPLEX = 0x01;
    uint8 public constant OP_BATCH = 0x02;
    uint8 public constant OP_FUNGIBLE_ASSET_ORDER = 0x03;

    error ErrNotIBC();
    error ErrInvalidMultiplexSender();

    struct Batch {
        IZkgm.Instruction[] instructions;
    }

    struct Multiplex {
        bytes sender;
        bool eureka;
        bytes contractAddress;
        bytes contractCalldata;
    }

    struct FungibleAssetOrder {
        bytes  sender;
        bytes  receiver;
        bytes  baseToken;
        uint256 baseAmount;
        string baseTokenSymbol;
        string baseTokenName;
        uint8  baseTokenDecimals;
        uint256 baseTokenPath;
        bytes  quoteToken;
        uint256 quoteAmount;
    }

    struct ZkgmPacket {
        bytes32 salt;
        uint256 path;
        IZkgm.Instruction instruction;
    }

    event MessageSent(uint256 indexed channelId, address indexed sender, string message);

    function encodeMultiplex(Multiplex memory m) internal pure returns (bytes memory) {
        return abi.encode(m.sender, m.eureka, m.contractAddress, m.contractCalldata);
    }

    /// @notice ABI-encode a batch of instructions
    function encodeBatch(IZkgm.Instruction[] memory instrs) internal pure returns (bytes memory) {
        return abi.encode(instrs);
    }

    function encodeFungibleAssetOrder(FungibleAssetOrder memory o) internal pure returns (bytes memory) {
        return abi.encode(
            o.sender,
            o.receiver,
            o.baseToken,
            o.baseAmount,
            o.baseTokenSymbol,
            o.baseTokenName,
            o.baseTokenDecimals,
            o.baseTokenPath,
            o.quoteToken,
            o.quoteAmount
        );
    }

    function bytesEqual(bytes memory a, bytes memory b) internal pure returns (bool) {
        return a.length == b.length && keccak256(a) == keccak256(b);
    }

    function sendZkgmMessage(
        uint32 channelId,
        bytes memory targetContractAddress,
        uint256 id
    ) internal {
        Multiplex memory mux = Multiplex({
            sender: abi.encodePacked(address(this)),
            eureka: true,
            contractAddress: targetContractAddress,
            contractCalldata: abi.encode(id)
        });
        bytes memory data = encodeMultiplex(mux);
        IZkgm.Instruction memory instr = IZkgm.Instruction({
            version: ZKGM_VERSION_0,
            opcode: OP_MULTIPLEX,
            operand: data
        });
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));

        try IZkgm(ZKGM_ADDRESS).send(
            channelId,
            0,
            18446744073709551500,
            salt,
            instr
        ) {
            emit MessageSent(channelId, address(bytes20(targetContractAddress)), "Message Sent");
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Zkgm send failed: ", reason)));
        } catch {
            revert("Zkgm send failed with low level error");
        }
    }

    /// @notice Send a batch instruction via Zkgm
    function sendZkgmBatch(
        uint32 channelId,
        bytes memory targetContractAddress,
        IZkgm.Instruction[] memory instrs
    ) internal {
        IZkgm.Instruction memory batchInstr = IZkgm.Instruction({
            version: ZKGM_VERSION_0,
            opcode: OP_BATCH,
            operand: encodeBatch(instrs)
        });
        _sendPacket(channelId, batchInstr, targetContractAddress, "Batch Message Sent");
    }

    /// @notice Send a single fungible-asset-order
    function sendZkgmAssetOrder(
        uint32 channelId,
        bytes memory targetContractAddress,
        FungibleAssetOrder memory order
    ) internal {
        IZkgm.Instruction memory instr = IZkgm.Instruction({
            version: INSTR_VERSION_1,
            opcode:  OP_FUNGIBLE_ASSET_ORDER,
            operand: encodeFungibleAssetOrder(order)
        });
        _sendPacket(channelId, instr, targetContractAddress, "AssetOrder Sent");
    }

    /// @dev Internal helper to dispatch a packet
    function _sendPacket(
        uint32 channelId,
        IZkgm.Instruction memory instr,
        bytes memory targetContractAddress,
        string memory successMsg
    ) private {
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp));
        try IZkgm(ZKGM_ADDRESS).send(
            channelId,
            0,
            18446744073709551500,
            salt,
            instr
        ) {
            emit MessageSent(channelId, address(bytes20(targetContractAddress)), successMsg);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Zkgm send failed: ", reason)));
        } catch {
            revert("Zkgm send failed with low level error");
        }
    }
}
