import * as core from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';

export function LibreChatStorage({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const ebsVolume = new ec2.Volume(stack, 'EbsVolume', {
    availabilityZone: 'us-east-1a',
    size: core.Size.gibibytes(10),
    volumeType: ec2.EbsDeviceVolumeType.GP2,
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    ebsVolumeId: ebsVolume.volumeId,
  });

  return { ebsVolume };
}
