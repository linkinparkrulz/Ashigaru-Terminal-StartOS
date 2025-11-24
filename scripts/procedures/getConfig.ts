// To utilize the default config system built, this file is required. It defines the *structure* of the configuration file. These structured options display as changeable UI elements within the "Config" section of the service details page in the StartOS UI.

import { compat, types as T } from "../deps.ts";

export const getConfig: T.ExpectedExports.getConfig = compat.getConfig({
  network: {
    type: "union",
    name: "Bitcoin Network",
    description:
      "<p>Select which Bitcoin network to use:</p><ul><li><strong>Mainnet</strong>: Use the main Bitcoin network (recommended for production use).</li><li><strong>Testnet</strong>: Use the Bitcoin test network (for testing only).</li></ul>",
    tag: {
      id: "type",
      name: "Network Type",
      "variant-names": {
        mainnet: "Mainnet (recommended)",
        testnet: "Testnet (testing only)",
      },
      description:
        "<p>Select which Bitcoin network to use:</p><ul><li><strong>Mainnet</strong>: Use the main Bitcoin network (recommended for production use).</li><li><strong>Testnet</strong>: Use the Bitcoin test network (for testing only).</li></ul>",
    },
    warning:
      "Testnet is for testing purposes only. Testnet coins have no real value.",
    default: "mainnet",
    variants: {
      mainnet: {},
      testnet: {},
    },
  },
  server: {
    type: "union",
    name: "Electrum Server",
    description:
      "<p>The Electrum server to connect to:</p><ul><li><strong>Fulcrum</strong>: Use the Fulcrum service installed on your server (recommended).</li><li><strong>Public</strong>: Use a public Electrum server (not recommended!).</li></ul>",
    tag: {
      id: "type",
      name: "Server Type",
      "variant-names": {
        fulcrum: "Fulcrum (recommended)",
        public: "Public (not recommended)",
      },
      description:
        "<p>The Electrum server to connect to:</p><ul><li><strong>Fulcrum</strong>: Use the Fulcrum service installed on your server (recommended).</li><li><strong>Public</strong>: Use a public Electrum server (not recommended!).</li></ul>",
    },
    warning:
      "If using 'Public', please switch to using Fulcrum as soon as possible. Using a public server can expose your IP address and transactions.",
    default: "fulcrum",
    variants: {
      fulcrum: {},
      public: {},
    },
  },
  proxy: {
    name: "Use a proxy",
    description:
      "<p>Use a proxy for external connections</p><ul><li><strong>Tor</strong>: Use the Tor Proxy of StartOS (recommended)</li><li><strong>None</strong>: do not use a proxy</li></ul>",
    type: "union",
    tag: {
      id: "type",
      name: "Proxy Type",
      "variant-names": {
        tor: "Tor (recommended)",
        none: "None (not recommended)",
      },
      description:
        "<p>Use a proxy for external connections</p><ul><li><strong>Tor</strong>: Use the Tor Proxy of StartOS (recommended)</li><li><strong>None</strong>: do not use a proxy</li></ul>",
    },
    default: "tor",
    variants: {
      tor: {},
      none: {},
    },
  },
});
