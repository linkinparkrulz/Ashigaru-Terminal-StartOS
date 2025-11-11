import { types as T, compat, matches } from "../deps.ts";

const { shape, boolean, string } = matches;

const current = "3.2.1.2";

export const migration: T.ExpectedExports.migration = (
  effects: T.Effects,
  version: string,
  ...args: unknown[]
) => {
  return compat.migrations.fromMapping({
      "2.0.0": {
            up: compat.migrations.updateConfig(
                (config) => {
                    const matchElectrs = shape({
                        "enable-fulcrum": boolean,
                     });
                    if (!matchElectrs.test(config)) {
                        config["enable-fulcrum"] = true;
                        return config;
                    }
                    return config;
                },
                false,
                { version: "2.0.0", type: "up" }
            ),
            down: compat.migrations.updateConfig(
                (config) => {
                    const matchElectrs = shape(
                        {
                            "enable-fulcrum": boolean,
                        },
                        ["enable-fulcrum"]
                    );
                    if (matchElectrs.test(config)) {
                        delete config["enable-fulcrum"];
                        return config;
                    }
                    return config;
                },
                true,
                { version: "2.0.0", type: "down" }
            ),
      },
  },
  current
  )(effects, version, ...args);
};
