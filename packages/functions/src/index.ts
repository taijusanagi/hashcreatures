import * as functions from "firebase-functions";
import { ethers } from "ethers";

import network from "./network.json";
import { abi } from "./HashCreature_v1.json";

const createClient = require("ipfs-http-client");

//this endpoint is too slow
export const ipfs = createClient({
  host: "ipfs.infura.io",
  port: 5001,
  protocol: "https",
});

export const helloWorld = functions.https.onRequest(async (request, response) => {
  const chainId = "4";


  const { contractAddress, rpc } = network[chainId];
  const provider = new ethers.providers.JsonRpcProvider(rpc);
  const contract = new ethers.Contract(contractAddress, abi, provider);
  const filter = contract.filters.Transfer()
// {
//   address: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
//   topics: [
//     '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
//     '0x0000000000000000000000008ba1f109551bd432803012645ac136ddd64dba72'
//   ]
// }
  const events = await contract.queryFilter(filter);
  for(const event of events){
    const metadata = await contract.getMetaData(event.args!.tokenId);
    const url = await contract.tokenURI(event.args!.tokenId);
    console.log(url)
    console.log(metadata);
    const cid = await ipfs.add(Buffer.from(metadata));
    console.log(cid)

  }
  response.send("Hello from Firebase!");
});
