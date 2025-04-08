import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const vpc = new ec2.Vpc(stack, 'Vpc', {
    maxAzs: 1,
    natGateways: 1,
  });

  const instance = new ec2.Instance(stack, 'LibreChatInstance', {
    vpc,
    instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MEDIUM),
    machineImage: ec2.MachineImage.lookup({
      name: 'aiwc-librechat-*',
      owners: [stack.account],
      filters: {
        [`tag:mediasci:env:${stack.stage}`]: ['true'],
        'tag:mediasci:project': ['aicw'],
      },
    }),
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: vpc.vpcId,
    instanceId: instance.instanceId,
  });
}
