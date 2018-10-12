package main

import(
	"fmt"
	"encoding/json"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

type Car struct {
	Owner		string	`json:"owner"`
}

type User struct {
	Role		string `json:"role"`
}

type PendingTransfer struct {
	Creator		string `json:"creator"`
	TargetVehicle	string `json:"targetVehicle"`
}

func (c *Car) Init(stub shim.ChaincodeStubInterface) peer.Response {
	user := &User{"DMV"}
	userAsJSON, _ := json.Marshal(user)
	_ = stub.PutState("DMV", userAsJSON)
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
	}else if function == "createUser" {
		result, err = createUser(stub, args)
	} else if function == "getUser" {
		result, err = getUser(stub, args)
	}

	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success([]byte(result))
}


// args = [Username, Role, UserCalling]
func createUser(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 3 {
		return "", fmt.Errorf("Incorrect number of arguments. Need username and role.")
	}
	funcRoles := []string{"DMV"}
	if isValidUserRole(stub, args[2], funcRoles) == false {
		return "", fmt.Errorf("User not permitted to make other users")
	}
	user := &User{args[1]}
	userAsJSON, _ := json.Marshal(user)
	err := stub.PutState(args[0], userAsJSON)
	if err != nil {
		return "", fmt.Errorf("Could not put user on ledger")
	}
	return args[0], nil
}


// args = [VIN, UserCalling]
func createCar(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("Incorrect number of arguments. Need owner then VIN.")
	}
	funcRoles := []string{"DMV", "MANUFACTURER"}
	if isValidUserRole(stub, args[1], funcRoles) == false {
		return "", fmt.Errorf("User not permitted to create cars")
	}
	car := &Car{args[1]}
	carAsJSON, _ := json.Marshal(car)
	err := stub.PutState(args[0], carAsJSON)
	if err != nil {
		return "", fmt.Errorf("Could not put car on ledger")
	}
	return args[0], nil
}


// args = [VIN, UserCalling]
func getCar(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("Incorrect args")
	}
	value, err := stub.GetState(args[0])
	if err != nil {
		return "", fmt.Errorf("Failed to get car %s with error %s", args[0], err)
	} else if value == nil {
		return "", fmt.Errorf("Asset not found %s", args[0])
	} else {
		car := Car{}
		json.Unmarshal(value, &car)
		if car.Owner != args[1] && !isValidUserRole(stub, args[1], []string{"DMV"}) {
			return "", fmt.Errorf("User not permitted to view car")
		}
	}
	return string(value), nil
}


// args = [Username]
func getUser(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 1 {
		return "", fmt.Errorf("Incorrect args")
	}
	value, err := stub.GetState(args[0])
	if err != nil {
		return "", fmt.Errorf("Failed to get car %s with error %s", args[0], err)
	}
	if value == nil {
		return "", fmt.Errorf("Asset not found %s", args[0])
	}
	return string(value), nil
}

// TODO find valid users to fulfill transfers/ Allow DMV????
// args = [CarReciever/DMV, VIN]
func fulfillCarTransfer(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 2 {
		return "", fmt.Errorf("Incorrect args")
	}
	value, err := stub.GetState("pending:" + args[0] + ":" + args[1])
	if err != nil {
		return "", fmt.Errorf("Failed to get pending transfer %s with error %s", "pending:" + args[0], err)
	}
	tx := PendingTransfer{}
	err = json.Unmarshal(value, &tx)
	if err != nil {
		return "", fmt.Errorf("Pending transfer %s is improperly formatted", "pending:" + args[0])
	}
	car := &Car{args[0]}
	carAsJSON, _ := json.Marshal(car)
	err = stub.PutState(args[1], carAsJSON)
	if err != nil {
		return "", fmt.Errorf("Could not re-add car to chain")
	}
	err = stub.DelState("pending:" + args[0] + ":" + args[1])
	if err != nil {
		return "", fmt.Errorf("Could not delete pending transfer from chain")
	}
	return args[0], nil
}


// args = [VIN, currentOwner, newOwner]
// TODO Verify users?
func createCarTransfer(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	if len(args) != 3 {
		return "", fmt.Errorf("Incorrect args. Need VIN, creator and target")
	} else if !carExists(stub, args[2]) {
		return "", fmt.Errorf("Car does not exist. Cannot be transfered")
	} else if !userOwnsCar(stub, args[0], args[1]) {
		return "", fmt.Errorf("User does not have permission to transfer car")
	}
	pending := &PendingTransfer{args[1], args[0]}
	txAsBytes, _ := json.Marshal(pending)
	err := stub.PutState("pending:" + args[2] + ":" + args[0], txAsBytes)
	if err != nil {
		return "", fmt.Errorf("Could not put user on ledger")
	}
	return args[0], nil
}


func isValidUserRole(stub shim.ChaincodeStubInterface, userToGet string,  list []string) bool {
	value, err := stub.GetState(userToGet)
	if err != nil { return false }
	user := User{}
	err = json.Unmarshal(value, &user)
	if err != nil {return false}
	if is_in(user.Role, list) {
		return true
	} else {return false}
}


func is_in(a string, list []string) bool {
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

