# Libre-Chat deployment

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

The docker image is built as part of the AMI build process. However, if you want to
build the docker image separately, you can do so using the `docker compose` command.
This will build the image to your locally running docker daemon.

```shell
docker compose -f docker-compose.mediasci.yml build
```

### EC2 AMI

Once the docker image is built, the AMI can be built using the `packer` command.

```shell
packer build -var env=<environment>  packer/templates/libre-chat
```

### Deploying EC2 AMI to environment

And AMI is used by an environment if it is tagged for that environment. For a given environment
"my-env", the AMI must be tagged with `mediasci:env:my-env` == `true`. The latest AMI image which
name starts with `aiwc-librechat-` and is tagged with `mediasci:env:my-env` will be used by that
environment.

You can promote an AMI from an existing environment to another environment by using the
`promote-ami.sh` script:

```shell
./script/promote-ami.sh <source-env> <destination-env>
```

**WARNING:** In order to deploy a new AMI to an existing environment, it is necessary to *manually*
delete the reference to the old AMI from your local `cdk.context.json` file. This is because the
CDK will not update the AMI reference if it is already set. 

## Infrastructure Architecture

The infrastructure uses a shared VPC model with separate stacks for different concerns:

### Stack Overview

1. **Global Stack** (`--stage global`): Creates shared VPC infrastructure used by all environments
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

To reduce costs or temporarily disable an environment while preserving storage and secrets, you can
remove stacks in reverse dependency order. This preserves EBS volumes, KMS keys, secrets, and
Elastic IP addresses:

```shell
# Remove stacks in reverse dependency order
pnpm sst remove --stage <env> Instance
pnpm sst remove --stage <env> LoadBalancer
pnpm sst remove --stage <env> Domain
```

**Important:** Always remove in this order to avoid dependency conflicts. The Static and Storage stacks are preserved to maintain persistent resources.

**Re-enabling a disabled environment:**

To restore a temporarily disabled environment, redeploy stacks in dependency order:

```shell
# Deploy stacks in dependency order
pnpm sst deploy --stage <env> Domain
pnpm sst deploy --stage <env> LoadBalancer
pnpm sst deploy --stage <env> Instance
```

### Setting environment secrets

There are a number of secrets that an environement needs in order to run. These are set manually.
These secrets must be encrypted using the environments KMS key. To create the KMS key, deploy the
`Static` stack:

```shell
pnpm sst deploy --stage <env> Static
```

The secrets for an environment must have the format:

```shell
CREDS_KEY=<credential key>
CREDS_IV=<credential IV>
JWT_SECRET=<JWT secret>
JWT_REFRESH_SECRET=<JWT refresh secret>
MEILI_MASTER_KEY=<MeiliSearch master key>
OPENAI_API_KEY=<OpenAI API key>
ANTHROPIC_API_KEY=<Anthropic API key>
```

A file containing these secret can be uploaded using the `upload-secrets.sh` script:

```shell
./scripts/upload-secrets.sh -s <env> <path-to-secrets-file>
```

# User management

If you have sufficient access to the main AWS account, you can use scripts in the `scripts`
directory to remotely manage users on the EC2 instance.

All scripts will by default use the stage set in the `.sst/stage` file. To explicitly use
a specific stage, use the `-s` flag on each command.

## Adding SSH key to agent

Before running any of the scripts, you need to add the SSH key to the agent. This is done
using the `scripts/ssh-add-instance.sh`. The SSH key is specific to each environment.
Like all commands, you can use the `-s` flag to specify the environment or it will attempt
to use the stage in the `.sst/stage` file.

**Example:**

```shell
./scripts/ssh-add-instance.sh -s trajector
```

## SSH to instance

One can simply SSH to the instance using the `scripts/ssh-instance.sh` script. This assumes
you have already added the SSH key to the agent using the `ssh-add-instance.sh` script.
Like all commands, you can use the `-s` flag to specify the environment or it will attempt
to use the stage in the `.sst/stage` file.

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
