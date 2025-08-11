import { SSTConfig } from 'sst';
import * as lcDomain from './stacks/Domain';
import * as lcInstance from './stacks/Instance';
import * as lcGlobal from './stacks/Global';
import * as lcLoadBalancer from './stacks/LoadBalancer';
import * as lcStatic from './stacks/Static';
import * as lcStorage from './stacks/Storage';

export default {
  config(_input) {
    return {
      name: 'aiwc-librechat',
      region: 'us-east-1',
    };
  },
  stacks(app) {
    app.stack(lcGlobal.Global);
    if (app.stage !== 'global') {
      app.stack(lcDomain.Domain);
      app.stack(lcStatic.Static);
      app.stack(lcStorage.Storage);
      app.stack(lcLoadBalancer.LoadBalancer);
      app.stack(lcInstance.Instance);
    }
  },
} satisfies SSTConfig;
