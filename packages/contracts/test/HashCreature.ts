import { ethers } from "hardhat";
import * as chai from "chai";
import { solidity } from "ethereum-waffle";

import * as ipfsHash from "ipfs-only-hash";

// const createClient = require("ipfs-http-client");

//this endpoint is too slow
// export const ipfs = createClient({
//   host: "ipfs.infura.io",
//   port: 5001,
//   protocol: "https",
// });

chai.use(solidity);
const { expect } = chai;

describe("HashCreature_v1", function () {
  let hashCreature;
  const contractName = "HashCreature";
  const contractSymbol = "HC";
  const supplyLimit = "10000";
  let signer, creator;

  this.beforeAll("initialization.", async function () {
    [signer, creator] = await ethers.getSigners();
    const HashCreature = await ethers.getContractFactory("HashCreature_v1");
    hashCreature = await HashCreature.deploy(
      contractName,
      contractSymbol,
      supplyLimit,
      creator.address
    );
  });

  it("case: deploy is ok / check: name, symbol", async function () {
    expect(await hashCreature.name()).to.equal(contractName);
    expect(await hashCreature.symbol()).to.equal(contractSymbol);
    expect(await hashCreature.supplyLimit()).to.equal(supplyLimit);
    expect(await hashCreature.creator()).to.equal(creator.address);
  });

  it("case: mint is ok / check: tokenURI", async function () {
    const tokenId = "1";
    const baseIpfsUrl = "ipfs://";
    const totalSupply = hashCreature.totalSupply();
    const value = hashCreature.getPriceToMint(totalSupply);
    await hashCreature.mint({ value: value });
    const hash = await hashCreature.hashMemory(tokenId);
    const image_data = await hashCreature.getImageData(hash, 0);

    const metadata = JSON.stringify({
      image_data: image_data.split("\\").join(""),
      name: `${contractName}#${tokenId}`,
    });

    // await ipfs.add(Buffer.from(metadata));

    expect(await hashCreature.getMetaData(tokenId)).to.equal(metadata);
    const metadataBuffer = Buffer.from(metadata);
    const cid = await ipfsHash.of(metadataBuffer);
    expect(await hashCreature.getCidFromString(metadata)).to.equal(cid);
    expect(await hashCreature.tokenURI(tokenId)).to.equal(
      `${baseIpfsUrl}${cid}`
    );
  });
});
