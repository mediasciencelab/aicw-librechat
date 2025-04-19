import { SSTConfig } from 'sst';
import * as librechat from './stacks/Instance';
import * as librechatStatic from './stacks/Static';
import * as librechatStorage from './stacks/Storage';
import * as network from './stacks/Network';

export default {
  config(_input) {
    return {
      name: 'aiwc-librechat',
      region: 'us-east-1',
    };
  },
  stacks(app) {
    app.stack(network.Network);
    app.stack(librechatStatic.Static);
    app.stack(librechatStorage.Storage);
    app.stack(librechat.Instance);
  },
} satisfies SSTConfig;
