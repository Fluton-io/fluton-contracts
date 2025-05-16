import tokens from "../../config/tokens";
import addresses from "../../config/union";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function deploy({ networkId }: { networkId: number }, hre: HardhatRuntimeEnvironment) {
  const wrappedNativeTokenAddress = tokens[networkId].find((t) => t.symbol === "WETH")?.address;
  const ibcHandlerAddress = addresses[networkId].IBCHandler;
  const timeoutInSeconds = 60 * 60 * 24 * 7; // 7 days

  if (!wrappedNativeTokenAddress || !ibcHandlerAddress) {
    throw new Error("Missing addresses");
  }

  const contract = await hre.viem.deployContract("BridgeTest", [
    wrappedNativeTokenAddress,
    ibcHandlerAddress,
    timeoutInSeconds,
  ]);

  await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [wrappedNativeTokenAddress, ibcHandlerAddress, timeoutInSeconds],
  });

  const networkName = Object.keys(hre.config.networks).find((key) => hre.config.networks[key].chainId === networkId);

  console.log(`BridgeTest deployed to: ${contract.address} on network: ${networkName}`);

  return contract.address;
}

export default deploy;
