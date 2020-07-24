
require "omniauth-facebook"
fb_id           = Rails.env.production? ? "#{@settings[:facebook_id_production]}" : "#{@settings[:facebook_id_development]}"
fb_secret       = Rails.env.production? ? "#{@settings[:facebook_secret_production]}" : "#{@settings[:facebook_secret_development]}"
config.omniauth :facebook, fb_id, fb_secret

