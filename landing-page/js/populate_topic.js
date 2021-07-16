// Populate Topic
// If there is a topic included as a query string in the URL, 
// populate the input field with it

var topic_span = document.getElementById('topic');
var query = window.location.search.substring(1); // get the full URL
var vars = query.split("&"); // get the topic string
for (var i=0;i<vars.length;i++) {
  var pair = vars[i].split("=");
  if (pair[0] == "topic") { // if a query string parameter called "topic" exists ...
    topic_span.textContent = pair[1]; // ... update the input field with that topic
  }
}