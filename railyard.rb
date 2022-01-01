#
# Template: Railyard
#
# This template sets up a rails project with Bootstrap, some scaffolding 
# and authentication with support for Facebook, Twitter, Google, Linkedin
# and Microsoft login.
#
# Changes from previous version:
# - Completely rewritten to use Rails 7.0 and Bootstrap 5
# - Verified with Ruby 3.0.2, Rails 7.0, rbenv 1.2.0, npm 7.24.0.
# - Bootstrap compatible scaffolding views
#
# Copyright © 2014-2021 Spotwise
#
# Check the following web pages for information on how to setup
# authentication for each identity provider.
#
# Facebook: https://developers.facebook.com
# Twitter: https://dev.twitter.com
# Linkedin: https://www.linkedin.com/secure/developer
# Google: https://code.google.com/apis/console/
# Microsoft 365: https://portal.azure.com
#
# Check respective provider above for information on how to create
# app and get app ID and secret
#
# Production keys need to be unique for this application while
# development keys can be reused between applications
#
# NOTE Currently, this template must be started with the switch
# --css=bootstrap.

# TODO Configure settings
@settings = {
  application_name:                 "Test",
  application_url:                  "http://www.example.com",
  company_name:                     "Example Inc",
  copyright_year:                   "2021",
  login_local:                      true,
  login_facebook:                   true,
  login_twitter:                    true,
  login_linkedin:                   true,
  login_google:                     true,
  login_microsoft:                  true,
  facebook_id_production:           "000000000000",
  facebook_secret_production:       "000000000000",
  twitter_key_production:           "000000000000",
  twitter_secret_production:        "000000000000",
  linkedin_api_key_production:      "000000000000",
  linkedin_secret_key_production:   "000000000000",
  google_api_key_production:        "000000000000",
  google_secret_key_production:     "000000000000",
  microsoft_app_id_production:      "000000000000",
  microsoft_app_secret_production:  "000000000000",
  microsoft_directory_production:   "000000000000",
  facebook_id_development:          "000000000000",
  facebook_secret_development:      "000000000000",
  twitter_key_development:          "000000000000",
  twitter_secret_development:       "000000000000",
  linkedin_api_key_development:     "000000000000",
  linkedin_secret_key_development:  "000000000000",
  google_api_key_development:       "000000000000",
  google_secret_key_development:    "000000000000",
  microsoft_app_id_development:     "000000000000",
  microsoft_app_secret_development: "000000000000",
  microsoft_directory_development:  "000000000000"
}

# ========= NO CHANGES BELOW THIS LINE =========

# Load keys from separate file
begin

  if File.file?(ENV['HOME'] + '/.development_keys.rb')
    require ENV['HOME'] + '/.development_keys.rb'
  else
    require_relative 'development_keys'
  end

  @settings[:facebook_id_development]           = DevelopmentKeys::FACEBOOK_ID
  @settings[:facebook_secret_development]       = DevelopmentKeys::FACEBOOK_SECRET
  @settings[:twitter_key_development]           = DevelopmentKeys::TWITTER_KEY
  @settings[:twitter_secret_development]        = DevelopmentKeys::TWITTER_SECRET
  @settings[:linkedin_api_key_development]      = DevelopmentKeys::LINKEDIN_API_KEY
  @settings[:linkedin_secret_key_development]   = DevelopmentKeys::LINKEDIN_SECRET_KEY
  @settings[:google_api_key_development]        = DevelopmentKeys::GOOGLE_API_KEY
  @settings[:google_secret_key_development]     = DevelopmentKeys::GOOGLE_SECRET_KEY
  @settings[:microsoft_app_id_development]      = DevelopmentKeys::MICROSOFT_APP_ID
  @settings[:microsoft_app_secret_development]  = DevelopmentKeys::MICROSOFT_APP_SECRET
  @settings[:microsoft_directory_development]   = DevelopmentKeys::MICROSOFT_DIRECTORY

rescue LoadError
  puts <<EOS

No custom keys found. Copy the file development_keys.rb.sample to development_keys.rb and define your own keys.

EOS
end

# Create the directory structure for the provided file path to avoid file creation failing when copying files
def create_dir(source)
  FileUtils.mkdir_p(File.dirname(source))
end

# Read the contents from a file or from a URL
def read_uri(source)
  if source.match?(%r{https?://.*})
    uri = URI.parse(source)
    return uri.read
  else
    return File.read(source)
  end
end

# Helper method return the full path for supplementary files
def get_file_uri(source)
  return File.join(File.dirname(__FILE__), 'files/') + source if ENV['RAILS_TEMPLATE_DEBUG'].present?
  return 'https://raw.githubusercontent.com/spotwise/railyard/master/files/' + source
end

# Get the file contents, performing string interpolation
def get_file_contents(source)
  uri = get_file_uri(source)
  eval("\"" + read_uri(uri).gsub(/"/, '\"') + "\"")
end

# Get a file, performing string interpolation
def get_file(source, destination = nil, binary = false)
  destination ||= source
  create_dir(destination)
  uri = get_file_uri(source)
  if binary
    get(uri,destination, force: true)
  else
    File.write(destination, eval("\"" + read_uri(uri).gsub(/"/, '\"') + "\""))
  end
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
def login_microsoft
  @settings[:login_microsoft]
end
def login_oauth
  login_facebook || login_twitter || login_linkedin || login_google || login_microsoft
end

def create_scaffolding
  # Create scaffolding
  # TODO: Create an application specific data model instead of Author -> Books -> Reviews
  generate(:controller, "home index")
  generate(:controller, "dashboard index")
  generate(:scaffold, "Author user_id:integer name:string description:text --no-stylesheets")
  generate(:scaffold, "Book user_id:integer author_id:integer title:string description:text --no-stylesheets")
  generate(:scaffold, "Review user_id:integer book_id:integer comment:text rating:integer --no-stylesheets")
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

def add_omniauth

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
    generate(:migration, "AddTwitterToUsers tw_uid:string tw_name:string tw_nickname:string \
      tw_location:string tw_image:string tw_description:string tw_friends:integer \
      tw_followers:integer tw_statuses:integer tw_listed:integer --force")
      p << %w{ :tw_uid :tw_name :tw_nickname :tw_location :tw_image :tw_description :tw_friends :tw_followers :tw_statuses :tw_listed }
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

  if login_microsoft
    generate(:migration, "AddMicrosoftToUsers ms_uid:string ms_email:string ms_first_name:string ms_last_name:string \
      ms_name:string ms_image:text --force")
    p << %w{ :ms_uid :ms_email :ms_first_name :ms_last_name :ms_name :ms_image }
  end

  inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

    def user_params
      params.permit(#{p.join(", ")})
    end

  FILE
  end

  # Define API keys for the various OAuth providers. These keys are edited at the top of this file
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_facebook.rb'), :before => %r{^end$} if login_facebook
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_twitter.rb'), :before => %r{^end$} if login_twitter
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_linkedin.rb'), :before => %r{^end$} if login_linkedin
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_google.rb'), :before => %r{^end$} if login_google
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_microsoft.rb'), :before => %r{^end$} if login_microsoft

  providers = []
  providers << ":facebook" if login_facebook
  providers << ":twitter" if login_twitter
  providers << ":linkedin" if login_linkedin
  providers << ":google_oauth2" if login_google
  providers << ":azure_activedirectory_v2" if login_microsoft

  # Omniauth (https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)
  if login_oauth
    gsub_file "app/models/user.rb", %r{:validatable}, ":validatable, :omniauthable, :omniauth_providers => [#{providers.join(", ")}]"
    gsub_file 'config/routes.rb', "devise_for :users", 'devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }'

    get_file 'app/controllers/users/omniauth_callbacks_controller.rb'
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_facebook.rb'), :before => %r{^end$} if login_facebook
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_twitter.rb'), :before => %r{^end$} if login_twitter
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_linkedin.rb'), :before => %r{^end$} if login_linkedin
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_google.rb'), :before => %r{^end$} if login_google
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_microsoft.rb'), :before => %r{^end$} if login_microsoft
  end

  # Update the user model with roles
  prepend_file 'app/models/user.rb', get_file_contents('app/models/_user_require.rb')

  username = []
  username << "name" if login_local
  username << "fb_name" if login_facebook
  username << "tw_name" if login_twitter
  username << "li_name" if login_linkedin
  username << "go_name" if login_google
  username << "ms_name" if login_microsoft
  username << '"<no name>"'

  avatar = []
  avatar << "fb_image" if login_facebook
  avatar << "tw_image" if login_twitter
  avatar << "li_image" if login_linkedin
  avatar << "go_image" if login_google
  avatar << '"http://www.gravatar.com/avatar/\#{Digest::MD5.hexdigest(email)}"'

  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user.rb'), :before => %r{^end$}
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_facebook.rb'), :before => %r{^end$} if login_facebook
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_twitter.rb'), :before => %r{^end$} if login_twitter
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_linkedin.rb'), :before => %r{^end$} if login_linkedin
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_google.rb'), :before => %r{^end$} if login_google
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_microsoft.rb'), :before => %r{^end$} if login_microsoft

  inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

    def username
      #{username.join(" || ")}
    end

    def avatar
      #{avatar.join(" || ")}
    end

  FILE
  end
end

def update_content
  # First create the menu items based on existing models
  menu_model_items = ""
  all_models.sort.each do |c|
    menu_model_items += "<li class='nav-item'><%= link_to '#{c.pluralize}', '/#{c.tableize}', :class => 'nav-link'  %></li>\n              "
  end

  @settings[:footer] = footer
  @settings[:menu] = menu_model_items

  # Create the layout file
  get_file 'app/views/layouts/application.html.erb'

  # Download Bootstrap social icons
  run "wget -O app/assets/stylesheets/bootstrap-social.css https://github.com/lipis/bootstrap-social/raw/gh-pages/bootstrap-social.css"

  append_file 'app/assets/config/manifest.js', "\n//= link bootstrap-social.css\nw"

  append_file 'app/assets/stylesheets/application.bootstrap.scss', "#{get_file_contents('app/assets/stylesheets/_application.bootstrap.scss')}"

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

  # Add custom Javascript and stylesheets
  #append_file 'app/javascript/packs/application.js', get_file_contents('app/javascript/packs/_application.js')
  #get_file 'app/javascript/stylesheets/application.scss'

  # Replace the home page
  get_file 'app/views/home/index.html.erb'

  # Layout account pages
  get_file 'app/views/layouts/devise.html.erb'

  get_file     'app/views/devise/sessions/new.html.erb'
  append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_facebook.html.erb') if login_facebook
  append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_twitter.html.erb') if login_twitter
  append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_linkedin.html.erb') if login_linkedin
  append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_google.html.erb') if login_google
  append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_microsoft.html.erb') if login_microsoft
  append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_local.html.erb') if login_local

  get_file 'app/views/devise/registrations/new.html.erb'
  prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_microsoft.html.erb') if login_microsoft
  prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_google.html.erb') if login_google
  prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_linkedin.html.erb') if login_linkedin
  prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_twitter.html.erb') if login_twitter
  prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_facebook.html.erb') if login_facebook

  get_file 'app/views/devise/registrations/edit.html.erb'
  inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_facebook.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_facebook
  inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_twitter.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_twitter
  inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_linkedin.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_linkedin
  inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_google.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_google
  inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_microsoft.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_microsoft

  get_file 'app/views/devise/passwords/new.html.erb'
  inject_into_file 'config/locales/devise.en.yml', get_file_contents('config/locales/_devise.en.yml'), :before => %r{^    passwords:$}
  inject_into_file "config/application.rb", get_file_contents('config/_application_devise.rb'), :before => %r{^  end$}

  inject_into_file "config/application.rb", get_file_contents('config/_application_google.rb'), :before => %r{^  end$} if login_google

  #run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss"

  append_file "README.md", get_file_contents('_README.md')
end

def require_login
  # Add before filter to require login and ensure that tests pass
  all_models.sort.each do |c|
    inject_into_file "app/controllers/#{c.tableize}_controller.rb",
        "\n\tbefore_action :authenticate_user!\n\tload_and_authorize_resource\n\n",
        after: "< ApplicationController\n"

    inject_into_file "test/controllers/#{c.tableize}_controller_test.rb",
        "\n  include Devise::Test::IntegrationHelpers\n\n",
        after: "ActionDispatch::IntegrationTest\n"

    inject_into_file "test/controllers/#{c.tableize}_controller_test.rb",
        "    sign_in users(:one)\n",
        after: "setup do\n"

    inject_into_file "test/system/#{c.tableize}_test.rb",
        "\n  include Devise::Test::IntegrationHelpers\n\n",
        after: "ApplicationSystemTestCase\n"

    inject_into_file "test/system/#{c.tableize}_test.rb",
        "    sign_in users(:one)\n",
        after: "setup do\n"

  end

  inject_into_file "app/controllers/dashboard_controller.rb",
      "\n\tbefore_action :authenticate_user!\n\n",
      after: "< ApplicationController\n"

end

def add_test_data
  gsub_file 'test/fixtures/users.yml', %r{^one:}, '#one:'
  gsub_file 'test/fixtures/users.yml', %r{^two:}, '#two:'
  append_file 'test/fixtures/users.yml', "#{get_file_contents('test/fixtures/_users.yml')}"

  inject_into_file "test/controllers/dashboard_controller_test.rb",
      "#{get_file_contents('test/controllers/_dashboard_controller_test.rb')}",
      after: "ActionDispatch::IntegrationTest\n"
end

def add_seed_data
  # Add seed data to create a user
  if login_local
    append_file 'db/seeds.rb', get_file_contents('db/_seeds.rb')
    #rails_command "db:seed"
  end
end

def add_gems
  gem 'devise'
  gem 'importmap-rails'
  gem "omniauth", "~> 1.9.1"
  gem 'cancancan'
  gem 'role_model'
  gem 'omniauth-oauth2' if login_oauth
  gem 'omniauth-facebook' if login_facebook
  gem 'omniauth-twitter' if login_twitter
  gem 'omniauth-linkedin-oauth2' if login_linkedin
  gem 'google-api-client' if login_google
  gem 'omniauth-google-oauth2' if login_google
  gem 'omniauth-azure-activedirectory-v2' if login_microsoft
  gem 'sidekiq', '~> 6.3', '>= 6.3.1'
end

def add_bootstrap
  rails_command "css:install:bootstrap"
end

def add_users
  # Install Devise
  generate "devise:install"

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }", env: 'development'

  route "root to: 'home#index'"
  route "get 'dashboard' => 'dashboard#index'"

  # Create Devise User
  generate :devise, "User", "first_name", "last_name", "admin:boolean"

  # set admin boolean to false by default
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  # Create an ability file
  get_file 'app/models/ability.rb'

end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  content = <<-RUBY
    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end
  RUBY
  insert_into_file "config/routes.rb", "#{content}\n\n", after: "Rails.application.routes.draw do\n"
end

def extra_setup
  inject_into_file "config/application.rb", get_file_contents('config/_application_generators.rb'), :before => %r{^  end$}
  get_file 'lib/templates/erb/scaffold/_form.html.erb.tt'
  get_file 'lib/templates/erb/scaffold/edit.html.erb.tt'
  get_file 'lib/templates/erb/scaffold/index.html.erb.tt'
  get_file 'lib/templates/erb/scaffold/new.html.erb.tt'
  get_file 'lib/templates/erb/scaffold/show.html.erb.tt'
end

def add_swagger
  # append_file "Gemfile", "\n# Install gems"

  # gem 'rswag'
  # gem_group :development, :test do
  #   gem 'rspec-rails'
  #   gem 'rswag-specs'
  # end

  # Add support for Swagger
  # generate('rswag:specs:install')
  # generate('rswag:api:install')
  # generate('rswag:ui:install')
  # generate('rspec:install')

  # all_models.sort.each do |c|
  #   generate("rspec:swagger API::V1::#{c.pluralize}_Controller")
  # end

  # run('rails rswag:specs:swaggerize')
end


# Begin setup
source_paths

add_gems

after_bundle do
  extra_setup
  add_bootstrap
  add_users
  add_omniauth
  add_sidekiq
  create_scaffolding
  update_content
  require_login
  add_test_data
  add_seed_data

  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"
  rails_command "db:seed"

  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }

  say
  say "Ruby on Rails app successfully created!", :green
  say
  say "Switch to your app by running:"
  say "$ cd #{app_name}", :yellow
  say
  say "Then run:"
  say "$ bin/dev", :green
  say
end
