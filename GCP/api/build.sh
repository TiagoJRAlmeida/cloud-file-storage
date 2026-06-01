#!/bin/bash

VERSION=${1:-v1}
docker build -t tiagojralmeida/storage-api:$VERSION .
docker push tiagojralmeida/storage-api:$VERSION
echo "Built and pushed tiagojralmeida/storage-api:$VERSION"
