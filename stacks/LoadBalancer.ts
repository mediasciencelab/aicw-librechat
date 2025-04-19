import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';
import { Network } from './Network';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';

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

  stack.addOutputs({
    loadBalancerDNS: loadBalancer.loadBalancerDnsName,
    loadBalancerArn: loadBalancer.loadBalancerArn,
  });

  return { loadBalancer };
}
