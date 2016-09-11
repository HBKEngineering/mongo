# About this Repo

This is a fork of the Git repo of the Docker [official image](https://docs.docker.com/docker-hub/official_repos/) for [mongo](https://registry.hub.docker.com/_/mongo/). See [the Docker Hub page](https://registry.hub.docker.com/_/mongo/) for the full readme on how to use this Docker image and for information regarding contributing and issues. Among other things, it is limited to Mongo 3.2 and contains the MongoDB Cloud Manager agents (backup and monitoring.) 

It is also based partially off of the work of @ulexus, [here](https://github.com/Ulexus/docker-mms-agent) and [here](https://github.com/Ulexus/docker-mms-backup).

We use it in conjuction with [Dokku Mongo](https://github.com/dokku/dokku-mongo).

It has very basic Travis tests, but they are not tested/being used.