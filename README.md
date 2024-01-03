# Railyard

This repository contains tools to quickly set up new Ruby on Rails projects. Most importantly it includes templates to setup a new Rails project with support for:

* Responsive design based on TailwindCSS
* Authentication support based on Devise
* Oauth2 login support (Facebook, Linkedin and Google)

The choice of authentication services is arbitrary to allow for any combination of local, Facebook, Linkedin or Google accounts.

## Dependencies

This project depends on the following:

* Rails
* Command line support for wget

The template is known to work on OS X 14.2 and should work on any Linux system. Most likely it does not work on Windows due to the use of typical OS X / Linux commands.

## Usage

The quickest way to use the template is to access the template via HTTP:

    rails new SITENAME \
        --css=tailwind \
        -m https://github.com/spotwise/railyard/raw/master/railyard.rb

Replace SITENAME with the name of the project to be created. The Rails system will create a new Ruby on Rails site in the local directory and run the template directly from the web.

Once the site has been created, then change to the site directory and run

    bin/dev

Then open your browser and access http://localhost:3000 and you should be met with the site homepage. The template by default creates two test users, test1@example.com and test2@example.com, both with the password 'test'. Also by default, the template enables the use of Facebook, Linkedin and Google although none of these will work until you have added your own API keys.

The above command will create a Rails project with a few example models. Although this will work as an example it is probably not be what you want. To be able to customise the project the template files should be downloaded and then modified according to your needs. The main template file (railyard.rb) is sprinkled with the text TODO where modifications should be added.

The template uses a number of default settings that need to be modified. At the minimum the data model should be modified before running the template to create the database schema necessary for the intended application and not leave remnants of the example models. 

Other settings that may be modified later include:

* API keys for Facebook, Linkedin and Google
* Colours for navigation bar and links
* Footer message

The repository includes a sample file for development keys. This should be copied to your home directory with the name .development_keys.rb (i.e. hidden) and updated with the sample keys. They are then used during application setup which simplifies the setup when reusing this template for different applications.

Once the template has been modified to your satisfaction then run the above command but change the URI to the path to the modified file.

For a more extensive description of how to setup a Rails site using this template, please refer to http://www.spotwise.com/2015/01/04/create-a-web-site-in-53-seconds/.

## History

Note: Updates to both the Ruby language, the Rails framework and the used gems may cause issues with previous versions of the template. Always try to use the latest template version first.

* 2014-08-08 Initial version
* 2014-10-03 Support for Bootstrap 3
* 2014-12-20 Added support for Google+
* 2015-01-23 Improved handling of multiple authentication providers
* 2015-02-27 New theme with support for full width hero image
* 2015-05-28 Various layout fixes
* 2016-04-03 Updated to work with Rails 4.2.6
* 2016-08-21 Added support for Office 365 authentication
* 2018-03-02 Rewritten to use Rails 5.x and Bootstrap 4.x
* 2020-07-24 Completely rewritten to use Rails 6.x
* 2021-01-10 Completely rewritten to use Rails 6.1 and Bootstrap 5
* 2021-03-13 Fixed support for Microsoft
* 2022-01-04 Completely rewritten to use Rails 7
* 2024-01-02 Completely rewritten to use Rails 7.1 and TailwindCSS

