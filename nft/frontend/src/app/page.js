// import Image from "next/image";
"use client";
import { useState } from "react";
import { BrowserProvider, Contract } from "ethers"; // a newer of importing, from ethers v6.0 and next ^13
// import { ethers } from "ethers";
import { abi } from "./abi.js";
import { styled } from "styled-components";

export default function Home() {
  const [isConnected, setIsConnected] = useState(false);
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();

  // sort of coping from bing ai. Works, but ugly and with warnings
  const Button = styled.button`
    background-color: green;
    color: white;
  `;

  async function connect() {
    if (typeof window.ethereum != "undefined") {
      try {
        await ethereum.request({ method: "eth_requestAccounts" });
        setIsConnected(true);
        // this 'provider' is a different variable than the 'const provider'
        let provider = new BrowserProvider(window.ethereum);
        setSigner(await provider.getSigner());
        setProvider(provider);
        // signer = provider.getSigner();
      } catch (e) {
        console.log(e);
      }
    } else {
      setIsConnected(false);
    }
  }
  async function callContract() {
    if (typeof window.ethereum !== "undefined") {
      const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
      // setProvider(provider);
      // setSigner(await provider.getSigner());

      console.log("Provider:", provider);
      console.log("Signer: ", signer);
      // console.log("AbI:");
      // console.log(abi);

      // let provider = new BrowserProvider(window.ethereum);
      // let signer = await provider.getSigner();
      const contract = new Contract(contractAddress, abi, signer);

      // signer = await ethers.provider.getSigner();

      try {
        // Both these decoding methods are native to JavaScript, not Ethers specific
        // Get deeper into Ethers to make this more neat!

        const contractIntInHex = await contract.getTokenCounter();
        const decodedValue = parseInt(contractIntInHex);
        console.log("Parsed Int Value: ", decodedValue);

        const contractStringInHex = await contract.getHappySvgUri();
        const decodedStringValue = contractStringInHex.toString("utf8");
        console.log("Decoded String Value: ", decodedStringValue);

        // const stringValue = toUtf8String(contractValue);

        // console.log(contractValue);
        // await contract.mint();
        // const decoded = decodeBase64("EjQ=");
        // console.log("Contract Value: ", stringValue);
      } catch (e) {
        console.log(e);
      }
    } else {
      console.log("Please Install Metamask!");
    }
  }

  async function execute() {
    if (typeof window.ethereum !== "undefined") {
      const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

      console.log("Provider:", provider);
      console.log("Signer: ", signer);

      const contract = new Contract(contractAddress, abi, signer);

      try {
        await contract.mint();
      } catch (e) {
        console.log(e);
      }
    } else {
      console.log("Please Install Metamask!");
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        --- Hello React! ---
        {isConnected ? (
          "Connected!"
        ) : (
          <div>
            <button onClick={() => connect()}> Connect </button>
          </div>
        )}
        {isConnected ? (
          <Button onClick={() => callContract()}>Call Contract</Button>
        ) : (
          ""
        )}
      </div>
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        --- Contract Writing ---
        <div>
          {isConnected ? (
            <Button onClick={() => execute()}>Mint NFT</Button>
          ) : (
            ""
          )}
        </div>
      </div>
    </main>
  );
}
