import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
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

  const ssmPolicyStatement = new iam.PolicyStatement({
    effect: iam.Effect.ALLOW,
    actions: [
      'ssm:GetParameter',
      'ssm:GetParameters',
      'ssm:GetParameterHistory',
      'ssm:GetParametersByPath',
      'ssm:DescribeParameters',
    ],
    resources: [
      `arn:aws:ssm:${stack.region}:${stack.account}:parameter/mediasci/aicw/librechat/${stack.stage}/env`,
    ],
  });

  const kmsKeyDecryptionPolicyStatement = new iam.PolicyStatement({
    effect: iam.Effect.ALLOW,
    actions: ['kms:Decrypt'],
    resources: [kmsKey.keyArn],
  });

  const secretsPolicy = new iam.ManagedPolicy(stack, 'SecretsPolicy', {
    statements: [ssmPolicyStatement, kmsKeyDecryptionPolicyStatement],
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    keyPairName: keyPair.keyPairName,
    keyPairPrivateKeyParameter: keyPair.privateKey.parameterName,
    kmsKeyId: kmsKey.keyId,
    libreChatIpAddress: libreChatIpAddress.attrPublicIp,
    secretsPolicyArn: secretsPolicy.managedPolicyArn,
  });

  return { keyPair, kmsKey, libreChatIpAddress, secretsPolicy };
}
