$('#myTab a').click(function (e) {
  e.preventDefault()
  $(this).tab('show')
});

$(document).on('click', '#nagios-refresh', function (e) {
  var request = $.ajax({
    url: "/ajax/nagios",
    type: "GET"
  });
  request.done(function(data) {
    $("#nagios").html(data);
  });
});

function reloadNagiosWidget() {
  var request = $.ajax({
    url: "/ajax/nagios",
    type: "GET"
  });
  request.done(function(data) {
    $("#nagios").html(data);
  });
  setTimeout(reloadNagiosWidget, 10000);
}

$(document).ready(function() {
  reloadNagiosWidget();
});

