#!/bin/bash

GREEN='\033[32m'
RESET='\033[0m'

printf "${GREEN}Starting ingress controller...${RESET}\n"
kubectl apply -k deploy/ingress

printf "${GREEN}Waiting for ingress controller to start...${RESET}"
while [[ -z $(kubectl -n ingress-nginx get pod --selector=app.kubernetes.io/component=controller 2>/dev/null | grep -E '([0-9]+)/\1' 2>/dev/null) ]]; do
  sleep 5
  printf "${GREEN}.${RESET}"
done
printf "\n${GREEN}Ingress controller is running.${RESET}\n"

printf "${GREEN}Configuring pods...${RESET}\n"
make deploy-apply
printf "${GREEN}Starting is detached.${RESET}\n"
