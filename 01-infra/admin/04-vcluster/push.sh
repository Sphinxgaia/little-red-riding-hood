#!/usr/bin/env bash

aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 955480398230.dkr.ecr.eu-west-1.amazonaws.com


./push-images.sh --registry 955480398230.dkr.ecr.eu-west-1.amazonaws.com