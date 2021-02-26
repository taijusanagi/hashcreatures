import React, { DialogHTMLAttributes } from "react";
import {
  getEthersSigner,
  ChainIdType,
  getNetworkConfig,
  ipfsBaseUrl,
  getContract,
} from "../modules/web3";

const bs58 = require("bs58");
const logo = require("../assets/icon.png").default;

export const Create: React.FC = () => {
  const [
    waitingTransactionConfirmation,
    setWaitingTransactionConfirmation,
  ] = React.useState(false);
  const [name, setName] = React.useState("");
  const [description, setDescription] = React.useState("");

  const readAsArrayBufferAsync = (file: File) => {
    return new Promise((resolve) => {
      const fr = new FileReader();
      fr.onload = () => {
        resolve(fr.result);
      };
      fr.readAsArrayBuffer(file);
    });
  };

  const handleNameChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setName(event.target.value);
  };

  const handleDescriptionChange = (
    event: React.ChangeEvent<HTMLTextAreaElement>
  ) => {
    setDescription(event.target.value);
  };

  const openDialog = () => {
    const dialog = document.getElementById("dialog-dark") as any;
    dialog.showModal();
  };

  const createNft = async () => {
    if (!name || !description) {
      return;
    }
    setWaitingTransactionConfirmation(true);
    const signer = await getEthersSigner();
    const chainId = await signer.getChainId();
    if (chainId != 4 && chainId != 80001) {
      alert("Please connect to Rinkeby or Matic Testnet.");
      return;
    }
    const { contractAddress } = getNetworkConfig(
      chainId.toString() as ChainIdType
    );
    const contract = getContract(contractAddress).connect(signer);
    const { hash } = await contract.mint();
    alert(`TxHash:${hash}`);
  };

  return (
    <div className="">
      <div className="">
        <div className="">
          <div className="nes-container is-dark with-title is-centered">
            <p className="title">HashCreatures</p>
            <p>
              Hi, We are fully onchain generated creatures. HashCreatures is
              generate by hash in the minting transaction. Image SVG and
              Metadata is generated only in solidity code.
            </p>
          </div>
          <div className="nes-field">
            <label htmlFor="name_field">name</label>
            <input
              onChange={handleNameChange}
              type="text"
              name="name"
              id="name"
              autoComplete="name"
              className="nes-input"
            />
          </div>
          <div className="mt-12">
            <button
              type="button"
              className="nes-btn is-success"
              onClick={openDialog}
            >
              Mint
            </button>
          </div>
        </div>
      </div>
      <section>
        <dialog className="nes-dialog is-dark" id="dialog-dark">
          <form method="dialog">
            <p className="title">Dark dialog</p>
            <p>Alert: this is a dialog.</p>
            <menu className="dialog-menu">
              <button className="nes-btn" onClick={() => console.log("cancel")}>
                Cancel
              </button>
              <button
                className="nes-btn is-primary"
                onClick={() => console.log("confirm")}
              >
                Confirm
              </button>
            </menu>
          </form>
        </dialog>
      </section>
    </div>
  );
};

export default Create;
