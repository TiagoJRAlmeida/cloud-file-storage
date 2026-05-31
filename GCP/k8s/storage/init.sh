#!/bin/bash

source .env
helm install minio ./minio \
    --set auth.rootUser=$MINIO_ROOT_USER \
    --set auth.rootPassword=$MINIO_ROOT_PASSWORD \
    --namespace storage \
    --create-namespace
