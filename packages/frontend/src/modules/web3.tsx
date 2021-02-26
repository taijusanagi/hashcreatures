import { ethers } from "ethers";
import Web3Modal from "web3modal";
import WalletConnectProvider from "@walletconnect/web3-provider";

import networkConfig from "../configs/network.json";
import { abi } from "../HashCreature_v1.json";

export const ipfsBaseUrl = "ipfs://";
export const ipfsHttpsBaseUrl = "https://ipfs.io/ipfs/";
export const nullAddress = "0x0000000000000000000000000000000000000000";
export type ChainIdType = "4";

export const getNetworkConfig = (chainId: ChainIdType) => {
  return networkConfig[chainId];
};

export const getChainIds = () => {
  return Object.keys(networkConfig) as ChainIdType[];
};

export const getContract = (address: string, chainId?: ChainIdType) => {
  const provider = chainId
    ? new ethers.providers.JsonRpcProvider(getNetworkConfig(chainId).rpc)
    : undefined;
  return new ethers.Contract(address, abi, provider);
};

const providerOptions = {
  walletconnect: {
    package: WalletConnectProvider, // required
    options: {
      infuraId: "95f65ab099894076814e8526f52c9149", // required
    },
  },
};

export const getEthersSigner = async () => {
  const web3Modal = new Web3Modal({ providerOptions });
  const web3ModalProvider = await web3Modal.connect();
  await web3ModalProvider.enable();
  const web3EthersProvider = new ethers.providers.Web3Provider(
    web3ModalProvider
  );
  return web3EthersProvider.getSigner();
};
