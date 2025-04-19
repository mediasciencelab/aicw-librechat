import { SSTConfig } from 'sst';
import * as lcInstance from './stacks/Instance';
import * as lcLoadBalancer from './stacks/LoadBalancer';
import * as lcStatic from './stacks/Static';
import * as lcStorage from './stacks/Storage';
import * as lcNetwork from './stacks/Network';

export default {
  config(_input) {
    return {
      name: 'aiwc-librechat',
      region: 'us-east-1',
    };
  },
  stacks(app) {
    app.stack(lcNetwork.Network);
    app.stack(lcStatic.Static);
    app.stack(lcStorage.Storage);
    app.stack(lcLoadBalancer.LoadBalancer);
    app.stack(lcInstance.Instance);
  },
} satisfies SSTConfig;
