import { task } from "hardhat/config";
import deploy from "../scripts/private/_deploy";

const deployTask = task("deploy", "Deploys BridgeTest contract")
  .addPositionalParam("sourceNetwork")
  .setAction(async ({ sourceNetwork }, hre) => {
    const chainId = hre.config.networks[sourceNetwork]?.chainId;

    if (!chainId) {
      throw new Error("Source network not found");
    }

    await hre.switchNetwork(sourceNetwork);

    const address = await deploy({ networkId: chainId }, hre);

    return address;
  });

export default deployTask;
