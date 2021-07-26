class ExternalPersistentStorage
  # This is a wrapper class for the storage service specified below

  require_relative './storage_services/google_cloud_storage.rb'
  DEFAULT_STORAGE_SERVICE = GoogleCloudStorage
  
  extend DEFAULT_STORAGE_SERVICE

end