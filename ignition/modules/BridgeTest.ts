// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

// to deploy contract, run `npx hardhat ignition deploy ignition/modules/BridgeTest.ts --network sepolia --verify`

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LockModule = buildModule("BridgeTestModule", (m) => {
  const timeoutInSeconds = 60 * 60 * 24 * 7; // 7 days

  const wrappedNativeToken = m.getParameter("_wrappedNativeToken");
  const ibcHandler = m.getParameter("_ibcHandler");
  const timeout = m.getParameter("_timeout", timeoutInSeconds);

  const bridgeTest = m.contract("BridgeTest", [wrappedNativeToken, ibcHandler, timeout]);

  return { bridgeTest };
});

export default LockModule;
