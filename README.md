# README

This docker image is a rsync daemon, that serve files from directory /srv/releases/jenkins

## Build the image

```shell
docker build --tag rsyncd ./
```

## Test the image

- Unit testing the image with [`container-structure-test`](https://github.com/GoogleContainerTools/container-structure-test):

```shell
container-structure-test test --image=rsyncd --config=cst.yml
```

- Acceptance testing the image with [`docker compose`](https://docs.docker.com/compose/):

```shell
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
