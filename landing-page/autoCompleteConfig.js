const autoCompleteJS = new autoComplete({ // API Basic Configuration Object
  selector: "#topic-field",
  threshold: 3,
  searchEngine: "loose",
  diacritics: true,
  wrapper: false,
  data: {
    src: topics
  },
  resultItem: {
    highlight: {
      render: true
    }
  },
  events: {
    input: {
      selection: (event) => {
        const selection = event.detail.selection.value;
          autoCompleteJS.input.value = selection;
        }
      }
    }
});