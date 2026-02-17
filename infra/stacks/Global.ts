import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';

export function Global({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const projectVpc = (() => {
    if (stack.stage === 'global') {
      return new ec2.Vpc(stack, 'ProjectVpc', {
        maxAzs: 2,
        natGateways: 1,
        vpcName: 'aicw',
      });
    } else {
      return ec2.Vpc.fromLookup(stack, 'ProjectVpc', {
        vpcName: 'aicw',
      });
    }
  })();

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: projectVpc.vpcId,
  });

  return {
    vpc: projectVpc,
  };
}
