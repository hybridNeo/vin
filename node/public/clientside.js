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
  var response = $.ajax({
    type: 'POST',
    url: 'http://192.168.1.129:3000/enrollUser',
    success: function(data) {
      document.getElementById('userResponse').innerHTML = 'Enrolled User'
    }
  })
})
