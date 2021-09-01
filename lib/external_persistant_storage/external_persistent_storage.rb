class ExternalPersistentStorage
  # This is a wrapper class for the storage service(s) specified below
  # Note that all of the storage service classes below are duck-typed
  # to respond to:
  #  - save_string(topic, filename, string)
  #  - retrieve_string(topic, filename)
  #  - save_hash(topic, filename, hash)
  #  - retrieve_hash(topic, filename)
  #  - save_file(topic, filename, tempfile, public_pdf)
  #  - retrieve_file(topic, filename, public_pdf)
  #  - retrieve_public_pdf_url(topic, filename)

  require_relative './storage_services/google_cloud_storage.rb'
  CURRENT_STORAGE_SERVICE = GoogleCloudStorage
  
  extend CURRENT_STORAGE_SERVICE

end