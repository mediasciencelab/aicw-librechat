import * as certificatemanager from 'aws-cdk-lib/aws-certificatemanager';
import * as constants from './constants';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';
import { LibreChatStorage } from './LibreChatStorage';

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const vpc = new ec2.Vpc(stack, 'Vpc', {
    maxAzs: 1,
    natGateways: 1,
  });

  const hostedZone = route53.HostedZone.fromLookup(stack, 'HostedZone', {
    domainName: constants.hostedDomainName,
  });
  const domainName = `${stack.stage}.${constants.hostedDomainName}`;

  const certificate = new certificatemanager.Certificate(stack, 'Certificate', {
    domainName: domainName,
    validation: certificatemanager.CertificateValidation.fromDns(hostedZone),
  });

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
