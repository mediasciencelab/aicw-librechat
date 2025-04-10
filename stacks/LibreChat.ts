import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';
import { LibreChatStorage } from './LibreChatStorage';
import { Network } from './Network';

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const { vpc, certificate } = sst.use(Network);

  const { ebsVolume } = sst.use(LibreChatStorage);

  const keyPair = new ec2.KeyPair(stack, 'KeyPair', {
    keyPairName: `aiwc-librechat-${stack.stage}`,
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
    propagateTagsToVolumeOnCreation: true,
    keyPair: keyPair,
    vpcSubnets: {
      subnetType: ec2.SubnetType.PUBLIC,
    },
    associatePublicIpAddress: false,
  });

  instance.connections.allowFromAnyIpv4(ec2.Port.tcp(22), 'Allow SSH access from anywhere');

  new ec2.CfnVolumeAttachment(stack, 'VolumeAttachment', {
    instanceId: instance.instanceId,
    volumeId: ebsVolume.volumeId,
    device: '/dev/sda2',
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: vpc.vpcId,
    instanceId: instance.instanceId,
    certificateArn: certificate.certificateArn,
    keyPairPrivateKeyParameter: keyPair.privateKey.parameterName,
  });
}
