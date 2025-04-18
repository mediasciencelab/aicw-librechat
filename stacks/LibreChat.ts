import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';
import { LibreChatStatic } from './LibreChatStatic';
import { LibreChatStorage } from './LibreChatStorage';
import { Network } from './Network';

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const { vpc, certificate } = sst.use(Network);

  const { keyPair, libreChatIpAddress, secretsPolicy } = sst.use(LibreChatStatic);

  const { ebsVolume } = sst.use(LibreChatStorage);

  const instance = new ec2.Instance(stack, 'LibreChatInstance', {
    vpc,
    instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.MEDIUM),
    machineImage: ec2.MachineImage.lookup({
      name: 'aiwc-librechat-*',
      owners: [stack.account],
      filters: {
        [`tag:mediasci:env:${stack.stage}`]: ['true'],
        'tag:mediasci:project': ['aicw'],
        architecture: ['arm64'],
      },
    }),
    propagateTagsToVolumeOnCreation: true,
    keyPair: keyPair,
    vpcSubnets: {
      subnetType: ec2.SubnetType.PUBLIC,
    },
  });

  instance.role.addManagedPolicy(secretsPolicy);

  instance.connections.allowFromAnyIpv4(ec2.Port.tcp(22), 'Allow SSH access from anywhere');

  instance.addUserData(
    '#!/bin/bash',
    `echo ${stack.stage} | cat >/etc/env`,
    `echo Environment set in /etc/env: ${stack.stage}`,
    '/home/ubuntu/firstrun.sh',
  );

  new ec2.CfnEIPAssociation(stack, 'LibreChatEIPAssociation', {
    allocationId: libreChatIpAddress.attrAllocationId,
    instanceId: instance.instanceId,
  });

  new ec2.CfnVolumeAttachment(stack, 'VolumeAttachment', {
    instanceId: instance.instanceId,
    volumeId: ebsVolume.volumeId,
    device: '/dev/xvdbb',
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: vpc.vpcId,
    instanceId: instance.instanceId,
    certificateArn: certificate.certificateArn,
    keyPairPrivateKeyParameter: keyPair.privateKey.parameterName,
  });
}
