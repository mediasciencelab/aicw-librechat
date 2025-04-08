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

