
require "omniauth-office365"
o365_api_key      = Rails.env.production? ? "#{@settings[:o365_api_key_production]}" : "#{@settings[:o365_api_key_development]}"
o365_secret_key   = Rails.env.production? ? "#{@settings[:o365_secret_key_production]}" : "#{@settings[:o365_secret_key_development]}"
config.omniauth :office365, o365_api_key, o365_secret_key

