import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as sst from 'sst/constructs';
import { setStandardTags } from './tags';
import { Network } from './Network';

export function LoadBalancer({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const { vpc } = sst.use(Network);

  const loadBalancer = new elbv2.ApplicationLoadBalancer(stack, 'LoadBalancer', {
    vpc,
    internetFacing: true,
  });

  stack.addOutputs({
    loadBalancerDNS: loadBalancer.loadBalancerDnsName,
    loadBalancerArn: loadBalancer.loadBalancerArn,
  });

  return { loadBalancer };
}
