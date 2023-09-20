// import Image from "next/image";
"use client";
import { useState } from "react";
import { BrowserProvider } from "ethers"; // a newer of importing, from ethers v6.0 and next ^13
// import dynamic from "next/dynamic";

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
        setSigner(provider.getSigner());
        setProvider(provider);
        // signer = provider.getSigner();
      } catch (e) {
        console.log(e);
      }
    } else {
      setIsConnected(false);
    }
  }
  // async function connect() {
  //   if (typeof window.ethereum !== "undefined") {
  //     try {
  //       await ethereum.request({ method: "eth_requestAccounts" });
  //       setIsConnected(true);
  //       const provider = new ethers.providers.Web3Provider(window.ethereum);
  //       setSigner(provider.getSigner());
  //     } catch (e) {
  //       console.log(e);
  //     }
  //   } else {
  //     setIsConnected(false);
  //   }
  // }

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
      </div>
    </main>
  );
}
