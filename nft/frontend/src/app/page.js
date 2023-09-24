// import Image from "next/image";
"use client";
import { useState } from "react";
import { BrowserProvider, Contract } from "ethers"; // a newer of importing, from ethers v6.0 and next ^13
// import { ethers } from "ethers";
import { abi } from "./abi.js";
// Maybe you could do away with these two lines and do the vanilla route. Try and see.
// import dynamic from "next/dynamic";
// const DynamicAbi = dynamic(() => import("./abi.js").then((mod) => mod.abi));

// const DynamicComponentWithNoSSR = dynamic(
//   () => import("../components/YourComponent"),
//   {
//     ssr: false,
//   }
// );

export default function Home() {
  const [isConnected, setIsConnected] = useState(false);
  const [provider, setProvider] = useState();
  const [signer, setSigner] = useState();

  async function connect() {
    if (typeof window.ethereum != "undefined") {
      try {
        await ethereum.request({ method: "eth_requestAccounts" });
        setIsConnected(true);
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
  async function execute() {
    if (typeof window.ethereum !== "undefined") {
      const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
      setProvider(provider);
      setSigner(await provider.getSigner());

      console.log("Provider:", provider);
      console.log("Signer: ", signer);
      // console.log("AbI:");
      // console.log(abi);

      // let provider = new BrowserProvider(window.ethereum);
      // let signer = await provider.getSigner();
      const contract = new Contract(contractAddress, abi, signer);

      // signer = await ethers.provider.getSigner();

      try {
        // const contractValue = await contract.getHappySvgUri();
        // const stringValue = toUtf8String(contractValue);
        // const base64Decoded = decodeBase64(contractValue);
        // console.log("Contract Value: ", base64Decoded);
        // console.log(contractValue);
        await contract.mint();
        // const decoded = decodeBase64("EjQ=");
        // console.log("Contract Value: ", stringValue);
      } catch (e) {
        console.log(e);
      }
    } else {
      console.log("Please Install Metamask!");
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      {/* <DynamicComponentWithNoSSR /> */}
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        Hello React!
        {isConnected ? (
          "Connected!"
        ) : (
          <button onClick={() => connect()}>Connect</button>
        )}
        {isConnected ? (
          <button onClick={() => execute()}>Contract Interaction</button>
        ) : (
          ""
        )}
      </div>
    </main>
  );
}
