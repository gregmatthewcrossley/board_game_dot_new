const topicForm = document.getElementById('topic-form');
const topicField = document.getElementById('topic-field');
const previewArea = document.getElementById('preview');
const callToActionArea = document.getElementById('call-to-action');

topicForm.addEventListener(
  "submit", 
  function(e){ 
    callToActionArea.removeAttribute('style');
    previewArea.textContent = 'working... ';

    var xhr = new XMLHttpRequest();
    xhr.withCredentials = true;
    xhr.open('GET', '/functions/preview?topic='+encodeURIComponent(topicField.value));
    xhr.onload = function() {
      if (xhr.status === 200) {
        // show the generatd game's name
        previewArea.textContent = xhr.responseText;
        // show the call to action (stripe checkout session creation form)
        callToActionArea.setAttribute('style', 'display:block');
      }
      else {
        alert('Request failed.  Returned status of ' + xhr.status);
      }
    };
    xhr.send();

    e.preventDefault();
  }
);


