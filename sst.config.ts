import { SSTConfig } from "sst";
import * as librechat from "./stacks/LibreChat";

export default {
  config(_input) {
    return {
      name: "aiwc-librechat",
      region: "us-east-1",
    };
  },
  stacks(app) {
    app.stack(librechat.LibreChat);
  }
} satisfies SSTConfig;
