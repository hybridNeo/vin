const express = require('express')
const path = require('path')
const enrollUser = require('./registerUser')
const bodyParser = require('body-parser')
var Fabric_Client = require('fabric-client');
var Fabric_CA_Client = require('fabric-ca-client');
var util = require('util');
var os = require('os');
const app = express()
const port = 3000


app.use(express.static('public'))
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json())

app.post('/enrollAdmin', function(req, res) {
  console.log('Enrolling admin')
  var fabric_client = new Fabric_Client();
  var fabric_ca_client = null;
  var admin_user = null;
  var member_user = null;
  var store_path = path.join(__dirname, 'hfc-key-store');
  console.log(' Store path:'+store_path);
  Fabric_Client.newDefaultKeyValueStore({ path: store_path
  }).then((state_store) => {
      fabric_client.setStateStore(state_store);
      var crypto_suite = Fabric_Client.newCryptoSuite();
      var crypto_store = Fabric_Client.newCryptoKeyStore({path: store_path});
      crypto_suite.setCryptoKeyStore(crypto_store);
      fabric_client.setCryptoSuite(crypto_suite);
      var	tlsOptions = {
    	   trustedRoots: [],
    	    verify: false
        };
        fabric_ca_client = new Fabric_CA_Client('http://localhost:7054', tlsOptions , 'ca.dmv.vin.gov', crypto_suite);
        return fabric_client.getUserContext('admin', true);
      }).then((user_from_store) => {
        if (user_from_store && user_from_store.isEnrolled()) {
          console.log('Successfully loaded admin from persistence');
          admin_user = user_from_store;
          return null;
        } else {
          return fabric_ca_client.enroll({
            enrollmentID: 'admin',
            enrollmentSecret: 'adminpw'
          }).then((enrollment) => {
            console.log('Successfully enrolled admin user "admin"');
            return fabric_client.createUser(
                {username: 'admin',
                    mspid: req.body.adminMSP,
                    cryptoContent: { privateKeyPEM: enrollment.key.toBytes(), signedCertPEM: enrollment.certificate }
                  });
                }).then((user) => {
                  admin_user = user;
                  return fabric_client.setUserContext(admin_user);
                }).catch((err) => {
                  console.error('Failed to enroll and persist admin. Error: ' + err.stack ? err.stack : err);
                  throw new Error('Failed to enroll admin');
                });
              }
            }).then(() => {
              console.log('Assigned the admin user to the fabric client ::' + admin_user.toString());
            }).catch((err) => {
              console.error('Failed to enroll admin: ' + err);
            })
            res.setHeader('Content-Type', 'application/json');
            res.send(JSON.stringify({status:"ok", info: "Successfully enrolled Admin"}))
})

app.post('/enrollUser', function(req, res) {
  var username = req.body.username
  var mspid = req.body.mspid
  console.log('Enrolling ' + username + ' with MSP: ' + mspid)
  enrollUser.enrollUser(username, mspid)
  res.sendStatus(200)
})

app.post('/invokeFunction', function(req, res) {
    var functionName = req.body.functionName
    var arg1 = req.body.arg1
    var arg2 = req.body.arg2
    var arg3 = req.body.arg3
    console.log(functionName)
    var fabric_client = new Fabric_Client();
    var channel = fabric_client.newChannel('vin-main-channel');
    var peer = fabric_client.newPeer('grpc://localhost:7051');
    channel.addPeer(peer);
    var order = fabric_client.newOrderer('grpc://localhost:7050')
    channel.addOrderer(order);
    var member_user = null;
    var store_path = path.join(__dirname, 'hfc-key-store');
    console.log('Store path:'+store_path);
    var tx_id = null;
    Fabric_Client.newDefaultKeyValueStore({ path: store_path
    }).then((state_store) => {
    	fabric_client.setStateStore(state_store);
    	var crypto_suite = Fabric_Client.newCryptoSuite();
    	var crypto_store = Fabric_Client.newCryptoKeyStore({path: store_path});
    	crypto_suite.setCryptoKeyStore(crypto_store);
    	fabric_client.setCryptoSuite(crypto_suite);
    	return fabric_client.getUserContext('admin', true);
    }).then((user_from_store) => {
    	if (user_from_store && user_from_store.isEnrolled()) {
    		console.log('Successfully loaded user1 from persistence');
    		member_user = user_from_store;
    	} else {
    		throw new Error('Failed to get user1.... run registerUser.js');
    	}
    	tx_id = fabric_client.newTransactionID();
    	console.log("Assigning transaction_id: ", tx_id._transaction_id);
    	var request = {
    		chaincodeId: 'vin_chaincode',
    		fcn: functionName,
    		args: [arg1, arg2, arg3],
    		chainId: 'vin-main-channel',
    		txId: tx_id
    	};
    	return channel.sendTransactionProposal(request);
    }).then((results) => {
    	var proposalResponses = results[0];
    	var proposal = results[1];
    	let isProposalGood = false;
    	if (proposalResponses && proposalResponses[0].response &&
    		proposalResponses[0].response.status === 200) {
    			isProposalGood = true;
    			console.log('Transaction proposal was good');
    		} else {
    			console.error('Transaction proposal was bad');
          res.sendStatus(400)
    		}
    		if (isProposalGood) {
    			console.log(util.format(
    				'Successfully sent Proposal and received ProposalResponse: Status - %s, message - "%s"',
    				proposalResponses[0].response.status, proposalResponses[0].response.message));
    				var request = {
    					proposalResponses: proposalResponses,
    					proposal: proposal
    				};
    				var transaction_id_string = tx_id.getTransactionID();
    				var promises = [];
    				var sendPromise = channel.sendTransaction(request);
    				promises.push(sendPromise);
    				let event_hub = channel.newChannelEventHub(peer);
    				let txPromise = new Promise((resolve, reject) => {
    					let handle = setTimeout(() => {
    						event_hub.unregisterTxEvent(transaction_id_string);
    						event_hub.disconnect();
    						resolve({event_status : 'TIMEOUT'});
    					}, 3000);
    					event_hub.registerTxEvent(transaction_id_string, (tx, code) => {
    						clearTimeout(handle);

    						var return_status = {event_status : code, tx_id : transaction_id_string};
    						if (code !== 'VALID') {
    							console.error('The transaction was invalid, code = ' + code);
                  res.sendStatus(400)
    							resolve(return_status);
    						} else {
    							console.log('The transaction has been committed on peer ' + event_hub.getPeerAddr());
    							resolve(return_status);
    						}
    					}, (err) => {
    						reject(new Error('There was a problem with the eventhub ::'+err));
    					},
    					{disconnect: true}
    				);
    				event_hub.connect();
    			});
    			promises.push(txPromise);
    			return Promise.all(promises);
    		} else {
    			console.error('Failed to send Proposal or receive valid response. Response null or status is not 200. exiting...');
          res.sendStatus(400)
    			throw new Error('Failed to send Proposal or receive valid response. Response null or status is not 200. exiting...');
    		}
    	}).then((results) => {
    		console.log('Send transaction promise and event listener promise have completed');
    		if (results && results[0] && results[0].status === 'SUCCESS') {
    			console.log('Successfully sent transaction to the orderer.');
    		} else {
    			console.error('Failed to order the transaction. Error code: ' + results[0].status);
          res.sendStatus(400)
    		}
    		if(results && results[1] && results[1].event_status === 'VALID') {
    			console.log('Successfully committed the change to the ledger by the peer');
    		} else {
    			console.log('Transaction failed to be committed to the ledger due to ::'+results[1].event_status);
          res.sendStatus(400)
    		}
    	}).catch((err) => {
    		console.error('Failed to invoke successfully :: ' + err);
        res.sendStatus(400)
    	});
    res.sendStatus(200)
})

app.post('/queryChaincode', function(req, res) {
  var fabric_client = new Fabric_Client();
  var channel = fabric_client.newChannel('vin-main-channel');
  var peer = fabric_client.newPeer('grpc://localhost:7051');
  channel.addPeer(peer);
  var member_user = null;
  var store_path = path.join(__dirname, 'hfc-key-store');
  console.log('Store path:'+store_path);
  var tx_id = null;
  Fabric_Client.newDefaultKeyValueStore({ path: store_path
  }).then((state_store) => {
  	fabric_client.setStateStore(state_store);
  	var crypto_suite = Fabric_Client.newCryptoSuite();
  	var crypto_store = Fabric_Client.newCryptoKeyStore({path: store_path});
  	crypto_suite.setCryptoKeyStore(crypto_store);
  	fabric_client.setCryptoSuite(crypto_suite);
  	return fabric_client.getUserContext('user1', true);
  }).then((user_from_store) => {
  	if (user_from_store && user_from_store.isEnrolled()) {
  		console.log('Successfully loaded user1 from persistence');
  		member_user = user_from_store;
  	} else {
  		throw new Error('Failed to get user1.... run registerUser.js');
  	}
  	const request = {
  		chaincodeId: 'vin_chaincode',
  		fcn: 'getCar',
  		args: [req.body.vin]
  	};
  	return channel.queryByChaincode(request);
  }).then((query_responses) => {
  	console.log("Query has completed, checking results");
  	if (query_responses && query_responses.length == 1) {
  		if (query_responses[0] instanceof Error) {
  			console.error("error from query = ", query_responses[0]);
  		} else {
  			console.log("Response is ", query_responses[0].toString());
        res.setHeader("Content-Type", "application/json");
        res.send({
          owner: query_responses[0].toString()
        })
  		}
  	} else {
  		console.log("No payloads were returned from query");
  	}
  }).catch((err) => {
  	console.error('Failed to query successfully :: ' + err);
  });
})

app.listen(port, () => console.log(`Example app listening on port ${port}!`))
