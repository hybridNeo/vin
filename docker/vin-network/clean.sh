function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.vin_chaincode.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

rm -rf channel-artifacts
rm -rf crypto-config

export COMPOSE_PROJECT_NAME=vin_main_network
export IMAGE_TAG=1.3.0

docker-compose -f docker-compose-cli.yaml down --volumes --remove-orphans

removeUnwantedImages

docker kill $(docker ps -aq)
docker rm $(docker ps -aq)

docker network prune -f

