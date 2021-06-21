// define the refresh function
function refreshTopic() {
  fetch('/functions/random_topic')
    .then(function (response) {
      return response.json();
    })
    .then(function (random) {
      // add the generated game's name to the preview area
      document.getElementById('topic-field').value = random.topic;
      document.getElementById('topic-field').classList.remove('loading');
      document.getElementById('topic-refresh').classList.remove('loading');
    })
    .catch(function (err) {
        console.log("Something went wrong!", err);
    });
}

// refresh once on load
refreshTopic();

// refersh on click of the refresh button
document.getElementById('topic-refresh').addEventListener('click', function() {
  document.getElementById('topic-field').classList.add('loading');
  document.getElementById('topic-refresh').classList.add('loading');
  refreshTopic();
});


