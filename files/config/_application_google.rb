
# Use certificates from the google-api-client gem
ENV['SSL_CERT_FILE'] = Gem.loaded_specs['google-api-client'].full_gem_path+'/lib/cacerts.pem'
