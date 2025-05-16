import type { HardhatUserConfig } from "hardhat/config";
import dotenv from "dotenv";
import "@nomicfoundation/hardhat-viem";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-verify";
import "hardhat-switch-network";

// tasks
import "./tasks";

dotenv.config();

if (
  !process.env.PRIVATE_KEY_1 ||
  !process.env.ETHERSCAN_API_KEY ||
  !process.env.SCROLLSCAN_API_KEY ||
  !process.env.BASESCAN_API_KEY ||
  !process.env.OPSCAN_API_KEY ||
  !process.env.ARBISCAN_API_KEY
) {
  throw new Error("Missing environment variables.");
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  defaultNetwork: "sepolia",
  networks: {
    sepolia: {
      url: "https://rpc.sepolia.org",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 11155111,
    },
    baseTestnet: {
      url: "https://sepolia.base.org",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 84532,
    },
    optimismTestnet: {
      url: "https://sepolia.optimism.io",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 11155420,
    },
    arbitrumTestnet: {
      url: "https://arbitrum-sepolia.blockpi.network/v1/rpc/public",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 421614,
    },
    scrollTestnet: {
      url: "https://sepolia-rpc.scroll.io",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 534351,
    },

    mainnet: {
      url: "https://eth.llamarpc.com",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 1,
    },
    baseMainnet: {
      url: "https://base.llamarpc.com",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 8453,
    },
    optimismMainnet: {
      url: "https://optimism.llamarpc.com",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 10,
    },
    arbitrumMainnet: {
      url: "https://arbitrum.llamarpc.com",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 42161,
    },
    scrollMainnet: {
      url: "https://rpc.scroll.io",
      accounts: [process.env.PRIVATE_KEY_1],
      chainId: 534352,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY,
      baseTestnet: process.env.BASESCAN_API_KEY,
      optimismTestnet: process.env.OPSCAN_API_KEY,
      arbitrumTestnet: process.env.ARBISCAN_API_KEY,
      scrollTestnet: process.env.SCROLLSCAN_API_KEY,
      mainnet: process.env.ETHERSCAN_API_KEY,
      baseMainnet: process.env.BASESCAN_API_KEY,
      optimismMainnet: process.env.OPSCAN_API_KEY,
      arbitrumMainnet: process.env.ARBISCAN_API_KEY,
      scrollMainnet: process.env.SCROLLSCAN_API_KEY,
    },
    customChains: [
      {
        network: "arbitrumTestnet",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://sepolia.arbiscan.io/",
        },
      },
      {
        network: "scrollTestnet",
        chainId: 534351,
        urls: {
          apiURL: "https://api-sepolia.scrollscan.com/api",
          browserURL: "https://sepolia.scrollscan.com/",
        },
      },
    ],
  },
};

export default config;
