import * as certificatemanager from 'aws-cdk-lib/aws-certificatemanager';
import * as constants from './constants';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';

export function Network({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const vpc = new ec2.Vpc(stack, 'Vpc', {
    maxAzs: 2,
    natGateways: 1,
  });

  const hostedZone = route53.HostedZone.fromLookup(stack, 'HostedZone', {
    domainName: constants.hostedDomainName,
  });
  const domainName = `${stack.stage}.${constants.hostedDomainName}`;

  const chatHostedZone = route53.HostedZone.fromLookup(stack, 'ChatHostedZone', {
    domainName: constants.chatHostedDomainName,
  });
  const chatDomainName = `${stack.stage}.${constants.chatHostedDomainName}`;

  const certificate = new certificatemanager.Certificate(stack, 'Certificate', {
    domainName: domainName,
    validation: certificatemanager.CertificateValidation.fromDns(hostedZone),
  });

  const chatCertificate = new certificatemanager.Certificate(stack, 'ChatCertificate', {
    domainName: chatDomainName,
    validation: certificatemanager.CertificateValidation.fromDns(chatHostedZone),
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: vpc.vpcId,
    certificateArn: certificate.certificateArn,
    chatCertificateArn: chatCertificate.certificateArn,
  });

  return {
    vpc,
    certificate,
    chatCertificate,
    hostedZone,
  };
}
