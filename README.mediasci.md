# Libre-Chat deployment

## Prerequisites

- AWS CLI configured with appropriate permissions
- Domain hosted zone already configured in Route 53

## Requirements

### packer

See [Packer website](https://developer.hashicorp.com/packer)

```shell
brew install packer
```

### docker

See [Docker website](https://www.docker.com/)

## Build for deployment

### Docker image

The docker image is built as part of the AMI build process. However, if you want to build the
docker image separately, you can do so using the `docker compose` command. This will build the
image to your locally running docker daemon.

```shell
docker compose -f docker-compose.mediasci.yml build
```

### EC2 AMI

Once the docker image is built, the AMI can be built using the `packer` command. The
`<environment>` parameter should match the stage name you plan to deploy to (e.g., "dev",
"staging", "prod"):

```shell
packer build -var env=<environment>  packer/templates/libre-chat
```

**Example:**
```shell
packer build -var env=staging packer/templates/libre-chat
```

### Deploying EC2 AMI to environment

AMIs are automatically selected by the deployment based on tags. For a given stage "my-env", the
deployment will use the latest AMI that:
- Has a name starting with `aiwc-librechat-`
- Is tagged with `mediasci:env:my-env` = `true`
- Is tagged with `mediasci:project` = `aicw`

**AMI Tagging:** When you build an AMI with `packer build -var env=my-env`, it automatically gets
tagged for that environment.

**Promoting AMIs between environments:**

You can promote an existing AMI from one environment to another without rebuilding:

```shell
./scripts/promote-ami.sh <source-env> <destination-env>
```

**Example:**
```shell
./scripts/promote-ami.sh dev prod
```

**WARNING:** In order to deploy a new AMI to an existing environment, it is necessary to
*manually* delete the reference to the old AMI from your local `cdk.context.json` file. This is
because the CDK will not update the AMI reference if it is already set.

## Infrastructure Architecture

The infrastructure uses a shared VPC model with separate stacks for different concerns:

**Note:** Throughout this documentation, "stage" and "environment" are used interchangeably. Both
refer to deployment targets like "dev", "staging", or "trajector".

### Stack Overview

1. **Global Stack** (`--stage global`): Creates shared VPC infrastructure used by all
   environments
2. **Domain Stack**: Manages SSL certificates and DNS configuration
3. **Static Stack**: Creates environment-specific resources (KMS keys, EIP, etc.)
4. **Storage Stack**: Manages EBS volumes
5. **LoadBalancer Stack**: Application load balancer configuration
6. **Instance Stack**: EC2 instance and target group configuration

### Deployment Order

**First-time setup:**

1. Deploy the Global stack to create shared VPC:
   ```shell
   pnpm sst deploy --stage global
   ```

2. Deploy environment-specific stacks:
   ```shell
   pnpm sst deploy --stage <env>
   ```

### Environment Management

**Temporarily disabling an environment:**

To reduce costs or temporarily disable an environment while preserving storage and secrets, you
can remove stacks in reverse dependency order. This preserves EBS volumes, KMS keys, secrets,
and Elastic IP addresses:

```shell
# Remove stacks in reverse dependency order
pnpm sst remove --stage <env> Instance
pnpm sst remove --stage <env> LoadBalancer
pnpm sst remove --stage <env> Domain
```

**Important:** Always remove in this order to avoid dependency conflicts. The Static and Storage
stacks are preserved to maintain persistent resources.

**Re-enabling a disabled environment:**

To restore a temporarily disabled environment, redeploy stacks in dependency order:

```shell
# Deploy stacks in dependency order
pnpm sst deploy --stage <env> Domain
pnpm sst deploy --stage <env> LoadBalancer
pnpm sst deploy --stage <env> Instance
```

## Version Tags

The repository maintains several types of version tags to track important milestones and
architectural changes:

### Archive Tags
- **archive/unshared-vpc** (2025-05-05) - Marks the project before migrating to shared VPC
  architecture
- **archive/v0.7.7** (2025-08-11) - This represents the last change before migrating to v0.8.x.

### MediaSci Fork Tags
- **mediasci/fork-1** (2025-04-01) - First point in upstream repository where fork occured.
- **mediasci/fork-2** (2025-08-12) - Second point in upstream repository where fork occured.
  This was where v0.8.0-rc2 was defined.

**Tag Usage:**
- `archive/` tags mark significant infrastructure changes or major refactoring points
- `mediasci/` tags track specific fork points
- These tags serve as reference points for understanding the evolution of the deployment
  architecture and codebase

### Setting environment secrets

Each environment requires several secrets to function properly. These secrets are encrypted using
the environment's KMS key and stored in AWS Systems Manager Parameter Store.

**Step 1: Deploy `Static` stack to create KMS key**

```shell
pnpm sst deploy --stage <env> Static
```

**Step 2: Create secrets file**

Create a file containing the required secrets in this format:

```shell
CREDS_KEY=<credential key>
CREDS_IV=<credential IV>
JWT_SECRET=<JWT secret>
JWT_REFRESH_SECRET=<JWT refresh secret>
MEILI_MASTER_KEY=<MeiliSearch master key>
OPENAI_API_KEY=<OpenAI API key>
ANTHROPIC_API_KEY=<Anthropic API key>
```

**Step 3: Upload secrets**

```shell
./scripts/upload-secrets.sh -s <env> <path-to-secrets-file>
```

**Example:**
```shell
./scripts/upload-secrets.sh -s staging ./secrets/trajector.env
```

**How secrets are used:** The LibreChat application automatically retrieves these encrypted
secrets from Parameter Store at startup using the KMS key to decrypt them.

# User management

You can use scripts in the `scripts` directory to remotely manage users on the EC2 instance.

**Prerequisites for user management scripts:**
- AWS CLI configured with permissions for EC2, Systems Manager Parameter Store, and KMS
- SSH access to the target environment's EC2 instance

**Stage selection:** All scripts will by default use the stage set in the `.sst/stage` file. To
explicitly use a specific stage, use the `-s` flag on each command. If the `.sst/stage` file
doesn't exist, you must use the `-s` flag.

## Adding SSH key to agent

Before running any of the scripts, you need to add the SSH key to the agent. This is done using
the `scripts/ssh-add-instance.sh`. The SSH key is specific to each environment. Like all
commands, you can use the `-s` flag to specify the environment or it will attempt to use the
stage in the `.sst/stage` file.

**Example:**

```shell
./scripts/ssh-add-instance.sh -s trajector
```

## SSH to instance

One can simply SSH to the instance using the `scripts/ssh-instance.sh` script. This assumes you
have already added the SSH key to the agent using the `ssh-add-instance.sh` script. Like all
commands, you can use the `-s` flag to specify the environment or it will attempt to use the
stage in the `.sst/stage` file.

**Example:**

```shell
./scripts/ssh-instance.sh -s trajector
```

## Commands

* `scripts/create-user.sh` - Create a new Libre-Chat user.
* `scripts/delete-user.sh` - Delete a Libre-Chat user.
* `scripts/list-users.sh` - List all Libre-Chat users.
* `scripts/reset-password.sh` - Reset the password for a Libre-Chat user.
* `scripts/user-stats.sh` - Get the stats for all Libre-Chat users.

**Example:**

```shell
./scripts/create-user.sh -s trajector
```