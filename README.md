# Docker SSH Agent

Lets you store your SSH authentication keys in a dockerized ssh-agent that can provide the SSH authentication socket for other containers. Works in OSX and Linux environments.

## Why?

On OSX you cannot simply forward your authentication socket to a docker container to be able to e.g clone private repositories that you have access to. You don't want to copy your private key to all containers either. The solution is to add your keys only once to a long-lived ssh-agent container that can be used by other containers and stopped when not needed anymore.

## Image

You can pull the image from Amazon ECR via

```
docker pull 072717525149.dkr.ecr.us-west-2.amazonaws.com/docker-ssh-agent
```

## How to use

### Quickstart

If you don't want to build your own images, here's a 3-step guide:

1\. Run agent
```
docker run -d --name=ssh-agent 072717525149.dkr.ecr.us-west-2.amazonaws.com/docker-ssh-agent
```

2\. Add your keys
```
docker run --rm --volumes-from=ssh-agent -v ~/.ssh:/.ssh -it 072717525149.dkr.ecr.us-west-2.amazonaws.com/docker-ssh-agent ssh-add /.ssh/id_rsa
```

3\. Now run your actual container:

```
docker run -it --volumes-from=ssh-agent -e SSH_AUTH_SOCK=/.ssh-agent/socket ubuntu:latest /bin/bash
```

**Run script**

You can run the `run.sh` script which will build the images for you, launch the ssh-agent and add your keys. If your keys are password protected you will just need to input your passphrase.

```
./run.sh
```

Remove your keys from ssh-agent and stop container:

```
./run.sh -s
```

### Step by step

#### 0. Build
Navigate to the project directory and launch the following command to build the image:

```
docker build -t docker-ssh-agent:latest -f Dockerfile .
```

#### 1. Run a long-lived container
```
docker run -d --name=ssh-agent docker-ssh-agent:latest
```

#### 2. Add your ssh keys

Run a temporary container with volume mounted from host that includes your SSH keys. SSH key id_rsa will be added to ssh-agent (you can replace id_rsa with your key name):

```
docker run --rm --volumes-from=ssh-agent -v ~/.ssh:/.ssh -it docker-ssh-agent:latest ssh-add /.ssh/id_rsa
```

The ssh-agent container is now ready to use.

#### 3. Add ssh-agent socket to other container:

If you're using `docker-compose` this is how you forward the socket to a container:

```
ssh-sgent:
  container_name: ssh-agent
  image: 072717525149.dkr.ecr.us-west-2.amazonaws.com/docker-ssh-agent
  volumes:
    - dot_ssh:/root/.sshß
    - socket_dir:/.ssh-agent
  environment:
    - SSH_AUTH_SOCK=/.ssh-agent/socket
app:
  ...
  depends_on:
    - ssh-agent
  volumes:
    - dot_ssh:/root/.ssh
    - socket_dir:/.ssh-agent
  environment:
    SSH_AUTH_SOCK: /.ssh-agent/socket

volumes:
  dot_ssh:
  socket_dir:
```

##### For non-root users
The above only works for root. ssh-agent socket is accessible only to the user which started this agent or for root user. So other users don't have access to `/.ssh-agent/socket`. If you have another user in your container you should do the following:

1. Install `socat` utility in your container
2. Make proxy-socket in your container:
```
sudo socat UNIX-LISTEN:~/.ssh/socket,fork UNIX-CONNECT:/.ssh-agent/socket &
```
3. Change the owner of this proxy-socket
```
sudo chown $(id -u) ~/.ssh/socket
```
4. You will need to use different SSH_AUTH_SOCK for this user:
```
SSH_AUTH_SOCK=~/.ssh/socket
```

##### Without docker-compose
Here's an example how to run a Ubuntu container that uses the ssh authentication socket:
```
docker run -it --volumes-from=ssh-agent -e SSH_AUTH_SOCK=/.ssh-agent/socket ubuntu:latest /bin/bash
```

### Deleting keys from the container

Run a temporary container and delete all known keys from ssh-agent:

```
docker run --rm --volumes-from=ssh-agent -it docker-ssh-agent:latest ssh-add -D
```
