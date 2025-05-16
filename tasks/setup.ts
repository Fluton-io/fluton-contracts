import { task } from "hardhat/config";

const setupTask = task(
  "setup",
  "Deploys BridgeTest contract on sourceNetwork and targetNetwork and establishes a connection between them with Union infrastructure"
)
  .addPositionalParam("sourceNetwork", "example: sepolia")
  .addPositionalParam("targetNetwork", "example: scrollSepolia")
  .setAction(async ({ sourceNetwork, targetNetwork }, hre) => {
    const bridgeTestSourceAddress = await hre.run("deploy", {
      sourceNetwork: sourceNetwork,
    });

    console.log(`BridgeTest deployed to: ${bridgeTestSourceAddress}`);
  });

export default setupTask;
