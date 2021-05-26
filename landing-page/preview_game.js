const topicForm = document.getElementById('topic-form');
const topicField = document.getElementById('topic-field');
const previewArea = document.getElementById('preview');
const loadingText = document.createTextNode('working ...');

topicForm.addEventListener(
  "submit", 
  function(e){ 
    previewArea.appendChild(loadingText);
    var xhr = new XMLHttpRequest();
    xhr.withCredentials = true;
    xhr.open('GET', '/functions/preview?topic='+encodeURIComponent(topicField.value));
    xhr.onload = function() {
      if (xhr.status === 200) {
        var previewText = document.createTextNode(xhr.responseText);
        previewArea.appendChild(previewText);
      }
      else {
        alert('Request failed.  Returned status of ' + xhr.status);
      }
    };
    xhr.send();

    e.preventDefault();
  }
);


