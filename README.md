# Slurm REST Docker Cluster

# Table of contents

- [Slurm REST Docker Cluster](#slurm-rest-docker-cluster)
- [Table of contents](#table-of-contents)
- [Introduction](#introduction)
- [REST API](#rest-api)

# Introduction

[This is a fork of the SLURM Docker repo here.](https://github.com/giovtorres/slurm-docker-cluster)

[The principal difference is that the dependencies required for the SLURM REST API have been included in the image build.](https://slurm.schedmd.com/rest.html)

# REST API

Run `docker compose up -d` to launch a local SLURM cluster.

Within the *c2* node, set the JSON web token: `export $(docker compose exec c2 scontrol token)`

Test that the SLURM_JWT environment variable is set: `echo $SLURM_JWT`

Test that you can view the OpenAPI documentation: `curl -k -vvvv -H X-SLURM-USER-TOKEN:$SLURM_JWT -H X-SLURM-USER-NAME:root -X GET 'http://localhost:9200/openapi/v3'`

Export the API version: `export SLURM_API_VERSION=v0.0.37`

curl -k -vvvv "http://c2:9200/slurm/${SLURM_API_VERSION}/job/submit" -X POST -H X-SLURM-USER-TOKEN:$SLURM_JWT -H X-SLURM-USER-NAME:root -H Content-Type:application/json -d '{ "job": { "environment": {"test": "env" }, "script": "touch test.txt" } }'

curl -k -vvvv "http://c2:9200/slurm/${SLURM_API_VERSION}/job/21" -H X-SLURM-USER-TOKEN:$SLURM_JWT -H X-SLURM-USER-NAME:root -H Content-Type:application/json
