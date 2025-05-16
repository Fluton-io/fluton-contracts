import { task } from "hardhat/config";
import openChannel from "../scripts/private/_openChannel";

const openChannelTask = task("openChannel", "Opens channel between sourceContract and targetContract")
  .addPositionalParam("sourceNetwork")
  .addPositionalParam("targetNetwork")
  .addPositionalParam("sourceContractAddress")
  .addPositionalParam("targetContractAddress")
  .setAction(async ({ sourceNetwork, targetNetwork, sourceContractAddress, targetContractAddress }, hre) => {
    const sourceNetworkId = hre.config.networks[sourceNetwork].chainId;
    const targetNetworkId = hre.config.networks[targetNetwork].chainId;

    if (!sourceNetworkId || !targetNetworkId) {
      throw new Error("Networks not found");
    }

    await openChannel({ sourceNetworkId, targetNetworkId, sourceContractAddress, targetContractAddress }, hre);
  });

export default openChannelTask;
