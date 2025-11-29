#!/bin/bash

# Bash file used to start the bot with docker compose.

git fetch && git merge

docker build -t local/pyrite:latest -f Dockerfile .

docker compose up -d
