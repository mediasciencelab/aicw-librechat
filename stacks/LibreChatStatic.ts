import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';

export function LibreChatStatic({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const keyPair = new ec2.KeyPair(stack, 'KeyPair', {
    keyPairName: `aiwc-librechat-${stack.stage}`,
  });

  const libreChatIpAddress = new ec2.CfnEIP(stack, 'LibreChatIpAddress', {});

  const kmsKey = new kms.Key(this, 'KmsKey');

  // Export values from cloudformation template.
  stack.addOutputs({
    keyPairName: keyPair.keyPairName,
    keyPairPrivateKeyParameter: keyPair.privateKey.parameterName,
    kmsKeyId: kmsKey.keyId,
    libreChatIpAddress: libreChatIpAddress.attrPublicIp,
  });

  return { keyPair, kmsKey, libreChatIpAddress };
}
