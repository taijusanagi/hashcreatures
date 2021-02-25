import { ethers } from "hardhat";

const main = async () => {
  const HashCreature = await ethers.getContractFactory("HashCreature");
  const hashCreature = await HashCreature.deploy("HashCreature", "HC");
  console.log("HashCreature deployed to:", hashCreature.address);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
