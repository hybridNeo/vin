echo "############################################"
echo "#     Generating Crypto Material           #"
echo "############################################"
echo
cryptogen generate --config=crypto-config.yaml

export FABRIC_CFG_PATH=$PWD

echo
echo
echo
echo "############################################"
echo "#      Creating Channel Configuration      #"
echo "############################################"
echo

mkdir ./channel-artifacts
export CHANNEL_NAME=test
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block -channelID $CHANNEL_NAME
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/DMVMSPanchors.tx -channelID $CHANNEL_NAME -asOrg DMVMSP

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ManufacturersMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ManufacturersMSP

echo
echo
echo
echo "############################################"
echo "#         Starting Fabric Network          #"
echo "############################################"
echo

export COMPOSE_PROJECT_NAME=vin_main_network
export IMAGE_TAG=1.3.0
docker-compose -f docker-compose-cli.yaml up -d


echo "############################################"
echo "#     Generating Crypto Material           #"
echo "############################################"
echo
cryptogen generate --config=crypto-config.yaml

export FABRIC_CFG_PATH=$PWD

echo
echo
echo
echo "############################################"
echo "#      Creating Channel Configuration      #"
echo "############################################"
echo

mkdir ./channel-artifacts
export CHANNEL_NAME=vin-main-channel
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block -channelID $CHANNEL_NAME
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/DMVMSPanchors.tx -channelID $CHANNEL_NAME -asOrg DMVMSP

configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ManufacturersMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ManufacturersMSP






echo
echo
echo
echo "############################################"
echo "#       Executing Chaincode on Peers       #"
echo "############################################"
echo

export CHAINCODE_PATH=github.com/chaincode/vin_chaincode/
export CHAINCODE_NAME=vin_chaincode
export CHAINCODE_VERSION=0.0.1
export ORDERER=orderer.vin.gov:7050


docker exec cli peer channel create -c $CHANNEL_NAME -f channel-artifacts/channel.tx -o orderer.vin.gov:7050 --tls true --cafile "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/vin.gov/orderers/orderer.vin.gov/msp/tlscacerts/tlsca.vin.gov-cert.pem"

docker exec cli peer channel join -b $CHANNEL_NAME.block

docker exec cli peer channel update -o orderer.vin.gov:7050 -c $CHANNEL_NAME -f ./channel-artifacts/DMVMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/vin.gov/orderers/orderer.vin.gov/msp/tlscacerts/tlsca.vin.gov-cert.pem

#docker exec -e "CORE_PEER_LOCALMSPID=DMVMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dmv.vin.gov/users/Admin@dmv.vin.gov/msp" cli peer chaincode install -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -p $CHAINCODE_PATH

#docker exec -e "CORE_PEER_LOCALMSPID=DMVMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dmv.vin.gov/users/Admin@dmv.vin.gov/msp" cli peer chaincode instantiate -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -C $CHANNEL_NAME -o $ORDERER -c '{"Args":[""]}' -P "OR ('OrdererMSP.member')"
