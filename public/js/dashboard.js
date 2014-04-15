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
  // reload every 10 sec
  setTimeout(reloadNagiosWidget, 10000);
}

function reloadImages() {
  var now = new Date();
  $('img').each(function(index) {
    var url = $(this).attr('src').replace(/&\d+$/, '');
    $(this).attr('src', url + '&' + now.getTime());
  });
  // reload every 120 sec
  setTimeout(reloadImages, 120000);
}

function rotateTabs(){
    var tabs = $('.nav-tabs > li');
    var active = tabs.filter('.active');
    var next = active.next('li').length? active.next('li').find('a') : tabs.filter(':first-child').find('a');
    next.tab('show')
}


$(document).ready(function() {
  reloadNagiosWidget();
  reloadImages();

  setInterval(rotateTabs, 7000)
});
