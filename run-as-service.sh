#!/bin/bash

PORT=2022

zig build -Dtarget=native-linux && \
docker build -t sshd . && \
docker run -v $(pwd)/dropbear:/etc/dropbear -v $(pwd)/dotssh:/home/myuser/.ssh -it -p $PORT:22 sshd

