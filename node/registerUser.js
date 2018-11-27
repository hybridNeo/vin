'use strict';

module.exports = {
  enrollUser: function (username, mspid) {
    var Fabric_Client = require('fabric-client');
    var Fabric_CA_Client = require('fabric-ca-client');

    var path = require('path');
    var util = require('util');
    var os = require('os');

    var fabric_client = new Fabric_Client();
    var fabric_ca_client = null;
    var admin_user = null;
    var member_user = null;
    var store_path = path.join(__dirname, 'hfc-key-store');
    console.log('Store path:'+ store_path);

    Fabric_Client.newDefaultKeyValueStore({ path: store_path
    }).then((state_store) => {
        fabric_client.setStateStore(state_store);
        var crypto_suite = init_crypto_suite(store_path, Fabric_Client)
        fabric_client.setCryptoSuite(crypto_suite);
        var	tlsOptions = {
    	     trustedRoots: [],
    	      verify: false
          };
          fabric_ca_client = new Fabric_CA_Client('http://localhost:7054', null , '', crypto_suite);
          return fabric_client.getUserContext('admin', true);
        }).then((user_from_store) => {
          if (user_is_valid(user_from_store)) {
            console.log('Successfully loaded admin from persistence');
            admin_user = user_from_store;
          } else {
            throw new Error('Failed to get admin.... run enrollAdmin.js');
          }

          return fabric_ca_client.register({enrollmentID: username, role: 'client'}, admin_user);
        }).then((secret) => {
          console.log('Successfully registered ' + username + ' - secret:'+ secret);

          return fabric_ca_client.enroll({enrollmentID: username, enrollmentSecret: secret});
        }).then((enrollment) => {
          console.log('Successfully enrolled member user ' + username);
          return fabric_client.createUser(
            {username: username,
            mspid: mspid,
            cryptoContent: { privateKeyPEM: enrollment.key.toBytes(), signedCertPEM: enrollment.certificate }
          });
        }).then((user) => {
          member_user = user;

          return fabric_client.setUserContext(member_user);
        }).then(()=>{
          console.log(username + ' was successfully registered and enrolled and is ready to interact with the fabric network');

        }).catch((err) => {
          console.error('Failed to register: ' + err);
	         if(err.toString().indexOf('Authorization') > -1) {
		           console.error('Authorization failures may be caused by having admin credentials from a previous CA instance.\n' +
		             'Try again after deleting the contents of the store directory '+store_path);
	        }
        });
    }
};

function init_crypto_suite(store_path, fabric_client) {
  var crypto_suite = fabric_client.newCryptoSuite();
  var crypto_store = fabric_client.newCryptoKeyStore({path: store_path});
  crypto_suite.setCryptoKeyStore(crypto_store);
  return crypto_suite
};

function user_is_valid(user_from_store) {
  return user_from_store && user_from_store.isEnrolled()
}
