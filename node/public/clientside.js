$('#enroll-admin').click( function() {
  var response = $.ajax({
    type: 'POST',
    url: 'http://192.168.1.129:3000/enrollAdmin',
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
  var response = $.ajax({
    type: 'POST',
    url: 'http://192.168.1.129:3000/invokeFunction',
    success: function(data) {
      document.getElementById('invokeResponse').innerHTML = 'Coming Soon'
    }
  })
})

$('#query-chaincode').click( function() {
  var response = $.ajax({
    type: 'GET',
    url: 'http://192.168.1.129:3000/queryChaincode',
    success: function(data) {
      document.getElementById('queryResponse').innerHTML = 'Coming Soon'
    }
  })
})
