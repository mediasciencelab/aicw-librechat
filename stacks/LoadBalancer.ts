import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import * as sst from 'sst/constructs';
import { Network } from './Network';
import { setStandardTags } from './tags';

export function LoadBalancer({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const { vpc, hostedZone } = sst.use(Network);

  const loadBalancer = new elbv2.ApplicationLoadBalancer(stack, 'LoadBalancer', {
    vpc,
    internetFacing: true,
  });

  new route53.ARecord(stack, 'DnsAlias', {
    zone: hostedZone,
    recordName: stack.stage,
    target: route53.RecordTarget.fromAlias(new route53Targets.LoadBalancerTarget(loadBalancer)),
  });

  const lbSecurityGroup = new ec2.SecurityGroup(stack, 'lbSecurityGroup', {
    vpc,
    description: 'Security group for ALB',
    allowAllOutbound: true,
  });

  loadBalancer.connections.addSecurityGroup(lbSecurityGroup);

  stack.addOutputs({
    loadBalancerDNS: loadBalancer.loadBalancerDnsName,
    loadBalancerArn: loadBalancer.loadBalancerArn,
  });

  return {
    loadBalancer,
    lbSecurityGroup,
    loadBalancerArn: loadBalancer.loadBalancerArn,
    loadBalancerSecurityGroupId: lbSecurityGroup.securityGroupId,
  };
}
