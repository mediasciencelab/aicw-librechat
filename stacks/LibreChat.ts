import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';
import { LibreChatStorage } from './LibreChatStorage';
import { Network } from './Network';

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const { vpc, certificate } = sst.use(Network);

  const { ebsVolume } = sst.use(LibreChatStorage);

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
    propagateTagsToVolumeOnCreation: true,
  });

  const volumeAttachment = new ec2.CfnVolumeAttachment(stack, 'VolumeAttachment', {
    instanceId: instance.instanceId,
    volumeId: ebsVolume.volumeId,
    device: '/dev/sda2',
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: vpc.vpcId,
    instanceId: instance.instanceId,
    certificateArn: certificate.certificateArn,
  });
}
