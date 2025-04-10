import { SSTConfig } from 'sst';
import * as librechat from './stacks/LibreChat';
import * as librechatStatic from './stacks/LibreChatStatic';
import * as librechatStorage from './stacks/LibreChatStorage';
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
    app.stack(librechatStatic.LibreChatStatic);
    app.stack(librechatStorage.LibreChatStorage);
    app.stack(librechat.LibreChat);
  },
} satisfies SSTConfig;
