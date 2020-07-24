
require "omniauth-google-oauth2"
go_api_key      = Rails.env.production? ? "#{@settings[:google_api_key_production]}" : "#{@settings[:google_api_key_development]}"
go_secret_key   = Rails.env.production? ? "#{@settings[:google_secret_key_production]}" : "#{@settings[:google_secret_key_development]}"
config.omniauth :google_oauth2, go_api_key, go_secret_key

