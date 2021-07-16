// makeButtonConfig.js
// Adds some triggers and events to the "make it! button"

const topicField = document.getElementById('topic-field');
const makeButton = document.getElementById('make-button');
const statusMessage = document.getElementById('status');
const cancelMakeButton = document.getElementById('cancel-make-button');
// const previewArea = document.getElementById('preview');
// const callToActionArea = document.getElementById('call-to-action');

makeButton.addEventListener('click', function() {
  // restyle the button on click
  makeButton.classList.add('working');

  // lock the input field
  topicField.setAttribute('disabled', 'true');

  // show a status text under the spinner
  statusMessage.textContent = 'researching ...';
  statusMessage.setAttribute('style', 'display:block');
  
  // show the cancel button
  cancelMakeButton.setAttribute('style', 'display:inline');

  // // re-hide the call to action area, if shown
  // callToActionArea.removeAttribute('style');
  // // remove any content in the preview area, replace with a "working..." message
  // previewArea.textContent = 'working... ';
  // // send the topic to a google function to get the preview content
  // request_uri = '/functions/preview?topic='+encodeURIComponent(topicField.value);
  // fetch(request_uri)
  //   .then(function (response) {
  //     return response.json();
  //   })
  //   .then(function (board_game_preview) {
  //     // add the generated game's name to the preview area
  //     previewArea.textContent = board_game_preview.name;
  //     // show the call to action (stripe checkout session creation form)
  //     callToActionArea.setAttribute('style', 'display:block');
  //   })
  //   .catch(function (err) {
  //       console.log("Something went wrong!", err);
  //   });
});

cancelMakeButton.addEventListener('click', function() {
  // restyle the button on click
  makeButton.classList.remove('working');

  // lock the input field
  topicField.setAttribute('disabled', 'false');

  // show a status text under the spinner
  statusMessage.textContent = 'researching ...';
  statusMessage.setAttribute('style', 'display:none');
  
  // show the cancel button
  cancelMakeButton.setAttribute('style', 'display:none');
});