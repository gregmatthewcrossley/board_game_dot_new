// Populate topic
var topic_span = document.getElementById('topic');
var query = window.location.search.substring(1);
var vars = query.split("&");
for (var i=0;i<vars.length;i++) {
  var pair = vars[i].split("=");
  if (pair[0] == "topic") {
    topic_span.textContent = pair[1];
  }
}