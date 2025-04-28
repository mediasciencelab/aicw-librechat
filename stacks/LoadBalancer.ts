import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as sst from 'sst/constructs';
import { Network } from './Network';
import { setStandardTags } from './tags';

export function LoadBalancer({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const { vpc, hostedZone, chatHostedZone } = sst.use(Network);

  const loadBalancer = new elbv2.ApplicationLoadBalancer(stack, 'LoadBalancer', {
    vpc,
    internetFacing: true,
  });

  const chatLoadBalancer = new elbv2.ApplicationLoadBalancer(stack, 'ChatLoadBalancer', {
    vpc,
    internetFacing: true,
  });

  new route53.ARecord(stack, 'DnsAlias', {
    zone: hostedZone,
    recordName: stack.stage,
    target: route53.RecordTarget.fromAlias(new route53Targets.LoadBalancerTarget(loadBalancer)),
  });

  new route53.ARecord(stack, 'ChatDnsAlias', {
    zone: chatHostedZone,
    recordName: stack.stage,
    target: route53.RecordTarget.fromAlias(new route53Targets.LoadBalancerTarget(chatLoadBalancer)),
  });

  const lbSecurityGroup = new ec2.SecurityGroup(stack, 'lbSecurityGroup', {
    vpc,
    description: 'Security group for ALB',
    allowAllOutbound: true,
  });

  loadBalancer.connections.addSecurityGroup(lbSecurityGroup);
  chatLoadBalancer.connections.addSecurityGroup(lbSecurityGroup);

  stack.addOutputs({
    loadBalancerDNS: loadBalancer.loadBalancerDnsName,
    loadBalancerArn: loadBalancer.loadBalancerArn,
    chatLoadBalancerDNS: chatLoadBalancer.loadBalancerDnsName,
    chatLoadBalancerArn: chatLoadBalancer.loadBalancerArn,
  });

  return {
    loadBalancer,
    chatLoadBalancer,
    lbSecurityGroup,
    loadBalancerArn: loadBalancer.loadBalancerArn,
    loadBalancerSecurityGroupId: lbSecurityGroup.securityGroupId,
    chatLoadBalancerArn: chatLoadBalancer.loadBalancerArn,
    chatLoadBalancerSecurityGroupId: lbSecurityGroup.securityGroupId,
  };
}
