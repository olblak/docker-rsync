# README

This docker image provides a rsync service using either rsyncd (default) or sshd as backend daemon.

## Using the image

This image is expected to run with a read only rootfs and unprivileged user.
The default user is `rsyncd` with an UID of `1000`.

### rsyncd (default)

This mode used by default is convenient to provide anonymous rsync service (usually read-only) for mirrors.

Simple usage:

```shell
# Start in background with defaults
docker run --detach --read-only -p 873:873 rsyncd
# Check default dir (empty) with the rsync protocol and unauthenticated request
rsync -av --port=873 localhost::root/ .tmp/
```

It exposes the default Rsync port `873`, which can be changed using the `$RSYNC_PORT` environment variable:

```shell
# Start in background with defaults
docker run --detach --read-only -p 1873:1873 -e RSYNC_PORT=1873 rsyncd
# Check default dir (empty) with the rsync protocol and unauthenticated request
rsync -av --port=1873 localhost::root/ .tmp/
```

You can provide "Rsync configuration modules" by mounting the `*.conf` files in `/home/rsyncd/etc/rsyncd.d/`:

```shell
# File ./jenkins.conf
[jenkins]
path = /home/rsyncd/data/jenkins

# Start with the rsync module conf file bind mounted in read-only
docker run --detach --read-only -p 873:873 -v "$(pwd)"/jenkins.conf:/home/rsyncd/etc/rsyncd.d/jenkins.conf:ro -v jenkins-data:/home/rsyncd/data/jenkins:rw rsyncd
# Check default dir (empty) with the rsync protocol and unauthenticated request
rsync -av --port=873 localhost::root/ .tmp/
# Check module 'jenkins'
rsync -av --port=873 localhost::jenkins/ .tmp/jenkins/
```

### sshd

This mode should be preferred when using authenticated access (usually to write data).

To enable SSH instead of RsyncD, the environment variable `$RSYNC_DAEMON` must be set to the value `sshd`.

SSH is restricted to only `rsync *` commands for the `rsyncd` user:
you cannot login and execute commands, no port/X11 forwarding and no SCP/sftp are allowed
(see the `ssh-rsync-wrapper.sh` script specified in the authorized keys).

SSH Authentication is restricted to only 1 public key associated to the default user `rsyncd`.
This key is provided through the `$SSH_PUBLIC_KEY` environment variable.

Simple example:

```shell
# Start in background
docker run --detach --read-only -p 22:22 -e RSYNC_DAEMON=sshd -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsyncd.pub)" rsyncd
# Check default dir (empty) with the rsync protocol and unauthenticated request
rsync -av --rsh="ssh -i $HOME/.ssh/id_rsyncd" rsyncd@localhost:data/ .tmp/
```

It exposes the default SSH port `22`, which can be changed using the `$SSH_PORT` environment variable:

```shell
# Start in background and publishes the port 4022
docker run --detach --read-only -p 4022:4022 -e SSH_PORT=4022 -e RSYNC_DAEMON=sshd -e SSH_PUBLIC_KEY="$(cat ~/.ssh/id_rsyncd.pub)" rsyncd
# Check default dir (empty) with the rsync protocol and unauthenticated request
rsync -av --rsh="ssh -p 4022 -i $HOME/.ssh/id_rsyncd" rsyncd@localhost:data/ .tmp/
```

Safety Note: There are no concepts of "Rsync" module with SSH: any specified directory accessible by the `rsyncd` user can be read (...or written).
As such, it's recommended to always use a read-only rootfs and eventually restrict network access as additional security measures to the key based authentication.

## Build the image

```shell
docker build --tag rsyncd ./
```

## Test the image

- Unit testing the image with [`container-structure-test`](https://github.com/GoogleContainerTools/container-structure-test):

```shell
container-structure-test test --image=rsyncd --config=cst.yml
```

- Manual acceptance testing of the the image with [`docker compose`](https://docs.docker.com/compose/):

```shell
$ cd ./tests
$ docker compose up --build --detach
$ sleep 2
$ rsync -av rsync://localhost:1873/jenkins
========================
==== JENKINS MIRROR ====
========================

**Read Only**

Feel free to reach out on https://www.jenkins.io/chat/#jenkins-infra/ with any question you may have

receiving file list ... done
drwxr-xr-x          96 2023/08/31 20:24:33 .
-rw-r--r--          12 2023/08/31 20:24:37 sample.txt

sent 16 bytes  received 111 bytes  254.00 bytes/sec
total size is 12  speedup is 0.09
```
