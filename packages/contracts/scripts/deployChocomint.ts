import { ethers } from "hardhat";

const main = async () => {
  const HashCreature = await ethers.getContractFactory("HashCreature_v1");
  const hashCreature = await HashCreature.deploy(
    "HashCreature",
    "HC",
    10,
    "0x64478Fc1bc6726caf1D0366dC61eF44E7bD3C1bc"
  );
  console.log("HashCreature deployed to:", hashCreature.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
