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

**WARNING:** In order to deploy a new AMI to an existing environment, it is necessary to *manually*
delete the reference to the old AMI from your local `cdk.context.json` file. This is because the
CDK will not update the AMI reference if it is already set. 

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
