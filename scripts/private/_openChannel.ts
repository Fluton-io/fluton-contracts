import { HardhatRuntimeEnvironment } from "hardhat/types";
import addresses from "../../config/union";

const channel_state_init = 1
const channel_order_unordered = 1
const channel_connection = "connection-5"
const channel_connection_arb = "connection-0"

interface OpenChannelParams {
  sourceNetworkId: number;
  targetNetworkId: number;
  sourceContractAddress: string;
  targetContractAddress: string;
}

async function openChannel(
  { sourceNetworkId, targetNetworkId, sourceContractAddress, targetContractAddress }: OpenChannelParams,
  hre: HardhatRuntimeEnvironment
) {
  const ibcHandlerAddress = addresses[sourceNetworkId].IBCHandler;

  if (!ibcHandlerAddress) {
    throw new Error("Missing addresses");
  }

  const ibcHandlerContract = await hre.viem.getContractAt("IBCHandler", ibcHandlerAddress);

  // @ts-expect-error - Currently, old version of IBC handler contract is deployed. Delete this when new version is deployed.
  const asd = await ibcHandlerContract.write.channelOpenInit(["{}", (channel_state_init, channel_order_unordered, (`wasm.`))]);

  console.log(`Opening channel from ${sourceNetworkId} to ${targetNetworkId}`);
}

export default openChannel;
