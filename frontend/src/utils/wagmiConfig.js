import { createConfig, configureChains } from 'wagmi';
import { publicProvider } from 'wagmi/providers/public';
import { alchemyProvider } from 'wagmi/providers/alchemy';
import { arbitrum, arbitrumSepolia, hardhat } from 'wagmi/chains';
import { connectorsForWallets } from 'connectkit';
import {
  metaMaskWallet,
  coinbaseWallet,
  walletConnectWallet,
  injectedWallet
} from 'connectkit/wallets';

// 自定義HashKey Chain配置
const hashkeyChain = {
  id: 1506,
  name: 'HashKey Chain',
  network: 'hashkey',
  nativeCurrency: {
    name: 'HashKey Token',
    symbol: 'HSK',
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ['https://rpc-mainnet.hashkey.com'],
    },
    public: {
      http: ['https://rpc-mainnet.hashkey.com'],
    },
  },
  blockExplorers: {
    default: {
      name: 'HashKey Explorer',
      url: 'https://explorer.hashkey.com',
    },
  },
  testnet: false,
};

// 配置支持的鏈和提供商
const { chains, publicClient, webSocketPublicClient } = configureChains(
  [arbitrumSepolia, arbitrum, hardhat, hashkeyChain],
  [
    alchemyProvider({ apiKey: process.env.ALCHEMY_API_KEY || 'demo' }),
    publicProvider()
  ]
);

// 配置連接器
const connectors = connectorsForWallets([
  {
    groupName: '推薦',
    wallets: [
      metaMaskWallet({ chains }),
      coinbaseWallet({ chains }),
      walletConnectWallet({ chains }),
      injectedWallet({ chains }),
    ],
  },
]);

// 創建Wagmi配置
export const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
  webSocketPublicClient,
});

export { chains };
