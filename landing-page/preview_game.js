const previewButton = document.getElementById('preview-button');
// const topicField = document.getElementById('topic-field');
const previewArea = document.getElementById('preview');
const callToActionArea = document.getElementById('call-to-action');

previewButton.addEventListener('click', function() {
  // re-hide the call to action area, if shown
  callToActionArea.removeAttribute('style');
  // remove any content in the preview area, replace with a "working..." message
  previewArea.textContent = 'working... ';
  // send the topic to a google function to get the preview content
  request_uri = '/functions/preview?topic='+encodeURIComponent(topicField.value);
  fetch(request_uri)
    .then(function (response) {
      return response.json();
    })
    .then(function (board_game_preview) {
      // add the generated game's name to the preview area
      previewArea.textContent = board_game_preview.name;
      // show the call to action (stripe checkout session creation form)
      callToActionArea.setAttribute('style', 'display:block');
    })
    .catch(function (err) {
        console.log("Something went wrong!", err);
    });
  }
);


