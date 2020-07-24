
require "omniauth-twitter"
twitter_key     = Rails.env.production? ? "#{@settings[:twitter_key_production]}" : "#{@settings[:twitter_key_development]}"
twitter_secret  = Rails.env.production? ? "#{@settings[:twitter_secret_production]}" : "#{@settings[:twitter_secret_development]}"
config.omniauth :twitter, twitter_key, twitter_secret

