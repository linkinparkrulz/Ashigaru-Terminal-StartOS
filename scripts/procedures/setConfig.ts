// This is where any configuration rules related to the configuration would go. These ensure that the user can only create a valid config.

import { compat, types as T } from "../deps.ts";

// Define a custom type for T.Config to include the 'server' property with a 'type' property
interface AshigaruConfig extends T.Config {
  ashigaru?: {
    server?: {
      type?: string;
    };
  };
}

// deno-lint-ignore require-await
export const setConfig: T.ExpectedExports.setConfig = async (
  effects: T.Effects,
  newConfig: AshigaruConfig,
) => {
  const depsFulcrum: { [key: string]: string[] } = newConfig?.ashigaru?.server?.type === "fulcrum" ? { "fulcrum": ["synced"] } : {};

  return compat.setConfig(effects, newConfig, {
    ...depsFulcrum,
  });
};
