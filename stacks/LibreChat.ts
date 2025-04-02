import { Cluster, ContainerImage } from 'aws-cdk-lib/aws-ecs';
import { Vpc } from 'aws-cdk-lib/aws-ec2';
import * as sst from "sst/constructs";
import { Service } from "sst/constructs";
import {setStandardTags} from "./tags";

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const vpc = new Vpc(stack, "Vpc", {
    maxAzs: 1,
    natGateways: 1,
  });

  const cluster = new Cluster(stack, "Cluster", {
    vpc,
  })

  const mongodb = new Service(stack, "MongoDB", {
    port: 27017,
    cdk: {
      cluster,
      vpc,
      container: {
        image: ContainerImage.fromRegistry(
          "public.ecr.aws/docker/library/mongo:latest")
      },
      applicationLoadBalancer: false,
      cloudfrontDistribution: false
    },
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
