const express = require('express')
const path = require('path')
const enroll = require('./enrollAdmin')
const enrollUser = require('./registerUser')
const app = express()
const port = 3000


console.log("ON")

app.use(express.static('public'))

app.post('/enrollAdmin', function(req, res) {
  console.log('Enrolling admin')
  enroll.enrollAdminForDMV()
  res.setHeader('Content-Type', 'application/json');
  res.send(JSON.stringify({status:"ok", info: "Successfully enrolled Admin"}))
})

app.post('/enrollUser', function(req, res) {
  console.log('Enrolling User1')
  enrollUser.enrollUser()
  res.sendStatus(200)
})

app.listen(port, () => console.log(`Example app listening on port ${port}!`))
