// THIS IS DUMMY!
// DELETE IT ENTIRELY!

"use client";
import { useState } from "react";
import { BrowserProvider } from "ethers";

export default function Home() {
  const [isConnected, setIsConnected] = useState(false);
  const [provider, setProvider] = useState();

  async function connect() {
    if (typeof window.ethereum !== "undefined") {
      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        setIsConnected(true);
        const ethersProvider = new BrowserProvider(window.ethereum);
        setProvider(ethersProvider);
      } catch (e) {
        console.log(e);
      }
    } else {
      setIsConnected(false);
    }
  }

  // Rest of your component code...

  return (
    <div>
      <button onClick={connect}>Connect to MetaMask</button>
      {/* Rest of your component UI */}
    </div>
  );
}
