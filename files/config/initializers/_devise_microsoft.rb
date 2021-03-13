
require "omniauth-azure-activedirectory-v2"
microsoft_app_id = Rails.env.production? ? "#{@settings[:microsoft_app_id_production]}" : "#{@settings[:microsoft_app_id_development]}"
microsoft_app_secret = Rails.env.production? ? "#{@settings[:microsoft_app_secret_production]}" : "#{@settings[:microsoft_app_secret_development]}"
microsoft_directory = Rails.env.production? ? "#{@settings[:microsoft_directory_production]}" : "#{@settings[:microsoft_directory_development]}"
config.omniauth :azure_activedirectory_v2, client_id: microsoft_app_id, client_secret: microsoft_app_secret, tenant_id: microsoft_directory

