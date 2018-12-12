$('#enroll-admin').click( function() {
  var data = {}
  data.adminMSP = document.getElementById("admin-form").elements[0].value;
  var response = $.ajax({
    type: 'POST',
    url: 'http://192.168.1.129:3000/enrollAdmin',
    data: JSON.stringify(data),
    contentType: 'application/json',
    complete: function(data) {
      document.getElementById('here').innerHTML = "Enrolled Admin";
    }
  })
});

$('#enroll-user').click( function() {
  var data = {};
  data.username = document.getElementById("username_form").elements[0].value;
  data.mspid = document.getElementById("username_form").elements[1].value;
  console.log(data.username)
  var response = $.ajax({
    type: 'POST',
    url: 'http://192.168.1.129:3000/enrollUser',
    data: JSON.stringify(data),
    contentType: 'application/json',
    success: function(data) {
      document.getElementById('userResponse').innerHTML = 'Enrolled User'
    }
  })
})

$('#invoke-chaincode').click( function() {
  var data = {}
  data.functionName = document.getElementById("invoke-form").elements[0].value;
  data.arg1 = document.getElementById("invoke-form").elements[1].value;
  data.arg2 = document.getElementById("invoke-form").elements[2].value;
  data.arg3 = document.getElementById("invoke-form").elements[3].value;
  var response = $.ajax({
    type: 'POST',
    url: 'http://192.168.1.129:3000/invokeFunction',
    data: JSON.stringify(data),
    contentType: 'application/json',
    success: function(data) {
      document.getElementById('invokeResponse').innerHTML = 'Invoked'
    },
  })
})

$('#query-chaincode').click( function() {
  var data = {}
  data.vin = document.getElementById("query-form").elements[0].value;
  var response = $.ajax({
    type: 'POST',
    url: 'http://192.168.1.129:3000/queryChaincode',
    data: JSON.stringify(data),
    contentType: 'application/json',
    success: function(data) {
      document.getElementById('queryResponse').innerHTML = data.owner
    }
  })
})
