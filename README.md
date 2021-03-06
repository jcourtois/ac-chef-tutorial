# Infrastructure Automation with Chef

## Before we start
We want to make this a great learning experience. We would encourage you to type all the code and commands yourself and follow the steps. Also please make sure you understand why and what you are doing. Don't hesitate to ask us for help.
Also you will see that setting up machines is a lot of waiting around - take this as a time to learn more about the tools you're using by reading `--help` and `man` pages.

## Prerequisites

We'll be using the following tools.
- [Vagrant](https://www.vagrantup.com/)
- [Virtualbox](https://www.virtualbox.org/)
- [ChefDK](https://downloads.chef.io/chef-dk/mac/#/)

It's useful to have a decent text editor handy, too – like [Sublime](http://www.sublimetext.com/3) or [Atom](https://atom.io/).

## Recommended installation using homebrew:
```sh
brew install Caskroom/cask/virtualbox
brew install Caskroom/cask/vagrant

vagrant box add bento/ubuntu-15.04
vagrant box add bento/centos-7.1
```

Verify required installations are complete:
```sh
virtualbox
vagrant --version
chef --version
kitchen --version
berks --version
```

## Cloning the repo

First clone the workshop repository from github in your preferred location.

```sh
git clone https://github.com/jcourtois/ac-chef-tutorial.git
```

### Whats inside the repo?
This repo contains two directories. The 'app' directory includes a ruby app called Minions. Our goal is to use Chef to provision a virtual machine machine so that it can run the Minions app. Take a minute to inspect the app directory.

### The cookbook directory
The cookbook directory will hold our chef code. We have created the basic directory structure for you. 

Take a moment to look at `metadata.rb`. 

The first two lines describe the name and version of the cookbook. The rest of the specifies our cookbook dependencies.
```ruby
name    'minions'
version '0.0.1'
```


##Setting up the Local Environment

### Berkshelf
Berkshelf is a dependency manager for Chef. Berkshelf uses a file called Berksfile to determine what dependencies to fetch and where to fetch these dependencies from. You will notice that an empty Berksfile has been created for you. 

Add the following lines to your Berksfile.
```ruby
source 'https://supermarket.getchef.com'
metadata
```

####  Berksfile
The first line tells Berkshelf to fetch cookbooks from the chef supermarket. 

The second line tells Berkshelf to inspect the cookbook's metadata file to determine dependencies (don't worry we will try this out later). 

To verify that your Berksfile is set up correctly, `cd` into the cookbook directory and make sure the following command executes without errors (nothing will be downloaded because we haven't specified any dependencies yet).
```sh
berks install
```

### Setting Up Test Kitchen
To borrow directly from the test-kitchen project:

>Test Kitchen is an integration tool for developing and testing infrastructure code and software on isolated target platforms.

What this means is that test-kitchen is the glue that holds our toolchain together. The kitchen command line tool allows you to create virtual machines using vagrant or another driver, upload your cookbook and its dependencies to that machine using berkshelf, apply your cookbook using chef, and then verify the state of the machine using minitest or another testing framework.

Look inside the `.kitchen.yml` file.
```YAML
driver:
  name: vagrant
  synced_folders:
    - ['../app', '/minions']
  network:
    - ['forwarded_port', {guest: 4567, host: 4567}]
```
What is a driver?
We have specified that we will use vagrant (on top of virtualbox) as a driver. This means that kitchen will create instances using vagrant (other drivers allow you to create instances in the cloud using various cloud drivers).

Inside the `kitchen.yml` file:
```YAML
provisioner:
  name: chef_solo
```

What is a provisioner? We have specified that we will be using chef_solo as a provisioner (this means that we will not be needing a chef server)

Inside the `kitchen.yml` file:
```YAML
platforms:
  - name: ubuntu15
    driver:
      box: bento/ubuntu-15.04
```
What is our platform?
The above lines specifies the type of instance kitchen should create. We will be testing our cookbook on ubuntu-15.04 image. The last 2 lines tell test-kitchen which base image to use when creating instances. 

Look inside the `kitchen.yml` file.
Here we have defined one suite named minions.
```YAML
suites:
  - name: minions
```

### Print out kitchen instances

The first important test-kitchen command you should know is kitchen list. This prints out the instances that kitchen knows about. When you run `kitchen list` it should list a single instance named 'minions-ubuntu15' that is currently identified.
kitchen list

### Creating a Virtual Machine
```
kitchen create
```
This will create an instance but will not apply any recipes. To verify that the virtual machine was successfully, open virtualbox manager (you can do this by running `virtualbox` from the command line) and look for the running guest machine.

### SSH into the new virtual machine
```
kitchen login
```

Look around the VM


Now you are logged into the virtual machine! Your command prompt should have changed to indicate this. From now on we will call this machine the VM or the guest. Take a moment to look around. Maybe try the following commands...
```
whoami
hostname    
ip addr
```
### Exit the VM
```
exit
```
### Check your instance status
If we run `kitchen list` now, we should see that the status of our instance is 'Created'.

### Your First Cookbook
Main Objective: Write a Chef cookbook that will provision an application server for the Minions app.

### Sharing a Folder
How will we get the app code onto the virtual machine? For now, let's share a directory from our host machine with the guest VM. Add the following line to your driver configuration in `.kitchen.yml`.

### kitchen.yml:
```YAML
driver:
  synced_folders:
    - ['../app', '/minions']
```
Be careful when you change the .yml files, they have strict syntax rules. Even a wrongly tabbed space can make a yaml file invalid. 

You can use this [validator](http://codebeautify.org/yaml-validator) to check if your yaml is valid.

Since we have changed our VM configuration we must destroy the VM and recreate it.
```
kitchen destroy
kitchen create
```
Now let's test whether the synced folder is working
```sh
kitchen login
cd /
ls
```
You should see the minions directory on the virtual machine
```sh
cd minions
ls
exit
```
### Installing Ruby
Since Minions is a ruby app, we must install ruby on the guest box in order to run it.

We are going to use the rbenv cookbook to install ruby. First mke sure that rbenv cookbook is listed as a dependency in our metadata file.

Take a moment to look at the [rbenv cookbook documentation](https://supermarket.chef.io/cookbooks/rbenv/versions/1.7.1)

We can use the `rbenv_ruby` resource to install ruby globally on the vagrant machine. We have created an empty `default.rb` file for you in the recipes directory.

Let's include the `rbenv::default` and `rbnev::ruby_build recipes`. The `rbenv::default recipe` installs `rbenv`. And the `rbenv::ruby_build` recipe to install `ruby-build` (an rbenv plugin that allows rbenv to build rubies).
```ruby
include_recipe 'rbenv::default'
include_recipe 'rbenv::ruby_build'
```

### Exercise 1: Install Ruby 2.1.6
Now that we have installed rbenv and ruby_build, let's use the `rbenv_ruby` LWRP (lightweight resources and providers) to install ruby 2.1.6.

We must add our cookbook to the vagrant runlist to apply it to the VM. Add the following to the minions suite under suites: in `.kitchen.yml`. If a cookbook is added to a runlist rather than a specific recipe the default recipe is run.

In .kitchen.yml:
```ruby
run_list:
  - minions
```

Let's apply the cookbook to the instance. `kitchen converge` will apply your run_list to a created instance.
```
kitchen converge
```

### SSH into box
Login to the instance and check the ruby version:

On the vagrant machine run `ruby -v`. The command should print `2.1.6` to the console. If you were unsuccessful, keep updating your recipe and converging until it works!

Now, that we have ruby installed let's try running the app
```sh
cd /minions/lib
ruby run_app.rb
```
Oops! You should see the following error:

>'cannot load such file -- sinatra (LoadError)'.

We need to install bundler on the VM so that we can install Minion's dependencies (which includes Sinatra). Let's write a test first in true TDD fashion!

### Exercise 2: Adding automated tests
As we evolve our recipe, we can manually test our work by logging into the VM and verifying its state from the command line. However we want to treat our infrastructure as similarly to real code as possible. Therefore we will automate our testing. 

You will notice that within the cookbook directory we have added a test directory for you. We have created a file named `default_spec.rb` with one example test in it.
### Run the tests.
```
kitchen verify
```

Before installing bundler via the cookbook, let's write a serverspec test to make sure bundler is installed. Explore the documentation for [serverspec](http://serverspec.org)

Make sure your test fails on an unconverged instance and succeed after the cookbook is applied!

### Exercise 3: Install Bundler
Extend `default.rb` so that it installs the gem 'bundler' on the VM. Hint: look at the rbenv cookbook docs.

When you are ready, converge your instance and see if the test you wrote succeeds.

Now login, and try running `bundle install` in the minions directory. Were you successful? If not, keep trying!

### Verify app is running
When you have successfully installed Minion's dependencies try starting the app again. If it starts successfully you should see the following message
```
Sinatra/1.4.5 has taken the stage on 4567 for development with backup from WEBrick
```

Let's quickly verify this with `curl`. Open a new terminal tab, run `kitchen login` and execute the following command. It should show you the html from the front page with 'Hello Minions!'
```
curl http://localhost:4567
```

Next try to add a minion. Oh no! A database error. This makes sense because we haven't installed the MySQL database yet! Time to improve our `default.rb` recipe.

But first, write as test and see it fail.

## Installing MySQL
### New dependencies
```ruby
depends 'apt',             '=2.9.2'
depends 'mysql',           '~> 6.0'
depends 'mysql2_chef_gem', '~> 1.0'
depends 'database',        '=4.0.9'
```
###  Install MySQL server
We can install MySQL by using the [`mysql_service`](https://github.com/chef-cookbooks/mysql#mysql_service) resource. You can get away with just supplying the port, version, initial root password, and actions.

### Verify mysql is running.
Run `kitchen converge` to apply our recipe to the VM. When the converge is finished login to the VM so we can verify start the installation worked. Login to the guest machine and verify that MySQL is running by executing `service mysql status` returns running. Exit the machine.

### Check if the password has been added.
Converge again. When we log into the machine, we should be able to connect to the MySQL REPL by executing:
```sh
mysql -uroot -pthought
```
### Create Minion Database
After you have successfully connected to the MySQL REPL enter `show databases`; in the REPL. As you can see, there are no databases currently. We must create one with the name "miniondb" for the app to connect to, so that we can add and remove minions.

### Include recipe to help create a database
Now we will use the database MySQL LWRP to create a MySQL database with the name 'miniondb'. The database mysql LWRP requires the [`mysql2`](https://github.com/brianmario/mysql2#mysql2---a-modern-simple-and-very-fast-mysql-library-for-ruby---binding-to-libmysql) gem to be present. The database cookbook [recommends](https://github.com/chef-cookbooks/database#resourcesproviders) that we use the [`mysql2_chef_gem`](https://github.com/chef-cookbooks/database#resourcesproviders) cookbook for its installation; make sure the dependency is in `metadata.rb`, then use it in your recipe by invoking the [`mysql2_chef_gem`](https://github.com/sinfomicien/mysql2_chef_gem#mysql2_chef_gem) resource.
```
include_recipe 'database::mysql'
```
### Exercise 4: Create a MySQL database with the name miniondb
Take a look at the database cookbook documentation. Now, use the [`mysql_database`](https://github.com/chef-cookbooks/database#database) LWRP to create a database with the name miniondb. You will know you are successful when you see miniondb after executing `show databases` in the MySQL REPL.

### Check if your app works!
Run your app. Check if you can add, view and remove your minions. You will need to figure out how to use tasks defined in the app to create the required table. 

### Exercise 5: Add Another Platform
Will this work on other operating systems?
A good chef cookbook should be platform-independent. Each resource often has multiple providers to support this goal. The correct provider is typically automatically selected for the platform – occasionally we might have to specify it explicitly.

Serverspec tests can also be written so that they are platform-independent. Test-kitchen allows you to validate this.

Add a second platform to your `.kitchen.yml` file. Use `bento/centos-7.1`. Run `kitchen test -c` to converge and test CentOS and Ubuntu concurrently.
## Troubleshooting
If Ubuntu is having trouble finding packages (looks like a bunch of attempts to download, returning with 404s), then add `include_recipe::apt` to the beginning of your recipe. This will call `apt-get update` and cause `apt` to update its list of package locations.
