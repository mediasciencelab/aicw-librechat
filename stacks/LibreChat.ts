import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as ecs from "aws-cdk-lib/aws-ecs";
import * as sst from "sst/constructs";
import * as constructs from "sst/constructs";
import {setStandardTags} from "./tags";

export function LibreChat({ stack }: sst.StackContext) {
  setStandardTags(stack);

  const vpc = new ec2.Vpc(stack, "Vpc", {
    maxAzs: 1,
    natGateways: 1,
  });

  const cluster = new ecs.Cluster(stack, "Cluster", {
    vpc,
  })

  const mongodb = new constructs.Service(stack, "MongoDB", {
    port: 27017,
    cdk: {
      cluster,
      vpc,
      container: {
        image: ecs.ContainerImage.fromRegistry(
          "public.ecr.aws/docker/library/mongo:latest"),
          command: ["mongod", "--noauth"],
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
