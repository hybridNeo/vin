echo
echo
echo
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
echo "#              Creating Channel            #"
echo "############################################"
echo

export CHAINCODE_PATH=github.com/chaincode/vin_chaincode/
export CHAINCODE_NAME=vin_chaincode
export CHAINCODE_VERSION=0.0.1
export ORDERER=orderer.vin.gov:7050


docker exec cli peer channel create -c $CHANNEL_NAME -f channel-artifacts/channel.tx -o orderer.vin.gov:7050 --tls true --cafile "/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/vin.gov/orderers/orderer.vin.gov/msp/tlscacerts/tlsca.vin.gov-cert.pem"



echo
echo
echo
echo "############################################"
echo "#      Joining DMV Peer 0 to Channel       #"
echo "############################################"
echo

docker exec cli peer channel join -b $CHANNEL_NAME.block

echo
echo
echo
echo "############################################"
echo "#      Joining DMV Peer 1 to Channel       #"
echo "############################################"
echo

docker exec cli /bin/bash -c "export CORE_PEER_ADDRESS=peer1.dmv.vin.gov:7051 && export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dmv.vin.gov/peers/peer1.dmv.vin.gov/tls/ca.crt && peer channel join -b $CHANNEL_NAME.block"

echo
echo
echo
echo "############################################"
echo "#  Joining Manufacturers Peer 0 to Channel #"
echo "############################################"
echo

docker exec cli /bin/bash -c "export CORE_PEER_ADDRESS=peer0.manufacturers.vin.gov:7051 && export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/peers/peer0.manufacturers.vin.gov/tls/ca.crt && export CORE_PEER_LOCALMSPID=ManufacturersMSP && export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/users/Admin@manufacturers.vin.gov/msp && peer channel join -b $CHANNEL_NAME.block"

echo
echo
echo
echo "############################################"
echo "#  Joining Manufacturers Peer 1 to Channel #"
echo "############################################"
echo

docker exec cli /bin/bash -c "export CORE_PEER_ADDRESS=peer1.manufacturers.vin.gov:7051 && export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/peers/peer1.manufacturers.vin.gov/tls/ca.crt && export CORE_PEER_LOCALMSPID=ManufacturersMSP && export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/users/Admin@manufacturers.vin.gov/msp && peer channel join -b $CHANNEL_NAME.block"

echo
echo
echo
echo "############################################"
echo "#          Updating DMV Anchor Peer        #"
echo "############################################"
echo

docker exec cli peer channel update -o orderer.vin.gov:7050 -c $CHANNEL_NAME -f ./channel-artifacts/DMVMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/vin.gov/orderers/orderer.vin.gov/msp/tlscacerts/tlsca.vin.gov-cert.pem

echo
echo
echo
echo "############################################"
echo "#    Updating Manufacturers Anchor Peer    #"
echo "############################################"
echo

docker exec cli /bin/bash -c "export CORE_PEER_ADDRESS=peer0.manufacturers.vin.gov:7051 && export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/peers/peer0.manufacturers.vin.gov/tls/ca.crt && export CORE_PEER_LOCALMSPID=ManufacturersMSP && export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/users/Admin@manufacturers.vin.gov/msp && peer channel update -o orderer.vin.gov:7050 -c $CHANNEL_NAME -f ./channel-artifacts/ManufacturersMSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/vin.gov/orderers/orderer.vin.gov/msp/tlscacerts/tlsca.vin.gov-cert.pem"

echo
echo
echo
echo "############################################"
echo "#      Install Chaincode on DMV Peer 0     #"
echo "############################################"
echo

docker exec cli peer chaincode install -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -p $CHAINCODE_PATH

echo
echo
echo
echo "############################################"
echo "#      Install Chaincode on DMV Peer 1     #"
echo "############################################"
echo

docker exec cli /bin/bash -c "export CORE_PEER_ADDRESS=peer1.dmv.vin.gov:7051 && export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/dmv.vin.gov/peers/peer1.dmv.vin.gov/tls/ca.crt && peer chaincode install -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -p $CHAINCODE_PATH"

echo
echo
echo
echo "############################################"
echo "# Install chaincode on Manufacturer Peer 0 #"
echo "############################################"
echo

docker exec cli /bin/bash -c "export CORE_PEER_ADDRESS=peer0.manufacturers.vin.gov:7051 && export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/peers/peer0.manufacturers.vin.gov/tls/ca.crt && export CORE_PEER_LOCALMSPID=ManufacturersMSP && export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/users/Admin@manufacturers.vin.gov/msp && peer chaincode install -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -p $CHAINCODE_PATH"

echo
echo
echo
echo "############################################"
echo "# Install chaincode on Manufacturer Peer 1 #"
echo "############################################"
echo

docker exec cli /bin/bash -c "export CORE_PEER_ADDRESS=peer1.manufacturers.vin.gov:7051 && export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/peers/peer1.manufacturers.vin.gov/tls/ca.crt && export CORE_PEER_LOCALMSPID=ManufacturersMSP && export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/manufacturers.vin.gov/users/Admin@manufacturers.vin.gov/msp && peer chaincode install -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -p $CHAINCODE_PATH"


echo
echo
echo
echo "############################################"
echo "#     Instantiate Chaincode on Channel     #"
echo "############################################"
echo

docker exec cli peer chaincode instantiate -o orderer.vin.gov:7050 -C $CHANNEL_NAME --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/vin.gov/orderers/orderer.vin.gov/msp/tlscacerts/tlsca.vin.gov-cert.pem -n $CHAINCODE_NAME -v $CHAINCODE_VERSION -c '{"Args":[]}' # -P "AND ('DMVMSP.peer', 'ManufacturersMSP.peer')"
