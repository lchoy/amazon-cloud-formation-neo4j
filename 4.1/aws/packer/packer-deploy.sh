#!/bin/bash

export VERSION=4.1.1
packer build \
    -var "neo4j_edition=enterprise" \
    -var "neo4j_version=1:4.1.1" \
    packer-template-test.json

packer build \
    -var "neo4j_edition=community" \
    -var "neo4j_version=1:4.1.1" \
    packer-template-test.json

#export PROFILE=govcloud
#export AWS_PROFILE=govcloud
#packer build \
#    -var "neo4j_edition=enterprise" \
#    -var "neo4j_version=1:4.1.1" \
#    -var "region=us-gov-east-1" \
#    -var "destination_regions=us-gov-west-1" \
#    -var "instance_type=t3.micro" \
#    -var "base_owner=513442679011" \
#    packer-template-test.json