// frontend/app/page.tsx
"use client";

import { useEffect, useState } from "react";
import { getTopMeritWallets, getCirculatingSupply } from "./apiClient";

interface Wallet {
  wallet_id: string;
  merit: number;
}

export default function HomePage() {
  const [topWallets, setTopWallets] = useState<Wallet[]>([]);
  const [circulatingSupply, setCirculatingSupply] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);
        const wallets = await getTopMeritWallets();
        const supply = await getCirculatingSupply();
        setTopWallets(wallets);
        setCirculatingSupply(supply.total);
      } catch (err: any) {
        setError(err.message || "Erreur inconnue");
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  if (loading) return <p className="p-4 text-lg">Chargement...</p>;
  if (error) return <p className="p-4 text-red-600">Erreur: {error}</p>;

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-3xl font-bold mb-4">OmniUtil Dashboard</h1>
      <p className="mb-6">Circulating Supply MERIT: {circulatingSupply.toLocaleString()}</p>

      <h2 className="text-2xl font-semibold mb-2">Top 10 MERIT Wallets</h2>
      <ul className="list-disc pl-5">
        {topWallets.map((wallet, index) => (
          <li key={wallet.wallet_id}>
            #{index + 1} – ID: {wallet.wallet_id}, MERIT: {wallet.merit.toLocaleString()}
          </li>
        ))}
      </ul>
    </div>
  );
}
