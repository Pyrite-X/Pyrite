#!/bin/bash

# Bash file used to update the running bot.

git fetch && git merge

docker build -t local/pyrite:latest -f Dockerfile .

docker compose up --no-deps -d gateway && docker compose up --no-deps -d webserver
