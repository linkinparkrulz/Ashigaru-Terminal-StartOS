import { compat, types as T } from "../deps.ts";

export interface AshigaruConfig extends T.Config {
  network?: {
    type?: "mainnet" | "testnet" | string;
  };
  server?: {
    type?: "fulcrum" | "public" | string;
  };
  proxy?: {
    type?: "tor" | "none" | string;
  };
}

// deno-lint-ignore require-await
export const setConfig: T.ExpectedExports.setConfig = async (
  effects: T.Effects,
  newConfig: AshigaruConfig,
) => {
  const netTypeRaw = newConfig?.network?.type;
  const srvTypeRaw = newConfig?.server?.type;
  const proxyTypeRaw = newConfig?.proxy?.type;

  const validNetworks = ["mainnet", "testnet"];
  const validServers = ["fulcrum", "public"];
  const validProxies = ["tor", "none"];

  const netType = (netTypeRaw ?? "mainnet").toString().trim().toLowerCase();
  const srvType = (srvTypeRaw ?? "fulcrum").toString().trim().toLowerCase();
  const proxyType = (proxyTypeRaw ?? "tor").toString().trim().toLowerCase();

  if (!validNetworks.includes(netType)) {
    throw new Error("Invalid Ashigaru network type: " + netType);
  }

  if (!validServers.includes(srvType)) {
    throw new Error("Invalid Ashigaru server type: " + srvType);
  }

  if (!validProxies.includes(proxyType)) {
    throw new Error("Invalid Ashigaru proxy type: " + proxyType);
  }

  const sanitizedConfig: AshigaruConfig = {
    ...newConfig,
    network: { type: (netType as any) },
    server: { type: (srvType as any) },
    proxy: { type: (proxyType as any) },
  };

  const finalDeps: { [key: string]: string[] } = {};
  if (srvType === "fulcrum") {
    finalDeps.fulcrum = ["synced"];
  }

  const result = await compat.setConfig(effects, sanitizedConfig, finalDeps);
  return result;
};
