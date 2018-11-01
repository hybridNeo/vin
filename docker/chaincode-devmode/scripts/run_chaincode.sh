peer chaincode install -p chaincode/vin_chaincode -n mycc -v 0
sleep 4
peer chaincode instantiate -n mycc -v 0 -c '{"Args":[]}' -C myc
sleep 4
peer chaincode invoke -n mycc -c '{"Args":["createCar", "abc123", "Chevrolet"]}' -C myc
sleep 5
peer chaincode invoke -n mycc -c '{"Args":["createCarTransfer", "abc123", "Chevrolet", "Dealer"]}' -C myc
sleep 5
peer chaincode invoke -n mycc -c '{"Args":["fulfillCarTransfer", "Dealer", "abc123"]}' -C myc
sleep 3
peer chaincode invoke -n mycc -c '{"Args":["getCar", "abc123"]}' -C myc
