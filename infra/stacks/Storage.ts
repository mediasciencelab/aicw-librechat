import * as core from 'aws-cdk-lib/core';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sst from 'sst/constructs';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { setStandardTags } from './tags';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function Storage({ stack }: sst.StackContext) {
  setStandardTags(stack);

  // Read snapshot ID from file system during stack synthesis
  // This approach is used because:
  // - EBS volumes must specify their snapshot ID at creation time - it cannot be changed later
  // - SST Config.Parameter values are fixed when the stack is defined, not read dynamically
  // - SST Config.Secret values can only be accessed inside Lambda functions, not during stack synthesis
  // - Environment variables from .env files were not being loaded consistently during deployment
  //
  // The restore script writes the snapshot ID to .snapshot-id.{stage} before deploying.
  let snapshotId: string | undefined;
  const snapshotFile = path.join(__dirname, '..', '..', `.snapshot-id.${stack.stage}`);

  if (fs.existsSync(snapshotFile)) {
    snapshotId = fs.readFileSync(snapshotFile, 'utf8').trim();
    console.log(`Read snapshot ID from ${snapshotFile}: ${snapshotId}`);
  } else {
    console.log(`Snapshot file ${snapshotFile} does not exist, proceeding without snapshot`);
    snapshotId = undefined;
  }

  const size = snapshotId ? undefined : core.Size.gibibytes(10);

  let volumeProps: ec2.VolumeProps = {
    availabilityZone: 'us-east-1a',
    volumeType: ec2.EbsDeviceVolumeType.GP2,
    snapshotId,
    size,
  };

  const ebsVolume = new ec2.Volume(stack, 'EbsVolume', volumeProps);

  // Export values from cloudformation template.
  stack.addOutputs({
    ebsVolumeId: ebsVolume.volumeId,
  });

  return { ebsVolume };
}
