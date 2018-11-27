const express = require('express')
const path = require('path')
const enroll = require('./enrollAdmin')
const enrollUser = require('./registerUser')
const invoke = require('./invoke')
const bodyParser = require('body-parser')
const app = express()
const port = 3000


console.log("ON")

app.use(express.static('public'))
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json())

app.post('/enrollAdmin', function(req, res) {
  console.log('Enrolling admin')
  enroll.enrollAdminForDMV()
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
    invoke.invokeChaincode(functionName, arg1, arg2, arg3)
    res.sendStatus(200)
})

app.get('/queryChaincode', function(req, res) {
  console.log('Pinged Query')
  res.sendStatus(200)
})

app.listen(port, () => console.log(`Example app listening on port ${port}!`))
