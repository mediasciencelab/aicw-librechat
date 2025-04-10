import * as certificatemanager from 'aws-cdk-lib/aws-certificatemanager';
import * as constants from './constants';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';

export function Network({ stack }: sst.StackContext) {
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

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: vpc.vpcId,
    certificateArn: certificate.certificateArn,
  });

  return {
    vpc,
    certificate,
  };
}
