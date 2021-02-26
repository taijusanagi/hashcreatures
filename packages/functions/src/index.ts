import * as functions from "firebase-functions";
import { ethers } from "ethers";

import network from "./network.json";
import { abi } from "./HashCreature_v1.json";

const createClient = require("ipfs-http-client");

// this endpoint is too slow
export const ipfs = createClient({
  host: "ipfs.infura.io",
  port: 5001,
  protocol: "https",
});

module.exports = functions
  .region("asia-northeast1")
  .pubsub.schedule("every 5 minutes")
  .onRun(async () => {
    const chainId = "4";
    const { contractAddress, rpc } = network[chainId];
    const provider = new ethers.providers.JsonRpcProvider(rpc);
    const contract = new ethers.Contract(contractAddress, abi, provider);
    const filter = contract.filters.Transfer() as any;
    const events = await contract.queryFilter(
      filter,
      await provider.getBlockNumber().then((b) => b - 30),
      "latest"
    );
    console.log(events.length);
    const processedToken = [] as string[];
    for (var i = events.length - 1; i >= 0; i--) {
      const { tokenId, to } = events[i].args!;
      const tokenIdString = tokenId.toString();
      if (!processedToken.find((tokenId) => tokenId === tokenIdString)) {
        if (to !== "0x0000000000000000000000000000000000000000") {
          const metadata = await contract.getMetaData(tokenId);
          const cid = await ipfs.add(Buffer.from(metadata));
          console.log(cid);
        }
        processedToken.push(tokenIdString);
      }
    }
  });
