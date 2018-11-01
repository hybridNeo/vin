package main

import (
	"encoding/json"
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

type Car struct {
	Owner		string `json:"owner"`
}


type PendingTransfer struct {
	Creator		string `json:"creator"`
	TargetVehicle	string `json:"targetVehicle"`
}


func (c *Car) Init(stub shim.ChaincodeStubInterface) peer.Response {
	return shim.Success(nil)
}


func (c *Car) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
	function, args := stub.GetFunctionAndParameters()
	var result string
	var err error
	if function == "createCar" {
		result, err = createCar(stub, args)
	} else if function == "getCar" {
		result, err = getCar(stub, args)
	} else if function == "createCarTransfer" {
		result, err = createCarTransfer(stub, args)
	} else if function == "fulfillCarTransfer" {
		result, err = fulfillCarTransfer(stub, args)
	}

	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success([]byte(result))
}

// args = [VIN, Owner]
func createCar(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("incorrect number of arguments: need owner and vin")
	}
	car := &Car{args[1]}
	carAsJSON, _ := json.Marshal(car)
	err := stub.PutState(args[0], carAsJSON)
	if err != nil {
		return "", fmt.Errorf("could not put car on ledger")
	}
	return args[0], nil
}


// args = [VIN]
func getCar(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 1 {
		return "", fmt.Errorf("incorrect args: need vin and user")
	}
	value, err := stub.GetState(args[0])
	if err != nil {
		return "", fmt.Errorf("failed to get car %s with error %s", args[0], err)
	} else if value == nil {
		return "", fmt.Errorf("asset not found %s", args[0])
	}
	return string(value), nil
}


// args = [CarReceiver/DMV, VIN]
func fulfillCarTransfer(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("incorrect args")
	}
	value, err := stub.GetState("pending:" + args[0] + ":" + args[1])
	if err != nil {
		return "", fmt.Errorf("failed to get pending transfer %s with error %s", "pending:" + args[0], err)
	}
	tx := PendingTransfer{}
	err = json.Unmarshal(value, &tx)
	if err != nil {
		return "", fmt.Errorf("pending transfer %s is improperly formatted", "pending:" + args[0])
	}
	car := &Car{args[0]}
	carAsJSON, _ := json.Marshal(car)
	err = stub.PutState(args[1], carAsJSON)
	if err != nil {
		return "", fmt.Errorf("could not re-add car to chain")
	}
	err = stub.DelState("pending:" + args[0] + ":" + args[1])
	if err != nil {
		return "", fmt.Errorf("could not delete pending transfer from chain")
	}
	return args[0], nil
}


// args = [VIN, currentOwner, newOwner]
func createCarTransfer(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 3 {
		return "", fmt.Errorf("incorrect args: need vin, creator and target")
	} else if !carExists(stub, args[0]) {
		return "", fmt.Errorf("car does not exist; cannot be transfered")
	} else if !userOwnsCar(stub, args[0], args[1]) {
		return "", fmt.Errorf("user does not have permission to transfer car")
	}
	pending := &PendingTransfer{args[1], args[0]}
	txAsBytes, _ := json.Marshal(pending)
	err := stub.PutState("pending:" + args[2] + ":" + args[0], txAsBytes)
	if err != nil {
		return "", fmt.Errorf("could not put user on ledger")
	}
	return args[0], nil
}

func isIn(a string, list []string) bool {
	for _, b := range list {
		if b == a {
			return true
		}
	}
	return false
}


func carExists(stub shim.ChaincodeStubInterface, vin string) bool {
	value, err := stub.GetState(vin)
	if err != nil {
		return false
	} else if value == nil {
		return false
	}
	return true
}


func userOwnsCar(stub shim.ChaincodeStubInterface, vin string, user string) bool {
	value, err := stub.GetState(vin)
	if err != nil {return false}
	car := Car{}
	json.Unmarshal(value, &car)
	if car.Owner == user {return true}
	return false
}


func main() {
	if err := shim.Start(new(Car)); err != nil {
		fmt.Printf("Error starting vin chaincode: %s", err)
	}
}

