import { ethers } from "hardhat";
import * as chai from "chai";
import { solidity } from "ethereum-waffle";

import * as ipfsHash from "ipfs-only-hash";

chai.use(solidity);
const { expect } = chai;

describe("HashCreature_v1", function () {
  let hashCreature;
  const contractName = "HashCreature_v1";
  const contractSymbol = "HC1";
  const maxSupply = 10000;
  this.beforeAll("initialization.", async function () {
    const HashCreature = await ethers.getContractFactory("HashCreature_v1");
    hashCreature = await HashCreature.deploy(
      contractName,
      contractSymbol,
      maxSupply
    );
  });

  it("case: deploy is ok / check: name, symbol", async function () {
    expect(await hashCreature.name()).to.equal(contractName);
    expect(await hashCreature.symbol()).to.equal(contractSymbol);
    expect(await hashCreature.maxSupply()).to.equal(maxSupply);
  });

  it("case: mint is ok / check: tokenURI", async function () {
    const tokenId = "1";
    const name = "name";
    const baseIpfsUrl = "ipfs://";
    const contractAddress = hashCreature.address.toLowerCase();
    const [signer] = await ethers.getSigners();
    const iss = signer.address.toLowerCase();
    const nameBytes32 = ethers.utils.formatBytes32String(name);
    await hashCreature.mint(nameBytes32);

    expect(await hashCreature.nameMemory(tokenId)).to.equal(nameBytes32);

    const chainId = await hashCreature.getChainId();
    const blockNumber = await hashCreature.blockNumberMemory(tokenId);
    const lastBlockHash = await hashCreature.lastBlockHashMemory(tokenId);

    const hash = ethers.utils.solidityKeccak256(
      [
        "uint256",
        "bytes32",
        "uint256",
        "address",
        "uint256",
        "address",
        "bytes32",
      ],
      [
        blockNumber,
        lastBlockHash,
        chainId,
        contractAddress,
        tokenId,
        iss,
        nameBytes32,
      ]
    );
    expect(await hashCreature.getSeedHash(tokenId)).to.equal(hash);

    //SVG Image generation logic goes here
    const image_data = await hashCreature.getImageData(hash);

    const metadata = JSON.stringify({
      blockNumber: blockNumber.toString(),
      lastBlockHash,
      chainId: chainId.toString(),
      contractAddress,
      tokenId,
      iss,
      name,
      image_data,
    });

    expect(await hashCreature.getMetaData(tokenId)).to.equal(metadata);

    const metadataBuffer = Buffer.from(metadata);
    const cid = await ipfsHash.of(metadataBuffer);

    expect(await hashCreature.getCidFromString(metadata)).to.equal(cid);
    expect(await hashCreature.tokenURI(tokenId)).to.equal(
      `${baseIpfsUrl}${cid}`
    );
  });
});
