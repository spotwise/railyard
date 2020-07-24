#
# Template: Railyard
#
# This template sets up a rails project with Bootstrap, some scaffolding 
# and authentication with support for Facebook, Twitter, Google, Linkedin
# and Office365 login.
#
# Note: Webpacker needs to be installed:
#
#   bundle exec rake webpacker:install
#
# Changes from previous version:
# - Completely rewritten to use Rails 6 and Bootstrap 4
#
# Copyright © 2014-2020 Spotwise
#
# Check the following web pages for information on how to setup
# authentication for each identity provider.
#
# Facebook: https://developers.facebook.com
# Twitter: https://dev.twitter.com
# Linkedin: https://www.linkedin.com/secure/developer
# Google: https://code.google.com/apis/console/
# Office 365: https://manage.windowsazure.com
#
# Check respective provider above for information on how to create
# app and get app ID and secret
#
# Production keys need to be unique for this application while
# development keys can be reused between applications


# TODO Configure settings
@settings = {
  application_name:               "Test",
  application_url:                "http://www.example.com",
  company_name:                   "Example Inc",
  copyright_year:                 "2020",
  login_local:                    true,
  login_facebook:                 true,
  login_twitter:                  true,
  login_linkedin:                 true,
  login_google:                   true,
  login_office365:                true,
  facebook_id_production:         "000000000000",
  facebook_secret_production:     "000000000000",
  twitter_key_production:         "000000000000",
  twitter_secret_production:      "000000000000",
  linkedin_api_key_production:    "000000000000",
  linkedin_secret_key_production: "000000000000",
  google_api_key_production:      "000000000000",
  google_secret_key_production:   "000000000000",
  o365_api_key_production:        "000000000000",
  o365_secret_key_production:     "000000000000",
  facebook_id_development:        "000000000000",
  facebook_secret_development:    "000000000000",
  twitter_key_development:        "000000000000",
  twitter_secret_development:     "000000000000",
  linkedin_api_key_development:   "000000000000",
  linkedin_secret_key_development:"000000000000",
  google_api_key_development:     "000000000000",
  google_secret_key_development:  "000000000000",
  o365_api_key_development:       "000000000000",
  o365_secret_key_development:    "000000000000"
}

# Create scaffolding
# TODO: Create an application specific data model instead of Author -> Books -> Reviews
generate(:controller, "home index")
generate(:controller, "dashboard index")
generate(:scaffold, "Author user_id:integer name:string description:text --no-stylesheets")
generate(:scaffold, "Book user_id:integer author_id:integer title:string description:text --no-stylesheets")
generate(:scaffold, "Review user_id:integer book_id:integer comment:text rating:integer --no-stylesheets")


########## NO CHANGES REQUIRED BELOW THIS LINE ##########
#########################################################

# Load keys from separate file
begin

  if File.file?(ENV['HOME'] + '/.development_keys.rb')
    require ENV['HOME'] + '/.development_keys.rb'
  else
    require_relative 'development_keys'
  end

  @settings[:facebook_id_development]         = DevelopmentKeys::FACEBOOK_ID
  @settings[:facebook_secret_development]     = DevelopmentKeys::FACEBOOK_SECRET
  @settings[:twitter_key_development]         = DevelopmentKeys::TWITTER_KEY
  @settings[:twitter_secret_development]      = DevelopmentKeys::TWITTER_SECRET
  @settings[:linkedin_api_key_development]    = DevelopmentKeys::LINKEDIN_API_KEY
  @settings[:linkedin_secret_key_development] = DevelopmentKeys::LINKEDIN_SECRET_KEY
  @settings[:google_api_key_development]      = DevelopmentKeys::GOOGLE_API_KEY
  @settings[:google_secret_key_development]   = DevelopmentKeys::GOOGLE_SECRET_KEY
  @settings[:o365_api_key_development]        = DevelopmentKeys::O365_API_KEY
  @settings[:o365_secret_key_development]     = DevelopmentKeys::O365_SECRET_KEY

rescue LoadError
  puts <<EOS

No custom keys found. Copy the file development_keys.rb.sample to development_keys.rb and define your own keys.

EOS
end

def login_local
  @settings[:login_local]
end
def login_facebook
  @settings[:login_facebook]
end
def login_twitter
  @settings[:login_twitter]
end
def login_linkedin
  @settings[:login_linkedin]
end
def login_google
  @settings[:login_google]
end
def login_office365
  @settings[:login_office365]
end
def login_oauth
  login_facebook || login_twitter || login_linkedin || login_google || login_office365
end

# Create the directory structure for the provided file path to avoid file creation failing when copying files
def create_dir(source)
  FileUtils.mkdir_p(File.dirname(source))
end

# Helper method return the full path for supplementary files
def get_file_uri(source)
  return File.join(File.dirname(__FILE__), 'files/') + source if ENV['RAILS_TEMPLATE_DEBUG'].present?
  return 'https://raw.githubusercontent.com/spotwise/railyard/master/files/' + source
end

# Get the file contents, performing string interpolation
def get_file_contents(source)
  uri = get_file_uri(source)
  eval("\"" + File.read(uri).gsub(/"/, '\"') + "\"")
end

# Get a file, performing string interpolation
def get_file(source, destination = nil, binary = false)
  destination ||= source
  create_dir(destination)
  uri = get_file_uri(source)
  if binary
    get(uri,destination, force: true)
  else
    File.write(destination, eval("\"" + File.read(uri).gsub(/"/, '\"') + "\""))
  end
end

# Get a list of all the user defined models
def all_models
  Dir.glob("app/models/*.rb").map { |x|
    x.split("/").last.split(".").first.camelize unless x.end_with?("user.rb") or x.end_with?("ability.rb") or x.end_with?("application_record.rb")
  }.compact
end

def footer
  "&copy; <a href='#{@settings[:application_url]}'>#{@settings[:company_name]}</a> #{@settings[:copyright_year]}."
end

append_file "Gemfile", "\n# Install gems"

gem 'font-awesome-rails'
gem 'bootstrap-sass-extras'
gem 'devise'
gem 'cancancan'
gem 'role_model'
gem 'omniauth-oauth2' if login_oauth
gem 'omniauth-facebook' if login_facebook
gem 'omniauth-twitter' if login_twitter
gem 'omniauth-linkedin' if login_linkedin
gem 'google-api-client' if login_google
gem 'omniauth-google-oauth2' if login_google
gem 'omniauth-office365' if login_office365

run 'bundle install'
run 'yarn add bootstrap jquery popper.js'
generate 'bootstrap:install'

# Add support for Bootstrap & jQuery
after_bundle do
  inject_into_file "config/webpack/environment.js", get_file_contents('config/webpack/_environment.js'), :before => %r{^module.exports}
end

inject_into_file "app/javascript/packs/application.js", :before => /^require\("@rails\/ujs"\)\.start\(\)/ do <<-FILE
import 'bootstrap'
FILE
end

run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss"
append_file 'app/assets/stylesheets/application.scss', "#{get_file_contents('app/assets/stylesheets/_application.scss')}"
inject_into_file "app/assets/stylesheets/application.scss", :before => /^ \*= require_tree \./ do <<-FILE
 *= require bootstrap
FILE
end

# Setup Devise
generate("devise:install")
generate(:devise, "User")

# Migrate database
rake "db:migrate"

# Add before filter to require login
all_models.sort.each do |c|
  inject_into_file "app/controllers/#{c.tableize}_controller.rb",
      "\n\tbefore_action :authenticate_user!\n\tload_and_authorize_resource\n\n",
      after: "< ApplicationController\n"
      generate('bootstrap:themed', c.pluralize + ' --force')
end

# Create an ability file
get_file 'app/models/ability.rb'

# Change root page
route "root to: 'home#index'"
route "get 'dashboard' => 'dashboard#index'"

# Add roles mask to the user table
generate(:migration, "AddRolesMaskToUsers roles_mask:integer --force")

# Add columns to the user table for omniauth
generate(:migration, "AddNameToUsers name:string --force")
generate(:migration, "AddProviderToUsers provider:string uid:string --force")
rake "db:migrate"

p = %w{ :email :password :password_confirmation :remember_me :roles_mask :roles :provider :uid }

# Add columns to the user table for Facebook and Twitter
if login_facebook
  generate(:migration, "AddFacebookToUsers fb_uid:string fb_email:string fb_first_name:string fb_last_name:string \
    fb_name:string fb_location:string fb_image:string fb_nickname:string fb_url:string fb_gender:string \
    fb_locale:string fb_username:string --force")
  p << %w{ :fb_uid :fb_first_name :fb_last_name :fb_name :fb_location :fb_image :fb_nickname :fb_url :fb_gender :fb_locale :fb_username }
end

if login_twitter
  generate(:migration, "AddTwitterToUsers twitter_uid:string twitter_name:string twitter_nickname:string \
    twitter_location:string twitter_image:string twitter_description:string twitter_friends:integer \
    twitter_followers:integer twitter_statuses:integer twitter_listed:integer --force")
    p << %w{ :twitter_uid :twitter_name :twitter_nickname :twitter_location :twitter_image :twitter_description :twitter_friends :twitter_followers :twitter_statuses :twitter_listed }
end

if login_linkedin
  generate(:migration, "AddLinkedinToUsers li_uid:string li_email:string li_first_name:string li_last_name:string \
    li_name:string li_image:text li_headline:string li_industry:string --force")
  p << %w{ :li_uid :li_email :li_first_name :li_last_name :li_name :li_image :li_headline :li_industry }
end

if login_google
  generate(:migration, "AddGoogleToUsers go_uid:string go_email:string go_first_name:string go_last_name:string \
    go_name:string go_image:text --force")
  p << %w{ :go_uid :go_email :go_first_name :go_last_name :go_name :go_image }
end

if login_office365
  generate(:migration, "AddOffice365ToUsers o3_uid:string o3_email:string o3_first_name:string o3_last_name:string \
    o3_name:string o3_image:text --force")
  p << %w{ :o3_uid :o3_email :o3_first_name :o3_last_name :o3_name :o3_image }
end

inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

  def user_params
    params.permit(#{p.join(", ")})
  end

FILE
end

rake "db:migrate"

# Add seed data to create a user
if login_local
  append_file 'db/seeds.rb', get_file_contents('db/_seeds.rb')
  rake "db:seed"
end

run "bundle install"

# Add PostgreSQL in production for Heroku
gsub_file 'Gemfile', %r{gem 'sqlite3'.*$}, get_file_contents('Gemfile')

# Define API keys for the various OAuth providers. These keys are edited at the top of this file
inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_facebook.rb'), :before => %r{^end$} if login_facebook
inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_twitter.rb'), :before => %r{^end$} if login_twitter
inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_linkedin.rb'), :before => %r{^end$} if login_linkedin
inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_google.rb'), :before => %r{^end$} if login_google
inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_office365.rb'), :before => %r{^end$} if login_office365

providers = []
providers << ":facebook" if login_facebook
providers << ":twitter" if login_twitter
providers << ":linkedin" if login_linkedin
providers << ":google_oauth2" if login_google
providers << ":office365" if login_office365

# Omniauth (https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)
if login_oauth
  gsub_file "app/models/user.rb", %r{:validatable}, ":validatable, :omniauthable, :omniauth_providers => [#{providers.join(", ")}]"
  gsub_file 'config/routes.rb', "devise_for :users", 'devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }'
  
  get_file 'app/controllers/users/omniauth_callbacks_controller.rb'
  inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_facebook.rb'), :before => %r{^end$} if login_facebook
  inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_twitter.rb'), :before => %r{^end$} if login_twitter
  inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_linkedin.rb'), :before => %r{^end$} if login_linkedin
  inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_google.rb'), :before => %r{^end$} if login_google
  inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_office365.rb'), :before => %r{^end$} if login_office365
end

# Update the user model with roles
prepend_file 'app/models/user.rb', get_file_contents('app/models/_user_require.rb')

username = []
username << "name" if login_local
username << "fb_name" if login_facebook
username << "twitter_name" if login_twitter
username << "li_name" if login_twitter
username << "go_name" if login_google
username << "o3_name" if login_office365
username << '"<no name>"'

avatar = []
avatar << "fb_image" if login_facebook
avatar << "twitter_image" if login_twitter
avatar << "li_image" if login_linkedin
avatar << "go_image" if login_google
avatar << '"http://www.gravatar.com/avatar/\#{Digest::MD5.hexdigest(email)}"'

inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user.rb'), :before => %r{^end$}
inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_facebook.rb'), :before => %r{^end$} if login_facebook
inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_twitter.rb'), :before => %r{^end$} if login_twitter
inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_linkedin.rb'), :before => %r{^end$} if login_linkedin
inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_google.rb'), :before => %r{^end$} if login_google
inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_office365.rb'), :before => %r{^end$} if login_office365

inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

  def username
    #{username.join(" || ")}
  end

  def avatar
    #{avatar.join(" || ")}
  end

FILE
end

# First create the menu items based on existing models
menu_model_items = ""
all_models.sort.each do |c|
  menu_model_items += "<li class='nav-item'><%= link_to '#{c.pluralize}', '/#{c.pluralize.downcase}', :class => 'nav-link'  %></li>"
end

@settings[:footer] = footer
@settings[:menu] = menu_model_items

# Create the layout file
get_file 'app/views/layouts/application.html.erb'

# Download Bootstrap social icons
run "wget -O app/assets/stylesheets/bootstrap-social.css https://github.com/lipis/bootstrap-social/raw/gh-pages/bootstrap-social.css"

inject_into_file 'app/assets/stylesheets/application.scss', get_file_contents('app/assets/stylesheets/_application_require.scss'), :before => " *= require_self"
append_file 'app/assets/stylesheets/application.scss', "#{get_file_contents('app/assets/stylesheets/_application.scss')}"

# Redirect user to dashboard after having logged in
inject_into_file 'app/controllers/application_controller.rb', get_file_contents('app/controllers/_application_controller.rb'), :before => %r{^end$}

# Download images
get_file 'app/assets/images/banner-flowers.jpg', nil, true
get_file 'app/assets/images/bird.jpg', nil, true
get_file 'app/assets/images/seaweed.jpg', nil, true
get_file 'app/assets/images/shells.jpg', nil, true
get_file 'app/assets/images/logo.png', nil, true
get_file 'app/assets/images/logo-600px.png', nil, true
get_file 'app/assets/images/favicon.ico', nil, true
get_file 'app/assets/images/apple-touch-icon-72x72-precomposed.png', nil, true
get_file 'app/assets/images/apple-touch-icon-114x114-precomposed.png', nil, true
get_file 'app/assets/images/apple-touch-icon-144x144-precomposed.png', nil, true
get_file 'app/assets/images/apple-touch-icon-precomposed.png', nil, true

# Add custom Javascript
append_file 'app/javascript/packs/application.js', get_file_contents('app/javascript/packs/_application.js')

# Replace the home page
get_file 'app/views/home/index.html.erb'

# Layout account pages
get_file 'app/views/layouts/devise.html.erb'

get_file     'app/views/devise/sessions/new.html.erb'
append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_facebook.html.erb') if login_facebook
append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_twitter.html.erb') if login_twitter
append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_linkedin.html.erb') if login_linkedin
append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_google.html.erb') if login_google
append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_office365.html.erb') if login_office365
append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_local.html.erb') if login_local

get_file 'app/views/devise/registrations/new.html.erb'
prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_office365.html.erb') if login_office365
prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_google.html.erb') if login_google
prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_linkedin.html.erb') if login_linkedin
prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_twitter.html.erb') if login_twitter
prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_facebook.html.erb') if login_facebook

get_file 'app/views/devise/registrations/edit.html.erb'
inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_facebook.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_facebook
inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_twitter.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_twitter
inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_linkedin.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_linkedin
inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_google.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_google
inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_office365.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_office365

get_file 'app/views/devise/passwords/new.html.erb'
inject_into_file 'config/locales/devise.en.yml', get_file_contents('config/locales/_devise.en.yml'), :before => %r{^    passwords:$}
inject_into_file "config/application.rb", get_file_contents('config/_application_devise.rb'), :before => %r{^  end$}

inject_into_file "config/application.rb", get_file_contents('config/_application_google.rb'), :before => %r{^  end$} if login_google

append_file "README.md", get_file_contents('_README.md')

# Change from 'btn-default' to 'default-secondary' in all views
Dir.glob("app/views/*/*.html.erb").each do |f|
  gsub_file f, %r{btn-default}, "btn-secondary"
end
