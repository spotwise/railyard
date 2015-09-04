#
# Template: Fifteen Five
#
# This template sets up a rails project with
# Bootstrap, a nice theme, some scaffolding
# and authentication with support for 
# Facebook, Twitter, Google and Linkedin login
#
# Changes from previous version:
# - Full width hero image
#
# Copyright © 2014-2015 Spotwise 
#

# TODO: Change as appropriately
footer = '&copy; <a href="http://www.example.com">Example Inc</a> 2015.'

# TODO: Turn on and off login options
login_local = true
login_facebook = true
login_twitter = true
login_linkedin = true
login_google = true

login_oauth = login_facebook || login_twitter || login_linkedin || login_google

# TODO: Specify oauth provider keys
# Facebook: https://developers.facebook.com
# Twitter: https://dev.twitter.com
# Linkedin: https://www.linkedin.com/secure/developer
# Google: https://code.google.com/apis/console/

# Note: Check respective provider above for information on how to create
# app and get app ID and secret

# Production keys - these need to be unique for this application
facebook_id_production          = "000000000000"
facebook_secret_production      = "000000000000"
twitter_key_production          = "000000000000"
twitter_secret_production       = "000000000000"
linkedin_api_key_production     = "000000000000"
linkedin_secret_key_production  = "000000000000"
google_api_key_production       = "000000000000"
google_secret_key_production    = "000000000000"

# Development keys - these can be reused between applications
facebook_id_development         = "000000000000"
facebook_secret_development     = "000000000000"
twitter_key_development         = "000000000000"
twitter_secret_development      = "000000000000"
linkedin_api_key_development    = "000000000000"
linkedin_secret_key_development = "000000000000"
google_api_key_development      = "000000000000"
google_secret_key_development   = "000000000000"


# Install gems
gem "devise"
gem 'cancancan', '~> 1.8'
gem "role_model"
gem "therubyracer"
gem "twitter-bootstrap-rails"
gem 'twitter-bootswatch-rails', '~> 3.2.0'
gem 'twitter-bootswatch-rails-fontawesome', '~> 4.0'
gem 'twitter-bootswatch-rails-helpers'

gem 'omniauth-facebook' if login_facebook
gem 'omniauth-twitter' if login_twitter
gem 'omniauth-linkedin' if login_linkedin
gem 'omniauth-google-oauth2' if login_google

run "bundle install"

# Define a function to get a list of all the user defined models
def all_models
  Dir.glob("app/models/*.rb").map { |x| 
    x.split("/").last.split(".").first.camelize unless x.end_with?("user.rb") or x.end_with?("ability.rb")
  }.compact
end


# Setup Devise
generate("devise:install")
generate(:devise, "User")

# Install Bootswatch
# Choice of theme: Cerulean, Cosmo, Cyborg, Darkly, Flatly, Journal, Lumen,
# Paper, Readable, Sandstone, Simplex, Slate, Spacelab, Superhero, United or Yeti
# For more information: http://bootswatch.com
theme = "yeti"
generate("bootswatch:install #{theme}")
generate("bootswatch:import #{theme} --force")
generate("bootswatch:layout #{theme} --force")

# Fix issue due to removed property in Bootstrap, not yet fixed in Bootswatch
append_file "app/assets/stylesheets/#{theme}/variables.less" do <<-'FILE'

// Fix for undefined value due to change in Bootstrap
// https://github.com/scottvrosenthal/twitter-bootswatch-rails/issues/30
@zindex-modal-background: 0;
FILE
end

append_file 'config/initializers/assets.rb' do <<-'FILE'

# Add all theme css and js files to the list of assets
@files = Dir.glob("app/assets/javascripts/*")
@files.each do |file|
  if File.directory?(file) 
    Rails.application.config.assets.precompile += [ File.basename(file) + ".css" ]
    Rails.application.config.assets.precompile += [ File.basename(file) + ".js"  ]
  end
end
FILE
end

# Create scaffolding
# TODO: Create an application specific data model instead of Author -> Books -> Reviews
generate(:controller, "home index")
generate(:controller, "dashboard index")
generate(:scaffold, "Author user_id:integer name:string description:text --no-stylesheets")
generate(:scaffold, "Book user_id:integer author_id:integer title:string description:text --no-stylesheets")
generate(:scaffold, "Review user_id:integer book_id:integer comment:text rating:integer --no-stylesheets")

# Add before filter to require login
all_models.each do |c|
  inject_into_file "app/controllers/#{c.tableize}_controller.rb",
      "\n\tbefore_filter :authenticate_user!\n\tload_and_authorize_resource\n\n",
      after: "< ApplicationController\n"
end

# Create an ability file
create_file 'app/models/ability.rb' do <<-'FILE'
class Ability  
  include CanCan::Ability  

  def initialize(user)
    # TODO: Modify permissions based on role  
  	can :manage, :all
  end
end
FILE
end

# Change root page
route "root to: 'home#index'"
route "get 'dashboard' => 'dashboard#index'"

# Migrate database
rake "db:migrate"

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

inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

  def user_params
    params.permit(#{p.join(", ")})
  end

FILE
end

rake "db:migrate"

# Add seed data to create a user
if login_local
append_file 'db/seeds.rb' do <<-'FILE'

puts "Create users"
if User.count == 0
  # TODO: Remove or change test users
  User.create(:name => "Test user 1", :email => "test1@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
  User.create(:name => "Test user 2", :email => "test2@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
end
FILE
end
end

# Create seed data
rake "db:seed"

# Add PostgreSQL in production for Heroku
gsub_file 'Gemfile', %r{gem 'sqlite3'} do <<-'FILE'
# Use Sqlite3 for development and testing
group :development, :test do
  gem 'sqlite3'
end
# Use PostgreSQL (for Heroku)
group :production, :staging do
  gem 'pg'
end
FILE
end

# Define API keys for the various OAuth providers. These keys are edited at the top of this file

if login_facebook
inject_into_file "config/initializers/devise.rb", :before => %r{^end$} do <<-FILE

  require "omniauth-facebook"
  fb_id           = Rails.env.production? ? "#{facebook_id_production}" : "#{facebook_id_development}"
  fb_secret       = Rails.env.production? ? "#{facebook_secret_production}" : "#{facebook_secret_development}"
  config.omniauth :facebook, fb_id, fb_secret

FILE
end
end

if login_twitter
inject_into_file "config/initializers/devise.rb", :before => %r{^end$} do <<-FILE

  require "omniauth-twitter"
  twitter_key     = Rails.env.production? ? "#{twitter_key_production}" : "#{twitter_key_development}"
  twitter_secret  = Rails.env.production? ? "#{twitter_secret_production}" : "#{twitter_secret_development}"
  config.omniauth :twitter, twitter_key, twitter_secret

FILE
end
end

if login_linkedin
inject_into_file "config/initializers/devise.rb", :before => %r{^end$} do <<-FILE

  require "omniauth-linkedin"
  li_api_key      = Rails.env.production? ? "#{linkedin_api_key_production}" : "#{linkedin_api_key_development}"
  li_secret_key   = Rails.env.production? ? "#{linkedin_secret_key_production}" : "#{linkedin_secret_key_development}"
  config.omniauth :linked_in, li_api_key, li_secret_key

FILE
end
end

if login_google
inject_into_file "config/initializers/devise.rb", :before => %r{^end$} do <<-FILE

  require "omniauth-google-oauth2"
  go_api_key      = Rails.env.production? ? "#{google_api_key_production}" : "#{google_api_key_development}"
  go_secret_key   = Rails.env.production? ? "#{google_secret_key_production}" : "#{google_secret_key_development}"
  config.omniauth :google_oauth2, go_api_key, go_secret_key

FILE
end
end


providers = []
providers << ":facebook" if login_facebook
providers << ":twitter" if login_twitter
providers << ":linkedin" if login_linkedin
providers << ":google_oauth2" if login_google

# Omniauth (https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)
if login_oauth
gsub_file "app/models/user.rb", %r{:validatable}, ":validatable, :omniauthable, :omniauth_providers => [#{providers.join(", ")}]"
gsub_file 'config/routes.rb', "devise_for :users", 'devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }'

create_file 'app/controllers/users/omniauth_callbacks_controller.rb' do <<-FILE
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
#{ if login_facebook; <<FACEBOOK
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user, session)

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      if @user.errors.empty?
        set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
      else
        set_flash_message(:error, @user.errors[:base].first) if is_navigational_format?
      end
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
FACEBOOK
end
}
#{ if login_twitter; <<TWITTER
  def twitter
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    puts request.env["omniauth.auth"]

    @user = User.find_for_twitter_oauth(request.env["omniauth.auth"], current_user, session)

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      if @user.errors.empty?
        set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
      else
        set_flash_message(:error, @user.errors[:base].first) if is_navigational_format?
      end
    else
      session["devise.twitter_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
TWITTER
end
}
#{ if login_linkedin; <<LINKEDIN
  def linkedin
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    puts request.env["omniauth.auth"]

    @user = User.find_for_linkedin_oauth(request.env["omniauth.auth"], current_user, session)

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      if @user.errors.empty?
        set_flash_message(:notice, :success, :kind => "Linkedin") if is_navigational_format?
      else
        set_flash_message(:error, @user.errors[:base].first) if is_navigational_format?
      end
    else
      session["devise.linkedin_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
LINKEDIN
end
}
#{ if login_google; <<GOOGLE
  def google_oauth2
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    puts request.env["omniauth.auth"]

    @user = User.find_for_google_oauth2(request.env["omniauth.auth"], current_user, session)

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      if @user.errors.empty?
        set_flash_message(:notice, :success, :kind => "google") if is_navigational_format?
      else
        set_flash_message(:error, @user.errors[:base].first) if is_navigational_format?
      end
    else
      session["devise.google_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
GOOGLE
end
}
end
FILE
end
end

# Update the user model with roles
prepend_file 'app/models/user.rb' do <<-'FILE'
require 'rubygems'
require 'role_model'
  
FILE
end

username = []
username << "name" if login_local
username << "fb_name" if login_facebook
username << "twitter_name" if login_twitter
username << "li_name" if login_twitter
username << "go_name" if login_google
username << '"<no name>"'

avatar = []
avatar << "fb_image" if login_facebook
avatar << "twitter_image" if login_twitter
avatar << "li_image" if login_linkedin
avatar << "go_image" if login_google
avatar << '"http://www.gravatar.com/avatar/\#{Digest::MD5.hexdigest(email)}"'

inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-FILE

  def email_required?
    super && provider.blank?
  end

  def self.is_uid_taken?(user, column, uid)
    u = User.where(column => uid).first
    return true if u and u.id != user.id
    return false
  end

#{ if login_facebook; <<FACEBOOK
  def has_facebook?
    return fb_uid.present?
  end
  
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:fb_uid => auth.uid).first unless user
    #{ "user = User.where(:li_email => auth.info.email).first unless user" if login_linkedin }
    #{ "user = User.where(:go_email => auth.info.email).first unless user" if login_google }
    p auth unless user
    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        email:auth.info.email,
        password:Devise.friendly_token[0,20]
        ) 
      session["user_return_to"] = "/users/edit"
    end

    if User.is_uid_taken?(user, :fb_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end

    user.update_attributes(
        fb_uid:auth.uid,
        fb_email:auth.info.email,
        fb_first_name:auth.info.first_name,
        fb_last_name:auth.info.last_name,
        fb_name:auth.info.name,
        fb_location:auth.info.location,
        fb_image:auth.info.image,
        fb_nickname:auth.info.nickname,
        fb_url:auth.info.urls.Facebook,
        fb_gender:auth.extra.raw_info.gender,
        fb_locale:auth.extra.raw_info.locale,
        fb_username:auth.extra.raw_info.username
        )
    user
  end


FACEBOOK
end
}
#{ if login_twitter; <<TWITTER
  def has_twitter?
    return twitter_uid.present?
  end
  
  def self.find_for_twitter_oauth(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:twitter_uid => auth.uid).first unless user
    p auth unless user
    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        password:Devise.friendly_token[0,20]
        )
      session["user_return_to"] = "/users/edit"
    end

    if User.is_uid_taken?(user, :twitter_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end

    user.update_attributes(
          twitter_uid:auth.uid,
          twitter_name:auth.info.name,
          twitter_nickname:auth.info.nickname,
          twitter_location:auth.info.location,
          twitter_image:auth.info.image,
          twitter_description:auth.info.description,
          twitter_friends:auth.extra.raw_info.friends_count,
          twitter_followers:auth.extra.raw_info.followers_count,
          twitter_statuses:auth.extra.raw_info.statuses_count,
          twitter_listed:auth.extra.raw_info.listed_count
          )
    user
  end

TWITTER
end
}
#{ if login_linkedin; <<LINKEDIN
  def has_linkedin?
    return li_uid.present?
  end
  
  def self.find_for_linkedin_oauth(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:li_uid => auth.uid).first unless user
    #{ "user = User.where(:fb_email => auth.info.email).first unless user" if login_facebook }
    #{ "user = User.where(:go_email => auth.info.email).first unless user" if login_google }
    p auth unless user
    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        email:auth.info.email,
        password:Devise.friendly_token[0,20]
        )
      session["user_return_to"] = "/users/edit"
    end

    if User.is_uid_taken?(user, :li_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end

    user.update_attributes(
        li_uid:auth.uid,
        li_email:auth.info.email,
        li_first_name:auth.info.first_name,
        li_last_name:auth.info.last_name,
        li_name:auth.info.name,
        li_image:auth.info.image,
        li_headline:auth.info.headline,
        li_industry:auth.info.industry
        )
    user
  end

LINKEDIN
end
}
#{ if login_google; <<GOOGLE
  def has_google?
    return go_uid.present?
  end
  
  def self.find_for_google_oauth2(auth, signed_in_resource=nil, session=nil)
    user = signed_in_resource
    user = User.where(:go_uid => auth.uid).first unless user
    #{ "user = User.where(:fb_email => auth.info.email).first unless user" if login_facebook }
    # { "user = User.where(:li_email => auth.info.email).first unless user" if login_linkedin }
    p auth unless user
    unless user
      user = User.create(provider:auth.provider,
        uid:auth.uid,
        email:auth.info.email,
        password:Devise.friendly_token[0,20]
        )
      session["user_return_to"] = "/users/edit"
    end

    if User.is_uid_taken?(user, :go_uid, auth.uid)
      user.errors[:base] << :taken
      return user
    end

    user.update_attributes(
        go_uid:auth.uid,
        go_email:auth.info.email,
        go_first_name:auth.info.first_name,
        go_last_name:auth.info.last_name,
        go_name:auth.info.name,
        go_image:auth.info.image
        )
    user
  end

GOOGLE
end
}
  
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def username
    #{username.join(" || ")}
  end
  
  def avatar
    #{avatar.join(" || ")}
  end
    
  # Role model
  include RoleModel
  
  # The attribute to store roles in.
  roles_attribute :roles_mask

  # Valid roles. (NOTE: only add new roles to the end of the list)
  roles :admin, :manager

FILE
end


# Bootstrapify scaffolding
all_models.each do |c|
  generate("bootswatch:themed #{c.pluralize.camelize} --force")
end

# Replace application layout file
remove_file 'app/views/layouts/application.html.erb'
create_file 'app/views/layouts/application.html.erb' do <<-FILE
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= content_for?(:title) ? yield(:title) : "testapp" %></title>
    <%= csrf_meta_tags %>

    <!-- Le HTML5 shim, for IE6-8 support of HTML elements -->
    <!--[if lt IE 9]>
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js" type="text/javascript"></script>
    <![endif]-->

    <%= stylesheet_link_tag "application", :media => "all" %>
    <%= stylesheet_link_tag "#{theme}", :media => "all" %>
    <%= yield(:page_stylesheet) if content_for?(:page_stylesheet) %>

  </head>
  <body>
    <!-- Fixed navbar -->
    <div class="navbar navbar-inverse navbar-fixed-top">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#">TEMPLATE</a>
        </div>
        <div class="navbar-collapse collapse">
          <ul class="nav navbar-nav">
		    <% if user_signed_in? then -%>
		    <li><%= link_to "Home", "/dashboard"  %></li>
		    <li><%= link_to "Authors", "/authors"  %></li>
		    <li><%= link_to "Books", "/books"  %></li>
		    <li><%= link_to "Reviews", "/reviews"  %></li>
		    <li><%= link_to "Help", "/#help"  %></li>
		    <% else -%>
		    <li><%= link_to "Home", "/"  %></li>
		    <li><%= link_to "Features", "/#features"  %></li>
		    <% end -%>  
	  
          </ul>
		  <ul class="nav navbar-nav navbar-right">
		    <% if user_signed_in? then -%>
			<li class="hidden-phone hidden-tablet"><%= image_tag current_user.avatar, :size => "32x32", :class => "img-circle", :style => "margin-top:7px;margin-left:16px;margin-right:4px" %></li>  
            <li class="dropdown">
              <a href="#" class="dropdown-toggle" data-toggle="dropdown"><%= current_user.username %> <b class="caret"></b></a>
              <ul class="dropdown-menu">
                <li><%= link_to "Profile", '/users/edit' %></li>
                <li class="divider"></li>
                <li><%= link_to "Sign out", '/users/sign_out', :method => :delete %></li>
              </ul>
            </li>
		    <% else -%>
		      <li><%= link_to "Sign in", '/users/sign_in' %></li>
		    <% end -%>
			</ul>
  
        </div><!--/.nav-collapse -->
      </div>
    </div>

  	<%= yield(:hero) %>

    <div class="container">
		<br/><br/>
		<div class="page-header">
			<!-- <%= bootstrap_flash %> -->
			<%= yield %>
		</div>
		<br/>
		<footer class="text-center">
			<p>#{footer}</p>
		</footer>

    </div> <!-- /container -->

    <!-- Javascripts
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <%= javascript_include_tag "#{theme}" %>
    <%= yield(:page_javascript) if content_for?(:page_javascript) %>
  </body>
</html>
FILE
end

# Download Bootstrap social icons
run "wget -O app/assets/stylesheets/bootstrap-social.css https://github.com/lipis/bootstrap-social/raw/gh-pages/bootstrap-social.css"

#inject_into_file "app/assets/stylesheets/application.css", :before => %r{*= require_self} do <<-FILE
inject_into_file "app/assets/stylesheets/application.css", :before => " *= require_self" do <<-FILE
 *= require fontawesome
 *= require bootstrap-social
FILE
end

append_file 'app/assets/stylesheets/application.css' do <<-'FILE'

a.btn-social {
  margin-top: 5px;
}
a.btn-social i {
	padding-top: 8px;
}

label.checkbox input[type="checkbox"] {
	margin-left: 0px;
}

div.form-group {
	margin-left: 0px !important;
	margin-right: 0px !important;
}

div.alert {
	margin-top: 30px;
	margin-bottom: 0px;
}

a.btn:hover {
    color: #eeeeee;
}

body.background {
	background-image:image-url("banner-flowers.jpg");
	background-repeat: no-repeat;
	background-size: cover;
	background-position: center center !important;
}
.jumbotron {
	background-image:image-url("banner-flowers.jpg");
	background-repeat: no-repeat;
	background-size: cover;
	background-position: center center !important;
	margin-top: 45px;
	height: 400px;
}
.jumbotron h2,
.jumbotron p {
	color: white;
	font-size: 200% !important;
	font-weight: bold;
}

footer.dark {
	color: white;
}

FILE
end

# Rename the application.css file to application.css.scss for asset pipelining
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss"

# Redirect user to dashboard after having logged in
inject_into_file "app/controllers/application_controller.rb", :before => %r{^end$} do <<-'FILE'

  before_filter :set_devise_redirect

  # Fix nicer CanCan exceptions
	rescue_from CanCan::AccessDenied do |exception|
	  flash[:alert] = "Access denied!"
	  redirect_to root_url
	end

  # Change layout for devise views
  layout Proc.new { |controller| controller.devise_controller? ? 'devise' : 'application' }

  def set_devise_redirect
    if controller_path == "devise/registrations"
      session["user_return_to"] = "/users/edit"
    elsif controller_path != "users/omniauth_callbacks"
      session["user_return_to"] = "/dashboard"
    end
  end
FILE
end

# Download images
run "wget -O app/assets/images/banner-flowers.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/banner-flowers.jpg"
run "wget -O app/assets/images/bird.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/bird.jpg"
run "wget -O app/assets/images/seaweed.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/seaweed.jpg"
run "wget -O app/assets/images/shells.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/shells.jpg"

run "wget -O app/assets/images/logo.png https://raw.githubusercontent.com/spotwise/railyard/master/assets/railyard-logo.png"
run "wget -O app/assets/images/logo-600px.png https://raw.githubusercontent.com/spotwise/railyard/master/assets/railyard-logo-600px.png"
run "wget -O public/favicon.ico https://raw.githubusercontent.com/spotwise/railyard/master/assets/favicon.ico"
run "wget -O app/assets/images/apple-touch-icon-72x72-precomposed.png https://raw.githubusercontent.com/spotwise/railyard/master/assets/apple-touch-icon-72x72-precomposed.png"
run "wget -O app/assets/images/apple-touch-icon-114x114-precomposed.png https://raw.githubusercontent.com/spotwise/railyard/master/assets/apple-touch-icon-114x114-precomposed.png"
run "wget -O app/assets/images/apple-touch-icon-144x144-precomposed.png https://raw.githubusercontent.com/spotwise/railyard/master/assets/apple-touch-icon-144x144-precomposed.png"
run "wget -O app/assets/images/apple-touch-icon-precomposed.png https://raw.githubusercontent.com/spotwise/railyard/master/assets/apple-touch-icon-precomposed.png"
  
# Add custom Javascript
append_file 'app/assets/javascripts/application.js' do <<-'FILE'

window.setTimeout(function() {
    $(".alert-success").fadeTo(1000, 0).slideUp(500, function(){
        $(this).remove(); 
    });
}, 5000);
FILE
end


# Replace home page
remove_file 'app/views/home/index.html.erb'
create_file 'app/views/home/index.html.erb' do <<-'FILE'

<% content_for :hero do %>
<div class="jumbotron">
	<div class="container">
	  <h2>Welcome!</h2>
	  <p class="lead">Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
  </div>
</div>
<% end %>

<div class="container">
	<div class="row">
		<div class="col-md-4 text-center">
	    <%= image_tag "bird.jpg", :class => 'img-circle', :width => 140, :height => 140, :'data-src' => "holder.js/140x140" %>
			<h2>Feature 1</h2>
			<p>Donec sed odio dui. Etiam porta sem malesuada magna mollis euismod. Nullam id dolor id nibh ultricies vehicula ut id elit. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Praesent commodo cursus magna, vel scelerisque nisl consectetur et.</p>
			<p><a class="btn btn-default" href="#">View details »</a></p>
		</div>
		<div class="col-md-4 text-center">
    <%= image_tag "seaweed.jpg", :class => 'img-circle', :width => 140, :height => 140, :'data-src' => "holder.js/140x140" %>
			<h2>Feature 2</h2>
			<p>Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Cras mattis consectetur purus sit amet fermentum. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.</p>
			<p><a class="btn btn-default" href="#">View details »</a></p>
		</div>
		<div class="col-md-4 text-center">
    <%= image_tag "shells.jpg", :class => 'img-circle', :width => 140, :height => 140, :'data-src' => "holder.js/140x140" %>
			<h2>Feature 3</h2>
			<p>Donec sed odio dui. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.</p>
			<p><a class="btn btn-default" href="#">View details »</a></p>
		</div>
	</div><!-- /.row -->
</div>

<hr/>

<% unless user_signed_in? then -%>
<div class="container">
	<div class="row">
		<div class="col-md-8 text-center">
			<h2>Sign up or log in now!</h2>
		</div>
		<div class="col-md-4 text-center">
			<a style="margin-top:10px;" href="/users/sign_in/" class="btn btn-lg btn-primary">Get Started</a>
		</div>
	</div>
</div>
<% end -%>
FILE
end


create_file 'app/views/devise/sessions/new.html.erb' do <<-FILE
<br/><br/>

#{ if login_facebook; <<FACEBOOK
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
    <a class="btn btn-lg btn-block btn-social btn-facebook" href="/users/auth/facebook"><i class="fa fa-facebook"></i> Log in with Facebook</a>
  </div>
</div>
FACEBOOK
end
}
#{ if login_twitter; <<TWITTER
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
	<a class="btn btn-lg btn-block btn-social btn-twitter" href="/users/auth/twitter"><i class="fa fa-twitter"></i>Log in with Twitter</a>
  </div>
</div>
TWITTER
end
}
#{ if login_linkedin; <<LINKEDIN
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
	<a class="btn btn-lg btn-block btn-social btn-linkedin" href="/users/auth/linkedin"><i class="fa fa-linkedin"></i>Log in with Linkedin</a>
  </div>
</div>
LINKEDIN
end
}
#{ if login_google; <<GOOGLE
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
	<a class="btn btn-lg btn-block btn-social btn-google" href="/users/auth/google_oauth2"><i class="fa fa-google-plus"></i>Log in with Google+</a>
  </div>
</div>
GOOGLE
end
}
#{ if login_local; <<LOCAL
<div class="row">
	<div class="col-lg-8 col-lg-offset-2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
		<%= form_for(resource, :as => resource_name, :url => session_path(resource_name)) do |f| %>
		  <%= f.email_field :email, :autofocus => true, :placeholder => "Email", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %><br/>
		  <%= f.password_field :password, :placeholder => "Password", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %>	
		  <% if devise_mapping.rememberable? -%>
			<label class="checkbox">
		    <%= f.check_box :remember_me %> <%= f.label :remember_me %>
			</label>
		  <% end -%>
		  <%= f.submit "Sign in", :class => "btn btn-primary btn-lg" %>
			<div class="pull-right" style="padding-top:10px"><a href="/users/password/new">Forgot your password?</a></div>
		<% end %>
	</div>
</div>

<div class="row">
	<div class="col-lg-8 col-lg-offset-2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
		<a class="btn btn-default btn-lg btn-block" href="/users/sign_up">Join</a>
	</div>
</div>
LOCAL
end
}
FILE
end

create_file 'app/views/devise/registrations/new.html.erb' do <<-FILE
<br/><br/>
#{ if login_facebook; <<FACEBOOK
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
    <a class="btn btn-lg btn-block btn-social btn-facebook" href="/users/auth/facebook"><i class="fa fa-facebook"></i> Join with Facebook</a>
  </div>
</div>
FACEBOOK
end
}
#{ if login_twitter; <<TWITTER
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
	<a class="btn btn-lg btn-block btn-social btn-twitter" href="/users/auth/twitter"><i class="fa fa-twitter"></i>Join with Twitter</a>
  </div>
</div>
TWITTER
end
}
#{ if login_linkedin; <<LINKEDIN
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
	<a class="btn btn-lg btn-block btn-social btn-linkedin" href="/users/auth/linkedin"><i class="fa fa-linkedin"></i>Join with Linkedin</a>
  </div>
</div>
LINKEDIN
end
}
#{ if login_google; <<GOOGLE
<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
	<a class="btn btn-lg btn-block btn-social btn-google" href="/users/auth/google_oauth2"><i class="fa fa-google-plus"></i>Join with Google+</a>
  </div>
</div>
GOOGLE
end
}
<div class="row">
	<div class="col-lg-8 col-lg-offset-2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
		<%= form_for(resource, :as => resource_name, :url => registration_path(resource_name)) do |f| %>
		  <%= f.email_field :email, :autofocus => true, :placeholder => "Email", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %><br/>
		  <%= f.password_field :password, :placeholder => "Password", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %>	
		  <%= f.password_field :password_confirmation, :placeholder => "Confirm password", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %>
			<br/><br/>
		  <%= f.submit "Join", :class => "btn btn-primary btn-lg" %>
		<% end %>
	</div>
</div>

<div class="row">
	<div class="col-lg-8 col-lg-offset-2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
		<a class="btn btn-default btn-lg btn-block" href="/users/sign_in">Back</a>
	</div>
</div>
FILE
end

create_file 'app/views/devise/passwords/new.html.erb' do <<-'FILE'
<br/><br/><div class="row">
	<div class="col-lg-4 col-lg-offset-4">
		<h2>Reset password</h2>
		<%= form_for(resource, :as => resource_name, :url => password_path(resource_name), :html => { :method => :post }) do |f| %>
  			<%= devise_error_messages! %>
  			<%= f.email_field :email, :autofocus => true, :placeholder => "Email", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %><br/><br/>
			<%= f.submit "Send instructions", :class => "btn btn-primary btn-lg" %>
		<% end %>
	</div>
</div>

<div class="row">
	<div class="col-lg-8 col-lg-offset-2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="col-lg-4 col-lg-offset-4">
		<a class="btn btn-default btn-lg btn-block" href="/users/sign_in">Back</a>
	</div>
</div>
FILE
end

# TODO: Change the class of the HTML tag to "background" to enable a background image on the login page (and add an image)
create_file 'app/views/layouts/devise.html.erb' do <<-FILE
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
  	<link href='http://fonts.googleapis.com/css?family=Ubuntu' rel='stylesheet' type='text/css'>
    <title><%= content_for?(:title) ? yield(:title) : "TEMPLATE" %></title>
    <%= csrf_meta_tags %>

    <!-- Le HTML5 shim, for IE6-8 support of HTML elements -->
    <!--[if lt IE 9]>
      <script src="//cdnjs.cloudflare.com/ajax/libs/html5shiv/3.6.1/html5shiv.js" type="text/javascript"></script>
    <![endif]-->

    <%= stylesheet_link_tag "application", :media => "all" %>
    <%= stylesheet_link_tag "#{theme}", :media => "all" %>

    <!-- For third-generation iPad with high-resolution Retina display: -->
    <!-- Size should be 144 x 144 pixels -->
    <%= favicon_link_tag 'images/apple-touch-icon-144x144-precomposed.png', :rel => 'apple-touch-icon-precomposed', :type => 'image/png', :sizes => '144x144' %>

    <!-- For iPhone with high-resolution Retina display: -->
    <!-- Size should be 114 x 114 pixels -->
    <%= favicon_link_tag 'images/apple-touch-icon-114x114-precomposed.png', :rel => 'apple-touch-icon-precomposed', :type => 'image/png', :sizes => '114x114' %>

    <!-- For first- and second-generation iPad: -->
    <!-- Size should be 72 x 72 pixels -->
    <%= favicon_link_tag 'images/apple-touch-icon-72x72-precomposed.png', :rel => 'apple-touch-icon-precomposed', :type => 'image/png', :sizes => '72x72' %>

    <!-- For non-Retina iPhone, iPod Touch, and Android 2.1+ devices: -->
    <!-- Size should be 57 x 57 pixels -->
    <%= favicon_link_tag 'images/apple-touch-icon-precomposed.png', :rel => 'apple-touch-icon-precomposed', :type => 'image/png' %>

    <!-- For all other devices -->
    <!-- Size should be 32 x 32 pixels -->
    <%= favicon_link_tag 'favicon.ico', :rel => 'shortcut icon' %>
  </head>
  <body>

    <div class="container">
      <div class="row">
          <div class="col-lg-12">
          <br/>
          <br class="hidden-phone hidden-tablet"/>
          <br class="hidden-phone hidden-tablet"/>
          <br class="hidden-phone hidden-tablet"/>
          <br class="hidden-phone hidden-tablet"/>          
          <center><a href="/"><%= image_tag("logo-600px.png", size: '300x80')%></a></center>
            <%= bootstrap_flash %>
            <%= yield %>
          </div>
        </div><!--/row-->


      <footer>
  		<hr/>
      <p><center>#{footer}</center></p>
</footer>


    </div> <!-- /container -->

    <!-- Javascripts
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <%= javascript_include_tag "application" %>
    <%= javascript_include_tag "#{theme}" %>

  </body>
</html>
FILE
end

create_file 'app/views/devise/registrations/edit.html.erb' do <<-FILE
<div class="container">
	<div class="row">
		<div class="span8">
			<h2>Your profile</h2>

	<p>Click on the services below to associate them with your account. This will allow you to use them to log onto the system. If you do not do this a new account may be created for you if you log on with another service.</p>
#{ if login_facebook; <<FACEBOOK
	<div style="width:200px;float:left;margin-right:30px">
    <a class="btn btn-block btn-social btn-facebook <%= "disabled" if current_user.has_facebook? %>" href="/users/auth/facebook"><i class="fa fa-facebook" style="line-height:26px;"></i> Facebook</a>
	</div>
FACEBOOK
end
}
#{ if login_twitter; <<TWITTER
	<div style="width:200px;float:left;margin-right:30px">
	<a class="btn btn-block btn-social btn-twitter <%= "disabled" if current_user.has_twitter? %>" href="/users/auth/twitter"><i class="fa fa-twitter" style="line-height:26px;"></i>Twitter</a>
	</div>
TWITTER
end
}
#{ if login_linkedin; <<LINKEDIN
	<div style="width:200px;float:left;margin-right:30px">
	<a class="btn btn-block btn-social btn-linkedin <%= "disabled" if current_user.has_linkedin? %>" href="/users/auth/linkedin"><i class="fa fa-linkedin" style="line-height:26px;"></i>Linkedin</a>
	</div>
LINKEDIN
end
}
#{ if login_google; <<GOOGLE
	<div style="width:200px;float:left;margin-right:30px">
	<a class="btn btn-block btn-social btn-google <%= "disabled" if current_user.has_google? %>" href="/users/auth/google_oauth2"><i class="fa fa-google-plus" style="line-height:26px;"></i>Google+</a>
	</div>
GOOGLE
end
}
 </div>
 </div>
 <br/>

<div class="row">
	<div class="span8 offset2">

<% if current_user.provider.nil? -%>
<%= form_for(resource, :as => resource_name, :url => registration_path(resource_name), :html => { :method => :put, :class => 'form-horizontal' }) do |f| %>
  <%= devise_error_messages! %>

  <div class="control-group">
  <%= f.label :email, :class => 'control-label' %>
  <div class="controls">
  	<%= f.email_field :email, :autofocus => true, :class => 'text_field'  %></div>
  </div>
  <% if devise_mapping.confirmable? && resource.pending_reconfirmation? %>
    <div>Currently waiting confirmation for: <%= resource.unconfirmed_email %></div>
  <% end %>

  <div class="control-group">
  	<%= f.label :password, :class => 'control-label' %>
	<div class="controls">
  		<%= f.password_field :password, :autocomplete => "off", :class => 'password_field' %>
		<span class="help-block">Leave blank if you don't want to change it</span>
	</div>
  </div>

  <div class="control-group">
  	<%= f.label :password_confirmation, :class => 'control-label' %>
	<div class="controls">
  		<%= f.password_field :password_confirmation, :autocomplete => "off", :class => 'password_field' %>
		<span class="help-block">Please retype your new password</span>
	</div>
  </div>

  <div class="control-group">
  	<%= f.label :current_password, :class => 'control-label' %>
	<div class="controls">
  		<%= f.password_field :current_password, :autocomplete => "off", :class => 'password_field' %>
		<span class="help-block">We need your current password to confirm your changes</span>
	</div>
  </div>

  <div><%= f.submit "Update", :class => 'btn btn-primary' %></div>
<% end %>

<% end -%>

<h3>Cancel my account</h3>

<p>If you do not want to use this service you can cancel your account. <strong>Note that doing so will delete all your data.</strong></p>
<p>
<%= button_to "Cancel my account", registration_path(resource_name), :data => { :confirm => "Are you sure?" }, 
		:method => :delete, :class => 'btn btn-danger' %></p>

</div></div></div>
FILE
end

inject_into_file "config/locales/devise.en.yml", :before => %r{^    passwords:$} do <<-FILE
      user:
        taken: "That identity is already claimed for another account."
FILE
end

inject_into_file "config/application.rb", :before => %r{^  end$} do <<-FILE

    # Change layout for edit page
    config.to_prepare do
        Devise::RegistrationsController.layout proc{ |controller| action_name == 'edit' ? "application" : "devise" }
    end
FILE
end

remove_file 'README.rdoc'
create_file 'README.rdoc' do <<-'FILE'

== README
    
=== Post creation setup

This web site was created using a template. Some typical changes will be 
necessary, like changing from numerical input to dropdown boxes:

  FROM: <%= f.text_field :user_id, :class => 'text_field' %>
  TO  : <%= f.select(:user_id, User.all.map {|u| [ "%s [%s]" % 
    [u.username, u.provider], u.id]}, :prompt => t('users.select_user') ) %>
  
  FROM: <%= f.text_field :author_id, :class => 'text_field' %>
  TO  : <%= f.select(:author_id, Author.all.map {|a| [a.name, a.id ]}, 
    :prompt => t('author.select_user') ) %>

=== Original text
  
Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions


Please feel free to use a different markup language if you do not plan to run
<tt>rake doc:app</tt>.

FILE
end

# Change from 'btn' to 'btn default' in all views
Dir.glob("app/views/*/*.html.erb").each do |f|
  gsub_file f, %r{'btn'}, "'btn btn-default'"
end
