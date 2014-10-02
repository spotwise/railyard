# Railyard

This repository contains tools to quickly set up new Ruby on Rails projects. Most importantly it it includes templates to setup a new Rails project with support for:

* Responsive design based on Twitter Bootstrap
* Oauth2 login support (Facebook, Twitter and Linkedin)

The choice of authentication services is arbitrary to allow for any combination of local, Facebook, Twitter or Linkedin accounts.

## Dependencies

This project depends on the following:

* Rails 4.1 (or later)
* Command line support for wget

The template is known to work on OS X 10.9 and should work on any Linux system. Most likely it does not work on Windows due to the use of typical OS X / Linux commands. 

## Usage

The quickest way to use the template is to access the template via HTTP:

    rails new [sitename] -m https://github.com/spotwise/railyard/raw/master/fourteen-ten.rb

Replace [sitename] with the name of the project to be created. The Rails system will create a new Ruby on Rails site in the local directory and run the template directly from the web.

Once the site has been created, then change to the site directory and run

    rails s

Then open your browser and access http://localhost:3000 and you should be met with the site homepage. The template by default creates two test users, test1@example.com and test2@example.com, both with the password 'test'. Also by default, the template enables the use of Facebook, Twitter and Linkedin although none of these will work until you have added your own API keys.

The above will create a Rails project with a few example models. Although this will work as an example it is probably not be what you want. To be able to customise the project the template file should be downloaded and then modified according to your needs. The template file is sprinkled with the text TODO where modifications should be added.

The template uses a number of default settings that need to be modified. At the minimum the data model should be modified before running the template to create the database schema necessary for the intended application and not leave remnants of the example models. 

Other settings that may be modified later include:

* API keys for Facebook, Twitter and Linkedin
* Name of Bootswatch theme
* Colours for navigation bar and links
* Images on home page
* Footer message
* Site logo

Once the template has beed modified to your satisfaction then run the above command but change the URI to the path to the modified file.

## History

* 2014-08-08 Initial version
* 2014-10-03 Support for Bootstrap 3

