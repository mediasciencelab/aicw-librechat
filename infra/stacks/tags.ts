import {Stack} from "sst/constructs";
import {CfnTag} from "aws-cdk-lib";

export function setStandardTags(stack: Stack) {
    const tags: Array<CfnTag> = [
        { key: "mediasci:env", value: stack.stage },
        { key: "mediasci:project", value: "aiwc" },
        { key: "mediasci:provisioner", value: "sst2" },
        { key: "mediasci:provisioner:github-owner", value: "mediasciencelab" },
        { key: "mediasci:provisioner:stack-name", value: stack.stackName },
    ];

    for (const tag of tags) {
        stack.tags.setTag(tag.key, tag.value);
    }
}
