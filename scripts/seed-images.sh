#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
HUB="${1:?dockerhub user}"; SRC="${2:?source tag}"; NEW="${3:?new tag}"
REG="285065163560.dkr.ecr.ap-south-1.amazonaws.com"
REGION=ap-south-1

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$REG"

for svc in account-service customer-service frontend; do
  case "$svc" in
    account-service)  ecr_repo="novabank/account_service" ;;
    customer-service) ecr_repo="novabank/customer_service" ;;
    frontend)         ecr_repo="novabank/novabank_frontend" ;;
  esac

  docker pull "$HUB/novabank-$svc:$SRC"
  docker tag  "$HUB/novabank-$svc:$SRC" "$REG/$ecr_repo:$NEW"
  docker push "$REG/$ecr_repo:$NEW"

  for env in dev prod; do
    sed -i "s|repository:.*|repository: $REG/$ecr_repo|g" "envs/$env/$svc.yaml"
    sed -i "s|tag:.*|tag: \"$NEW\"|g" "envs/$env/$svc.yaml"
  done
done

echo "Done. Commit + push envs/*, then check scan results: aws ecr describe-image-scan-findings --repository-name novabank/novabank_frontend --image-id imageTag=$NEW"
