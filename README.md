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

1. Run `docker compose up -d` to launch a local SLURM cluster.
2. Within the *c2* node, set the JSON web token: `export $(docker compose exec c2 scontrol token)`
3. Test that you can access the SLURM API documentation: `curl -k -vvvv -H X-SLURM-USER-TOKEN:${SLURM_JWT} -H X-SLURM-USER-NAME:root -X GET 'http://localhost:9200/openapi/v3' > docs.json`
4. Submit a SLURM job: `curl -X POST "http://localhost:9200/slurm/v0.0.37/job/submit" -H "X-SLURM-USER-NAME:root" -H "X-SLURM-USER-TOKEN:${SLURM_JWT}" -H "Content-Type: application/json" -d @rest_api_test.json`
5. Check that the SLURM job completed successfully: `docker compose exec c1 cat /root/test.out`
