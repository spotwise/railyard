#
# Template: Railyard
#
# This template sets up a rails project with Tailwind, some scaffolding
# and authentication support.
#
# Changes from previous version:
# - Rewritten to use Rails 7.1 and Tailwind
# - Simplified design with fewer tweaks, leaving more for the individual implementation
# - Verified with Ruby 3.2.2, Rails 7.1.2, rbenv 1.2.0, npm 9.6.6
#
# Copyright © 2014-2024 Spotwise
#
# Check the following web pages for information on how to setup
# authentication for each identity provider.
#
# Facebook: https://developers.facebook.com
# Linkedin: https://www.linkedin.com/secure/developer
# Google: https://code.google.com/apis/console/
#
# Check respective provider above for information on how to create
# app and get app ID and secret
#
# Production keys need to be unique for this application while
# development keys can be reused between applications
#
# NOTE Current issues:
# - This template must be started with the switch --css=bootstrap
# - Swagger API generation is currently commented out
# - Run with environment variable RAILS_TEMPLATE_DEBUG set to load local files
#
# This script reads resources from the online repository. To instead load resources locally,
# set the environment variable RAILS_TEMPLATE_DEBUG to any value, i.e.
#
#   export RAILS_TEMPLATE_DEBUG=1
#

# TODO Configure settings
@settings = {
  application_name:                 "Test",
  application_url:                  "http://www.example.com",
  company_name:                     "Example Inc",
  copyright_year:                   "2023",
  login_local:                      true,
  login_facebook:                   true,
  login_linkedin:                   true,
  login_google:                     true,
  facebook_id_production:           "000000000000",
  facebook_secret_production:       "000000000000",
  linkedin_api_key_production:      "000000000000",
  linkedin_secret_key_production:   "000000000000",
  google_api_key_production:        "000000000000",
  google_secret_key_production:     "000000000000",
  facebook_id_development:          "000000000000",
  facebook_secret_development:      "000000000000",
  linkedin_api_key_development:     "000000000000",
  linkedin_secret_key_development:  "000000000000",
  google_api_key_development:       "000000000000",
  google_secret_key_development:    "000000000000"
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
  @settings[:linkedin_api_key_development]      = DevelopmentKeys::LINKEDIN_API_KEY
  @settings[:linkedin_secret_key_development]   = DevelopmentKeys::LINKEDIN_SECRET_KEY
  @settings[:google_api_key_development]        = DevelopmentKeys::GOOGLE_API_KEY
  @settings[:google_secret_key_development]     = DevelopmentKeys::GOOGLE_SECRET_KEY

rescue LoadError
  puts <<EOS

No custom keys found. Copy the file development_keys.rb.sample to development_keys.rb and define your own keys.

EOS
end

##################################
### Helper functions
##################################

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

# Get a list of all the user defined models
def all_models
  Dir.glob("app/models/*.rb").map { |x|
    x.split("/").last.split(".").first.camelize unless x.end_with?("user.rb") or x.end_with?("ability.rb") or x.end_with?("application_record.rb")
  }.compact
end

def login_local
  @settings[:login_local]
end
def login_facebook
  @settings[:login_facebook]
end
def login_linkedin
  @settings[:login_linkedin]
end
def login_google
  @settings[:login_google]
end
def login_oauth
  login_facebook || login_linkedin || login_google
end

def footer
  "&copy; <a href='#{@settings[:application_url]}'>#{@settings[:company_name]}</a> #{@settings[:copyright_year]}."
end

##################################
### Gems
##################################

def add_gems
  gem 'devise-tailwinded'
  gem 'devise'
  gem 'cancancan'

  gem 'role_model'
  gem "omniauth", "~> 1.9.1"
  gem 'omniauth-oauth2' if login_oauth
  gem 'omniauth-facebook' if login_facebook
  gem 'omniauth-linkedin-oauth2' if login_linkedin
  gem 'google-api-client' if login_google
  gem 'omniauth-google-oauth2' if login_google

  #gem 'sidekiq', '~> 6.3', '>= 6.3.1'
end

##################################
### Content functions
##################################

def add_tailwind
  #generate "devise:views:tailwinded"
end

def add_alpine
  #rails_command "importmap:install"
  run "bin/importmap pin alpinejs"
  
  append_file 'app/assets/stylesheets/application.css', get_file_contents('app/assets/stylesheets/_application_alpine.css')
  append_file 'app/javascript/application.js', get_file_contents('app/javascript/_application_alpine.js')
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
      fb_name:string fb_image:string  --force")
    p << %w{ :fb_uid :fb_first_name :fb_last_name :fb_name :fb_image }
  end

  if login_linkedin
    generate(:migration, "AddLinkedinToUsers li_uid:string li_email:string li_first_name:string li_last_name:string \
      li_name:string li_image:text --force")
    p << %w{ :li_uid :li_email :li_first_name :li_last_name :li_name :li_image }
  end

  if login_google
    generate(:migration, "AddGoogleToUsers go_uid:string go_email:string go_first_name:string go_last_name:string \
      go_name:string go_image:text --force")
    p << %w{ :go_uid :go_email :go_first_name :go_last_name :go_name :go_image }
  end

  inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

    def user_params
      params.permit(#{p.join(", ")})
    end

  FILE
  end

  # Define API keys for the various OAuth providers. These keys are edited at the top of this file
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_facebook.rb'), :before => %r{^end$} if login_facebook
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_linkedin.rb'), :before => %r{^end$} if login_linkedin
  inject_into_file "config/initializers/devise.rb", get_file_contents('config/initializers/_devise_google.rb'), :before => %r{^end$} if login_google

  providers = []
  providers << ":facebook" if login_facebook
  providers << ":linkedin" if login_linkedin
  providers << ":google_oauth2" if login_google

  # Omniauth (https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)
  if login_oauth
    gsub_file "app/models/user.rb", %r{:validatable}, ":validatable, :omniauthable, :omniauth_providers => [#{providers.join(", ")}]"
    gsub_file 'config/routes.rb', "devise_for :users", 'devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }'

    get_file 'app/controllers/users/omniauth_callbacks_controller.rb'
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_facebook.rb'), :before => %r{^end$} if login_facebook
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_linkedin.rb'), :before => %r{^end$} if login_linkedin
    inject_into_file 'app/controllers/users/omniauth_callbacks_controller.rb', get_file_contents('app/controllers/users/_omniauth_callbacks_controller_google.rb'), :before => %r{^end$} if login_google
  end

  # Update the user model with roles
  prepend_file 'app/models/user.rb', get_file_contents('app/models/_user_require.rb')

  username = []
  username << "name" if login_local
  username << "fb_name" if login_facebook
  username << "go_name" if login_google
  username << "li_name" if login_linkedin
  username << '"<no name>"'

  avatar = []
  avatar << "fb_image" if login_facebook
  avatar << "go_image" if login_google
  avatar << "li_image" if login_linkedin
  avatar << '"http://www.gravatar.com/avatar/\#{Digest::MD5.hexdigest(email)}"'

  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user.rb'), :before => %r{^end$}
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_facebook.rb'), :before => %r{^end$} if login_facebook
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_linkedin.rb'), :before => %r{^end$} if login_linkedin
  inject_into_file 'app/models/user.rb', get_file_contents('app/models/_user_google.rb'), :before => %r{^end$} if login_google

  inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

    def username
      #{username.join(" || ")}
    end

    def avatar
      if Rails.env.production?
        #{avatar.join(" || ")}
      else
        # Facebook profile picture doesn't work in development (Q4 2023)
        #{(avatar - ['fb_image']).join(" || ")}
      end
    end

  FILE
  end
end

def add_seed_data
  # Add seed data to create a user
  if login_local
    append_file 'db/seeds.rb', get_file_contents('db/_seeds.rb')
    #rails_command "db:seed"
  end
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

def add_test_data
  gsub_file 'test/fixtures/users.yml', %r{^one:}, '#one:'
  gsub_file 'test/fixtures/users.yml', %r{^two:}, '#two:'
  append_file 'test/fixtures/users.yml', "#{get_file_contents('test/fixtures/_users.yml')}"

  inject_into_file "test/controllers/dashboard_controller_test.rb",
      "#{get_file_contents('test/controllers/_dashboard_controller_test.rb')}",
      after: "ActionDispatch::IntegrationTest\n"
end

def add_users

  # Install Devise
  generate "devise:install"
  generate "devise:views"

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

def create_scaffolding
  # Create scaffolding
  # TODO: Create an application specific data model instead of Author -> Books -> Reviews
  generate(:controller, "home index")
  generate(:controller, "dashboard index")
  generate(:scaffold, "Author user_id:integer name:string description:text --no-stylesheets")
  generate(:scaffold, "Book user_id:integer author_id:integer title:string description:text --no-stylesheets")
  generate(:scaffold, "Review user_id:integer book_id:integer comment:text rating:integer --no-stylesheets")
end

def pre_setup
  #inject_into_file "config/application.rb", get_file_contents('config/_application_generators.rb'), :before => %r{^  end$}
  #get_file 'lib/templates/erb/scaffold/_form.html.erb.tt'
  #get_file 'lib/templates/erb/scaffold/edit.html.erb.tt'
  #get_file 'lib/templates/erb/scaffold/index.html.erb.tt'
  #get_file 'lib/templates/erb/scaffold/new.html.erb.tt'
  #get_file 'lib/templates/erb/scaffold/show.html.erb.tt'

  # Install Devise
  #generate "devise:install"
  #generate "devise User"

end

def post_setup
  # Make development server accessible on the local network
  insert_into_file "Procfile.dev", " -b 0.0.0.0", after: "server -p 3000"

  run "bin/importmap pin alpinejs"

  append_file 'app/assets/stylesheets/application.css', get_file_contents('app/assets/stylesheets/_application_alpine.css')
  append_file 'app/javascript/application.js', get_file_contents('app/javascript/_application_alpine.js')

  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"
  rails_command "db:seed"

  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }
end

def fix_destroy_redirects
  all_models.sort.each do |c|
    gsub_file "app/controllers/#{c.tableize}_controller.rb",
      'was successfully destroyed."',
      'was successfully destroyed.", status: 303'
  end
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

def update_content
  # First create the menu items based on existing models
  #menu_model_items = ""
  #all_models.sort.each do |c|
  #  menu_model_items += "<li class='nav-item'><%= link_to '#{c.pluralize}', '/#{c.tableize}', :class => 'nav-link'  %></li>\n              "
  #end

  #@settings[:footer] = footer
  #@settings[:menu] = menu_model_items

  # Create the layout file
  #get_file 'app/views/layouts/application.html.erb'
  inject_into_file "app/views/layouts/application.html.erb", get_file_contents('app/views/layouts/_application_head.html.erb'), :before => %r{^  </head>$}
  inject_into_file "app/views/layouts/application.html.erb", get_file_contents('app/views/layouts/_application_navbar.html.erb'), :before => %r{^    <main}

  # Redirect user to dashboard after having logged in
  inject_into_file 'app/controllers/application_controller.rb', get_file_contents('app/controllers/_application_controller.rb'), :before => %r{^end$}

  # Download images
  get_file 'app/assets/images/logo.png', nil, true
  get_file 'app/assets/images/logo-600px.png', nil, true
  get_file 'app/assets/images/favicon.ico', nil, true
  get_file 'app/assets/images/apple-touch-icon-72x72-precomposed.png', nil, true
  get_file 'app/assets/images/apple-touch-icon-114x114-precomposed.png', nil, true
  get_file 'app/assets/images/apple-touch-icon-144x144-precomposed.png', nil, true
  get_file 'app/assets/images/apple-touch-icon-precomposed.png', nil, true

  # Replace the home page
  get_file 'app/views/home/index.html.erb'

  get_file     'app/views/devise/sessions/new.html.erb'
  #append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_facebook.html.erb') if login_facebook
  #append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_linkedin.html.erb') if login_linkedin
  #append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_google.html.erb') if login_google
  #append_file 'app/views/devise/sessions/new.html.erb', get_file_contents('app/views/devise/sessions/_new_local.html.erb') if login_local

  get_file 'app/views/devise/registrations/new.html.erb'
  #prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_google.html.erb') if login_google
  #prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_linkedin.html.erb') if login_linkedin
  #prepend_file 'app/views/devise/registrations/new.html.erb', get_file_contents('app/views/devise/registrations/_new_facebook.html.erb') if login_facebook

  get_file 'app/views/devise/registrations/edit.html.erb'
  #inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_facebook.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_facebook
  #inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_linkedin.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_linkedin
  #inject_into_file 'app/views/devise/registrations/edit.html.erb', get_file_contents('app/views/devise/registrations/_edit_google.html.erb'), :before => %r{^<!--SOCIAL-->$} if login_google

  get_file 'app/views/devise/passwords/new.html.erb'

  get_file 'app/views/devise/shared/_error_messages.html.erb'

  inject_into_file 'config/locales/devise.en.yml', get_file_contents('config/locales/_devise.en.yml'), :before => %r{^    passwords:$}
  inject_into_file "config/application.rb", get_file_contents('config/_application_devise.rb'), :before => %r{^  end$}

  inject_into_file "config/application.rb", get_file_contents('config/_application_google.rb'), :before => %r{^  end$} if login_google

  append_file "README.md", get_file_contents('_README.md')
end

# Begin setup
source_paths

add_gems

after_bundle do
  pre_setup
  add_tailwind
  #add_alpine
  add_users
  add_omniauth
  #add_sidekiq
  create_scaffolding
  update_content
  require_login
  add_test_data
  add_seed_data
  #fix_destroy_redirects
  post_setup

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
