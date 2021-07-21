// Populate Download Key
var topic_span = document.getElementById('topic');
var download_key_a = document.getElementById('download_link');
var query = window.location.search.substring(1);
var vars = query.split("&");
for (var i=0;i<vars.length;i++) {
  var pair = vars[i].split("=");
  if (pair[0] == "topic") {
    topic_span.textContent = decodeURI(pair[1]);
  }
  if (pair[0] == "download_key") {
    url = "https://boardgame.new/functions/download?download_key=" + pair[1];
    download_key_a.textContent = url;
    download_key_a.href = url;
  }
}