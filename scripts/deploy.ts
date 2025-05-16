import hre from "hardhat";
import deploy from "./private/_deploy";

async function main() {
  const networkId = hre.network.config.chainId!;
  await deploy({ networkId }, hre);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
