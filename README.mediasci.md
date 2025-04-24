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

The docker image is built locally and uploaded to the EC2 instance used for building the AMI.
This is done because it takes a very long time to buuild the container images remotely.
Once built it is not necessary to rebuild the image unless the code changes.

```shell
docker compose -f docker-compose.mediasci.yml build
```

### EC2 AMI

Once the docker image is built, the AMI can be built using the `packer` command.

```shell
packer build -var env=<environment>  packer/templates/libre-chat
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
