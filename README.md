# Railyard

This repository contains tools to quickly set up new Ruby on Rails projects. Most importantly it it includes templates to setup a new Rails project with support for:

* Responsive design based on Twitter Bootstrap
* Oauth2 login support (Facebook, Twitter and Linkedin)

## Dependencies

This project depends on the following:

* Rails 4.1 (or later)
* Command line support for wget

The template is known to work on OS X 10.9 and should work on any Linux system. Most likely it does not work on Windows due to the use of typical OS X / Linux commands. 

## Usage

The quickest way to use the template is to access the template via HTTP:

    rails new [sitename] -m https://github.com/spotwise/railyard/raw/master/fourteen-eight.rb

Replace [sitename] with the name of the project to be created. The Rails system will create a new Ruby on Rails site in the local directory and run the template directly from the web.

Once the site has been created, then change to the site directory and run

    rails s

Then open your browser and access http://localhost:3000 and you should be met with the site homepage.

The above will create a Rails project with a few example models. Although this will work as an example it may not be what you want. To be able to customise the project the template file should be downloaded and then modified according to your needs. The template file is sprinkled with the text TODO where modifications should be added.

Once the template has beed modified to your satisfaction then run the above command but change the URI to the path to the modified file.

The template uses a number of default settings that need to be modified:

* API keys for Facebook, Twitter and Linkedin
* Colours for navigation bar and links
* Images on home page
* Footer message
* Site logo
