#!/bin/bash

mkdir runnerf && cd runnerf

curl -o actions-runner-linux-x64-2.325.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.325.0/actions-runner-linux-x64-2.325.0.tar.gz

tar xzf ./actions-runner-linux-x64-2.325.0.tar.gz

./config.sh --url https://github.com/stemdo-labs/final-project-gestion-rrhh-backend-Dfausben --token BQ3DEMU4BREP7O2QBHCSGNTIIHTHU --labels finalp --unattended

bash run.sh &

cd ..

mkdir runnerb && cd runnerb

curl -o actions-runner-linux-x64-2.325.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.325.0/actions-runner-linux-x64-2.325.0.tar.gz

tar xzf ./actions-runner-linux-x64-2.325.0.tar.gz

./config.sh --url https://github.com/stemdo-labs/final-project-gestion-rrhh-frontend-Dfausben --token BQ3DEMXGZLF6EEBYHALH6H3IIHTHQ  --labels finalp --unattended

bash run.sh &