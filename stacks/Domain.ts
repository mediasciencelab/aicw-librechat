import * as certificatemanager from 'aws-cdk-lib/aws-certificatemanager';
import * as constants from './constants';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';

export function Domain({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const chatHostedZone = route53.HostedZone.fromLookup(stack, 'ChatHostedZone', {
    domainName: constants.chatHostedDomainName,
  });
  const chatDomainName = `${stack.stage}.${constants.chatHostedDomainName}`;

  const chatCertificate = new certificatemanager.Certificate(stack, 'ChatCertificate', {
    domainName: chatDomainName,
    validation: certificatemanager.CertificateValidation.fromDns(chatHostedZone),
  });

  // Export values from cloudformation template.
  stack.addOutputs({
    chatCertificateArn: chatCertificate.certificateArn,
  });

  return {
    chatCertificate,
    chatHostedZone,
  };
}
