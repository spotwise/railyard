
require "omniauth-linkedin-openid"
li_api_key      = Rails.env.production? ? "#{@settings[:linkedin_api_key_production]}" : "#{@settings[:linkedin_api_key_development]}"
li_secret_key   = Rails.env.production? ? "#{@settings[:linkedin_secret_key_production]}" : "#{@settings[:linkedin_secret_key_development]}"
config.omniauth :linked_in, li_api_key, li_secret_key

