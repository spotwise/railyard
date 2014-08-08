#
# This template sets up a rails project with
# Bootstrap, a nice theme, some scaffolding
# and authentication with support for 
# Facebook, Twitter and Linkedin login
#
# Copyright © 2014 Spotwise 
#

# Install gems
gem "devise"
gem 'cancancan', '~> 1.8'
gem "role_model"
gem "therubyracer"
gem "less-rails"
gem "twitter-bootstrap-rails"

gem 'omniauth-facebook'
gem 'omniauth-twitter'
gem 'omniauth-linkedin'

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

# Run Bootstrap generator
generate("bootstrap:install less")
generate("bootstrap:layout application fluid --force")

# Download Bootswatch template
run "mkdir app/assets/stylesheets/united"
run "wget -O app/assets/stylesheets/united/variables.less http://bootswatch.com/2/united/variables.less"
run "wget -O app/assets/stylesheets/united/bootswatch.less http://bootswatch.com/2/united/bootswatch.less"

# Create scaffolding
# TODO: Create an application specific data model instead of Author -> Books -> Reviews
generate(:controller, "home index")
generate(:controller, "dashboard index")
generate(:scaffold, "Author user_id:integer name:string description:text")
generate(:scaffold, "Book user_id:integer author_id:integer title:string description:text")
generate(:scaffold, "Review user_id:integer book_id:integer comment:text rating:integer")


# Add before filter to require login
all_models.each do |c|
  inject_into_file "app/controllers/#{c.downcase.pluralize}_controller.rb", 
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

# Add columns to the user table for Facebook and Twitter
generate(:migration, "AddFacebookToUsers fb_email:string fb_first_name:string fb_last_name:string fb_name:string fb_location:string fb_image:string fb_nickname:string fb_url:string fb_gender:string fb_locale:string fb_username:string --force")
generate(:migration, "AddTwitterToUsers twitter_name:string twitter_nickname:string twitter_location:string twitter_image:string twitter_description:string twitter_friends:integer twitter_followers:integer twitter_statuses:integer twitter_listed:integer --force")
generate(:migration, "AddLinkedinToUsers li_email:string li_first_name:string li_last_name:string li_name:string li_image:text li_headline:string li_industry:string --force")
rake "db:migrate"

inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-'FILE'

  def user_params
    params.permit(:email, :password, :password_confirmation, :remember_me, :roles_mask, :roles, :provider, :uid, :fb_first_name, :fb_last_name, :fb_name, :fb_location, :fb_image, :fb_nickname, :fb_url, :fb_gender, :fb_locale, :fb_username, :twitter_name, :twitter_nickname, :twitter_location, :twitter_image, :twitter_description, :twitter_friends, :twitter_followers, :twitter_statuses, :twitter_listed, :li_email, :li_first_name, :li_last_name, :li_name, :li_image, :li_headline, :li_industry)
  end

FILE
end

# Add seed data to create a user
append_file 'db/seeds.rb' do <<-'FILE'

puts "Create users"
if User.count == 0
  # TODO: Remove or change test users
  User.create(:email => "test1@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
  User.create(:email => "test2@example.com", :password => "test", :password_confirmation => "test").save(:validate => false)
end
FILE
end

# Create seed data
rake "db:seed"

#TBD
# Bootstrapify scaffolding
all_models.each do |c|
  generate("bootstrap:themed #{c.pluralize.camelize} --force")
end

# Update menu bar
# TODO: Update menu based on data model
gsub_file 'app/views/layouts/application.html.erb', 
    %r{<div class="container-fluid nav-collapse">.*</div><!--/.nav-collapse -->}mi do <<-'FILE'
<div class="container-fluid collapse nav-collapse">
<ul class="nav">
  <% if user_signed_in? then -%>
  <li><%= link_to "Home", "/dashboard"  %></li>
  <li><%= link_to "Authors", "/authors"  %></li>
  <li><%= link_to "Books", "/books"  %></li>
  <li><%= link_to "Reviews", "/reviews"  %></li>
  <li><%= link_to "Help", "/#help"  %></li>
  <% else -%>
  <li><%= link_to "Home", "/"  %></li>
  <li><%= link_to "Features", "/#features"  %></li>
  <li><%= link_to "Pricing", "/#pricing"  %></li>
  <% end -%>
  </ul>
  <ul class="nav pull-right">
  <% if user_signed_in? then -%>
    <li class="hidden-phone hidden-tablet"><%= image_tag current_user.avatar, :size => "32x32", :class => "img-circle", :style => "margin-top:4px;margin-left:16px;margin-right:4px" %></li>
	  <li class="dropdown"><a href="#" class="dropdown-toggle" data-toggle="dropdown"><%= current_user.username %>
		  <b class="caret"></b></a>
		  <ul class="dropdown-menu">
	  		<li><%= link_to "Sign out", '/users/sign_out', :method => :delete %></li>
		  </ul>
	  </li>
  <% else -%>
    <li><%= link_to "Sign in", '/users/sign_in' %></li>
  <% end -%>				
</ul>
</div><!--/.nav-collapse -->
FILE
end

gsub_file 'app/views/layouts/application.html.erb', 
    %r{<div class="row-fluid">.*</div><!--/row-->}mi do <<-'FILE'
  <div class="row-fluid">
    <div class="span12">
        <%= bootstrap_flash %>
        <%= yield %>
        </div>
  </div><!--/row-->
FILE
end

# Define API keys for the various OAuth providers
# TODO: Change API keys to personal ones for the site being built
#
inject_into_file "config/initializers/devise.rb", :before => %r{^end$} do <<-'FILE'

  require "omniauth-facebook"
  require "omniauth-twitter"
  require "omniauth-linkedin"
  
  # TODO: Change to proper keys below based on information found on the Facebook/Twitter/Linkedin developer sites
  
  # Facebook: https://developers.facebook.com 
  # Twitter: https://dev.twitter.com
  # Linkedin: https://www.linkedin.com/secure/developer
  
  fb_id           = Rails.env.production? ? "FB_ID_PRODUCTION" : "FB_ID_DEVELOPMENT"
  fb_secret       = Rails.env.production? ? "FB_SECRET_PRODUCTION" : "FB_SECRET_DEVELOPMENT"
  twitter_key     = Rails.env.production? ? "TWITTER_KEY_PRODUCTION" : "TWITTER_KEY_DEVELOPMENT"
  twitter_secret  = Rails.env.production? ? "TWITTER_SECRET_PRODUCTION" : "TWITTER_SECRET_DEVELOPMENT"
  li_api_key      = Rails.env.production? ? "LINKEDIN_API_KEY_PRODUCTION" : "LINKEDIN_API_KEY_DEVELOPMENT"
  li_secret_key   = Rails.env.production? ? "LINKEDIN_SECRET_KEY_PRODUCTION" : "LINKEDIN_SECRET_KEY_DEVELOPMENT"
  
  config.omniauth :facebook, fb_id, fb_secret
  config.omniauth :twitter, twitter_key, twitter_secret
  config.omniauth :linked_in, li_api_key, li_secret_key
  
FILE
end


# ============= NO CHANGES BELOW THIS LINE ===================

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

# Change application.css
gsub_file 'app/assets/stylesheets/application.css', 'require_tree .', 'require bootstrap_and_overrides'

append_file 'app/assets/stylesheets/bootstrap_and_overrides.css.less' do <<-'FILE'

@import "united/bootswatch.less";
@import "united/variables.less";

@facebookBlueLight: #627aad;
@facebookBlue: #3b5998;
.btn-facebook { .buttonBackground(@facebookBlueLight, @facebookBlue); }

@twitterBlueLight: #63b3ff;
@twitterBlue: #4099ff;
.btn-twitter { .buttonBackground(@twitterBlueLight, @twitterBlue); }  

@linkedinBlueLight: #627aad;
@linkedinBlue: #4875B4;
.btn-linkedin { .buttonBackground(@linkedinBlueLight, @linkedinBlue); }  

// TODO: Change the colours of the navbar and links
@linkColor: #AEE239;
@navbarBackground: #E73525;
@navbarBackgroundHighlight: lighten( @navbarBackground, 5% );

@dropdownLinkColor: @linkColor;
@dropdownLinkBackgroundActive: @linkColor;
@dropdownLinkBackgroundHover: @dropdownLinkBackgroundActive;

FILE
end

# Remove the round cornerns on the navbar
append_file 'app/assets/stylesheets/application.css' do <<-'FILE'

html.background { 
  background: url(/assets/background.jpg) no-repeat center center fixed; 
  -webkit-background-size: cover;
  -moz-background-size: cover;
  -o-background-size: cover;
  background-size: cover;
}
body {
  font-family: 'Ubuntu', sans-serif;
  padding-left: 0 !important;
  padding-right: 0 !important;
}
.container-fluid {
  padding-left: 20px !important;
  padding-right: 20px !important;
}
div.navbar-inner {
  border-radius: 0px;
  -webkit-border-radius: 0px;	
}
div.featurette {
  margin-bottom: 50px;
}
div.marketing {
  text-align: center;
}
div.boxed .span4 {
  background: #dddddd;
  padding-bottom: 10px;
  border-radius: 5px;
}
.btn-social {
  margin-top: 5px;
}
.devise .alert {
  margin-top: 30px;
  margin-bottom: 0;
}
div.row {
  margin-left:0;
}
FILE
end


# Omniauth (https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)
gsub_file 'app/models/user.rb', %r{:validatable}, ':validatable, :omniauthable, :omniauth_providers => [:facebook, :twitter, :linkedin]'
gsub_file 'config/routes.rb', "devise_for :users", 'devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }'


create_file 'app/controllers/users/omniauth_callbacks_controller.rb' do <<-'FILE'
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def twitter
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    puts request.env["omniauth.auth"]

    @user = User.find_for_twitter_oauth(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Twitter") if is_navigational_format?
    else
      session["devise.twitter_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
  
  def linkedin
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    puts request.env["omniauth.auth"]

    @user = User.find_for_linkedin_oauth(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Linkedin") if is_navigational_format?
    else
      session["devise.linkedin_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end
  
end
FILE
end

# Update the user model with roles
prepend_file 'app/models/user.rb' do <<-'FILE'
require 'rubygems'
require 'role_model'
  
FILE
end

inject_into_file "app/models/user.rb", :before => %r{^end$} do <<-'FILE'

  def email_required?
    super && provider.blank?
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      p auth
      user = User.create(provider:auth.provider,
                           uid:auth.uid,
                           email:auth.info.email,
                           password:Devise.friendly_token[0,20],
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
    end
    user
  end

  def self.find_for_twitter_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      p auth
      user = User.create(provider:auth.provider,
                           uid:auth.uid,
                           password:Devise.friendly_token[0,20],
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
    end
    user
  end  
  
  def self.find_for_linkedin_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      p auth
      user = User.create(provider:auth.provider,
                           uid:auth.uid,
                           email:auth.info.email,
                           password:Devise.friendly_token[0,20],
                           li_first_name:auth.info.first_name,
                           li_last_name:auth.info.last_name,
                           li_name:auth.info.name,
                           li_image:auth.info.image,
                           li_headline:auth.info.headline,
                           li_industry:auth.info.industry
                           )                           
    end
    user
  end  
  
  
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def username
    name || fb_name || twitter_name || li_name ||  "<no name>"
  end
  
  def avatar
    fb_image || twitter_image || li_image || "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}"
  end
    
  # Role model
  include RoleModel
  
  # The attribute to store roles in.
  roles_attribute :roles_mask

  # Valid roles. (NOTE: only add new roles to the end of the list)
  roles :admin, :manager

FILE
end

# Redirect user to dashboard after having logged in
inject_into_file "app/controllers/application_controller.rb", :before => %r{^end$} do <<-'FILE'

  # Fix nicer CanCan exceptions
	rescue_from CanCan::AccessDenied do |exception|
	  flash[:alert] = "Access denied!"
	  redirect_to root_url
	end

  # Change layout for devise views
  layout Proc.new { |controller| controller.devise_controller? ? 'devise' : 'application' }

  def after_sign_in_path_for(resource)
    "/dashboard"
  end
FILE
end

# TODO:  Change copyright in footer
gsub_file 'app/views/layouts/application.html.erb', 
    %r{<footer>.*</footer>}mi do <<-'FILE'
<footer>
  		<hr/>
      <p><center>&copy; <a href="http://www.example.com">Example Inc</a> 2014.</center></p>
</footer>

FILE
end

# Add link to font
inject_into_file "app/views/layouts/application.html.erb", :before => "<title>" do <<-'FILE'
<link href='http://fonts.googleapis.com/css?family=Ubuntu' rel='stylesheet' type='text/css'>	
FILE
end

# Download images
run "wget -O app/assets/images/banner-flowers.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/banner-flowers.jpg"
run "wget -O app/assets/images/bird.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/bird.jpg"
run "wget -O app/assets/images/seaweed.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/seaweed.jpg"
run "wget -O app/assets/images/shells.jpg https://raw.githubusercontent.com/spotwise/railyard/master/assets/shells.jpg"

run "wget -O app/assets/images/logo.png https://raw.githubusercontent.com/spotwise/railyard/master/assets/railyard-logo.png"
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
<div class="container featurette alert">
  <button type="button" class="close" data-dismiss="alert">&times;</button>
  <strong>Note:</strong> This site is in evaluation mode. You may try out this service but please be aware that the content may be reset without prior notice.
</div>
<div class="container featurette">
	<h2>Welcome!</h2>
	<p class="lead">Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
	<%= image_tag "banner-flowers.jpg" %>
</div>

<div id="features" class="container featurette marketing">
	<div class="row">
		<div class="span4">
	    <%= image_tag "bird.jpg", :class => 'img-circle', :width => 140, :height => 140, :'data-src' => "holder.js/140x140" %>
			<h2>Heading</h2>
			<p>Donec sed odio dui. Etiam porta sem malesuada magna mollis euismod. Nullam id dolor id nibh ultricies vehicula ut id elit. Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Praesent commodo cursus magna, vel scelerisque nisl consectetur et.</p>
			<p><a class="btn" href="#">View details »</a></p>
		</div><!-- /.span4 -->
		<div class="span4">
    <%= image_tag "seaweed.jpg", :class => 'img-circle', :width => 140, :height => 140, :'data-src' => "holder.js/140x140" %>
			<h2>Heading</h2>
			<p>Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Cras mattis consectetur purus sit amet fermentum. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.</p>
			<p><a class="btn" href="#">View details »</a></p>
		</div><!-- /.span4 -->
		<div class="span4">
    <%= image_tag "shells.jpg", :class => 'img-circle', :width => 140, :height => 140, :'data-src' => "holder.js/140x140" %>
			<h2>Heading</h2>
			<p>Donec sed odio dui. Cras justo odio, dapibus ac facilisis in, egestas eget quam. Vestibulum id ligula porta felis euismod semper. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus.</p>
			<p><a class="btn" href="#">View details »</a></p>
		</div><!-- /.span4 -->
	</div><!-- /.row -->
</div>

<div id="pricing" class="container featurette marketing boxed">
	<div class="row">
		<div class="span8" style="text-align:left">
			<h2>Plans &amp; pricing</h2>
		</div>
	</div>
	<div class="row">
		<div class="span4">
			<h2>Premium</h2>
			<strong>€20 per month</strong>
		</div>
		<div class="span4">
			<h2>Pro</h2>
			<strong>€10 per month</strong>
		</div>
		<div class="span4">
			<h2>Basic</h2>
			<strong>Free</strong>
		</div>
	</div>
</div>

<% unless user_signed_in? then -%>
<div class="container featurette marketing lastcall">
	<div class="row">
		<div class="span8">
			<h2>Sign up or log in now!</h2>
		</div>
		<div class="span4">
			<a style="margin-top:10px;" href="/users/sign_in/" class="btn btn-large btn-primary">Get Started</a>
		</div>
	</div>
</div>
<% end -%>
FILE
end

# TODO: Select login/registration options
create_file 'app/views/devise/sessions/new.html.erb' do <<-'FILE'
<br/><br/>

<div class="row">
	<div class="span4 offset4">
    <a class="btn btn-large btn-block btn-social btn-facebook" href="/users/auth/facebook"><i class="icon-facebook"></i>&nbsp;&nbsp;|&nbsp;&nbsp;Log in with Facebook</a>
  </div>
</div>
<div class="row">
	<div class="span4 offset4">
	<a class="btn btn-large btn-block btn-social btn-twitter" href="/users/auth/twitter"><i class="icon-twitter"></i>&nbsp;&nbsp;|&nbsp;&nbsp;Log in with Twitter</a>
  </div>
</div>
<div class="row">
	<div class="span4 offset4">
	<a class="btn btn-large btn-block btn-social btn-linkedin" href="/users/auth/linkedin"><i class="icon-linkedin"></i>&nbsp;&nbsp;|&nbsp;&nbsp;Log in with Linkedin</a>
  </div>
</div>

<div class="row">
	<div class="span8 offset2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="span4 offset4">
		<%= form_for(resource, :as => resource_name, :url => session_path(resource_name)) do |f| %>
		  <%= f.email_field :email, :autofocus => true, :placeholder => "Email", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %><br/>
		  <%= f.password_field :password, :placeholder => "Password", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %>	
		  <% if devise_mapping.rememberable? -%>
			<label class="checkbox">
		    <%= f.check_box :remember_me %> <%= f.label :remember_me %>
			</label>
		  <% end -%>
		  <%= f.submit "Sign in", :class => "btn btn-large" %>
			<div class="pull-right" style="padding-top:10px"><a href="/users/password/new">Forgot your password?</a></div>
		<% end %>
	</div>
</div>

<div class="row">
	<div class="span8 offset2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="span4 offset4">
		<a class="btn btn-large btn-block" href="/users/sign_up">Join</a>
	</div>
</div>
FILE
end

# TODO: Select login/registration options
create_file 'app/views/devise/registrations/new.html.erb' do <<-'FILE'
<br/><br/>
<div class="row">
	<div class="span4 offset4">
    <a class="btn btn-large btn-block btn-social btn-facebook" href="/users/auth/facebook"><i class="icon-facebook"></i>&nbsp;&nbsp;|&nbsp;&nbsp;Join with Facebook</a>
  </div>
</div>
<div class="row">
	<div class="span4 offset4">
	<a class="btn btn-large btn-block btn-social btn-twitter" href="/users/auth/twitter"><i class="icon-twitter"></i>&nbsp;&nbsp;|&nbsp;&nbsp;Join with Twitter</a>
  </div>
</div>
<div class="row">
	<div class="span4 offset4">
	<a class="btn btn-large btn-block btn-social btn-linkedin" href="/users/auth/linkedin"><i class="icon-linkedin"></i>&nbsp;&nbsp;|&nbsp;&nbsp;Join with Linkedin</a>
  </div>
</div>

<div class="row">
	<div class="span8 offset2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="span4 offset4">
		<%= form_for(resource, :as => resource_name, :url => registration_path(resource_name)) do |f| %>
		  <%= f.email_field :email, :autofocus => true, :placeholder => "Email", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %><br/>
		  <%= f.password_field :password, :placeholder => "Password", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %>	
		  <%= f.password_field :password_confirmation, :placeholder => "Confirm password", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %>
			<br/>		
		  <%= f.submit "Join", :class => "btn btn-large" %>
		<% end %>
	</div>
</div>

<div class="row">
	<div class="span8 offset2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="span4 offset4">
		<a class="btn btn-large btn-block" href="/users/sign_in">Back</a>
	</div>
</div>
FILE
end

create_file 'app/views/devise/passwords/new.html.erb' do <<-'FILE'
<br/><br/><div class="row">
	<div class="span4 offset4">	
		<h2>Reset password</h2>
		<%= form_for(resource, :as => resource_name, :url => password_path(resource_name), :html => { :method => :post }) do |f| %>
  			<%= devise_error_messages! %>
  			<%= f.email_field :email, :autofocus => true, :placeholder => "Email", :style => "width:100%;box-sizing:border-box;height:44px;padding: 9px 9px;font-size: 17.5px;" %><br/>
			<%= f.submit "Send instructions", :class => "btn btn-large" %>
		<% end %>
	</div>
</div>

<div class="row">
	<div class="span8 offset2">
		<hr/>
	</div>
</div>

<div class="row">
	<div class="span4 offset4">
		<a class="btn btn-large btn-block" href="/users/sign_in">Back</a>
	</div>
</div>
FILE
end

# TODO: Change the class of the HTML tag to "background" to enable a background image on the login page (and add an image
create_file 'app/views/layouts/devise.html.erb' do <<-'FILE'
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

    <div class="container-fluid">
      <div class="row-fluid">
          <div class="span12">
          <br/>
          <br class="hidden-phone hidden-tablet"/>
          <br class="hidden-phone hidden-tablet"/>
          <br class="hidden-phone hidden-tablet"/>
          <br class="hidden-phone hidden-tablet"/>          
			<center><a href="/"><%= image_tag("logo.png")%></a></center>
            <%= bootstrap_flash %>
            <%= yield %>
          </div>
        </div><!--/row-->


      <footer>
  		<hr/>
      <p><center>Crafted with <span>♥</span> in Sweden. &copy; <a href="http://www.spotwise.com">Spotwise</a> 2014.</center></p>
</footer>


    </div> <!-- /container -->

    <!-- Javascripts
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <%= javascript_include_tag "application" %>

  </body>
</html>
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

