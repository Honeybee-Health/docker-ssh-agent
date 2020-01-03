#!/bin/bash

underline='\033[4;37m'
purple='\033[0;35m'
bold='\033[1;37m'
green='\033[0;32m'
cyan='\033[0;36m'
red='\033[0;31m'
nc='\033[0m'

IMAGE_NAME="docker-ssh-agent"
CONTAINER_NAME="ssh-agent"

# Find image id
image=$(docker images | grep $IMAGE_NAME | awk '{print $3}')

# Find agent container id
id=$(docker ps -a|grep $CONTAINER_NAME|awk '{print $1}')

# Stop command
if [ "$1" == "-s" ] && [ $id ]; then
  echo -e "Removing ssh-keys..."
  docker run --rm --volumes-from=$CONTAINER_NAME -it $IMAGE_NAME:latest ssh-add -D
  echo -e "Stopping $CONTAINER_NAME container..."
  docker rm -f $id
  exit
fi

# Build image if not available
if [ -z $image ]; then
  echo -e "${bold}The image for $IMAGE_NAME has not been built.${nc}"
  echo -e "Building image..."
  docker build -t $IMAGE_NAME:latest -f Dockerfile .
  echo -e "${cyan}Image built.${nc}"
fi

# If container is already running, exit.
if [ $id ]; then
  echo -e "A container named '$CONTAINER_NAME' is already running."
  echo -e "Do you wish to stop it? (y/N): "
  read input

  if [ "$input" == "y" ]; then
    echo -e "Removing SSH keys..."
    docker run --rm --volumes-from=$CONTAINER_NAME -it $IMAGE_NAME:latest ssh-add -D
    echo -e "Stopping $CONTAINER_NAME container..."
    docker rm -f $id
    echo -e "${red}Stopped.${nc}"
  fi

  exit
fi

# Run ssh-agent
echo -e "${bold}Launching $CONTAINER_NAME container...${nc}"
docker run -d --name=$CONTAINER_NAME $IMAGE_NAME:latest

echo -e "Adding your ssh keys to the $CONTAINER_NAME container..."
docker run --rm --volumes-from=$CONTAINER_NAME -v ~/.ssh:/.ssh -it $IMAGE_NAME:latest ssh-add /root/.ssh/id_rsa

echo -e "${green}$CONTAINER_NAME is now ready to use.${nc}"
