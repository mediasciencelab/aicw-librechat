import * as sst from "sst/constructs";
import {setStandardTags} from "./tags";
import { Service } from "sst/constructs";
import { Cluster } from "aws-cdk-lib/aws-ecs";
import { Vpc } from 'aws-cdk-lib/aws-ec2';

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const vpc = new Vpc(stack, "Vpc", {
    maxAzs: 1,
    natGateways: 1,
  });

  const cluster = new Cluster(stack, "Cluster", {
    vpc,
  })

  // Export values from cloudformation template.
  stack.addOutputs({
    vpcId: vpc.vpcId,
    clusterName: cluster.clusterName,
    clusterArn: cluster.clusterArn,
  })

  return {
    cluster: cluster.clusterArn,
  }
}
