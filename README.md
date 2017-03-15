# :cloud: Lightning Sites

*Lightning Sites* gives you beautifully simple deployment for your ~/Sites folders, inspired by [Fastlane](https://fastlane.tools/). We support all deployment setups, such as:

 * Single developer and push when done

    ```
    [LOCALHOST] ----deploy---> [PRODUCTION]
    ```

 * The way you shouldn't edit PHP websites (but people do it anyway)

    ```
    [LOCALHOST] <---promote/demote---> [PRODUCTION]
    ```

 * Version-controlled with a build step

    ```
    [SCM] <-push/pull-> [LOCALHOST] --build-> [STAGING] --deploy-> [QA/PRODUCTION]
    ```

You set up each site with a simple rakefile and customize as necessary. Then you can perform tasks on multiple sites quickly, including validation, backups and even SEO tasks.


# How to set it up

Enter your website folder and create a `Gemfile` with these contents:

```ruby
gem 'lightning_sites'
```

Then run `bundle install`

There is a full example of a website using lightning-sites at https://github.com/fulldecent/html-website-template

Also create a file named `Rakefile` with these contents:

```ruby
# Uses rake tasks from https://github.com/fulldecent/Sites
abort('Please run this using `bundle exec rake`') unless ENV["BUNDLE_BIN_PATH"]
require 'lightning_sites'
require 'shellwords'
# encoding: UTF-8 # https://stackoverflow.com/a/2105210/300224

##
## SETUP BUILD TASK
##

desc "Perform website build"
task :build do
  puts ''
  puts ' 🔨  Building your website'.blue
  puts ''
  Rake::Task['rsync:copy_build'].invoke
  Rake::Task['git:save_version'].invoke
end


##
## SETUP DEPLOYMENT VARIABLES
##
production_base = 'horseslov@172.16.11.23:'
@production_dir = "#{production_base}www"
@production_backup_targets = {
  'www' => "#{production_base}www",
  'logs' => "#{production_base}logs"
}


##
## CONFIGURE TESTING TASKS
## See more options at https://github.com/fulldecent/Sites
##

desc "Perform validation testing for this website's code"
task :test => [] do
  puts "To run even more tests, which may be expensive, also run text_extensive"
end

desc "Perform more tests with extensive time, bandwidth or other cost"
task :text_extensive do

end


##
## CONFIGURE DEPLOYMENT TASKS
## See more options at https://github.com/fulldecent/Sites
##

desc "This is a task using code from the included library"
task :deploy => ['git:helloworld']

#task :default => :deploy
```


# How to use it

Now you can deploy a site with your new task defined above:

```bash
rake deploy
```

And you can use these other fun built-in tasks. Your `deploy` task above simply composites some of these tasks.

```bash
rake default                   # Show all the tasks
rake distclean                 # Delete all local code and backups
rake git:clone                 # Download and create a copy of code from git server
rake git:pull                  # Fetch and merge from git server, using current checked out branch
rake git:stale_report          # Print the modified date for all files under source control
rake git:status                # Shows status of all files in git repo
rake html:check_links          # Checks links with htmlproofer
rake html:check_onsite         # Checks HTML with htmlproofer, excludes offsite broken link checking
rake html:find_external_links  # Find all external links
rake jekyll:build              # Build Jekyll site
rake jekyll:test               # Run a Jekyll test server
rake rsync:backup              # Backup production
rake rsync:pull                # Bring deployed web server files local
rake rsync:push                # Push local files to production web server
rake seo:find_301              # Find 301s
rake seo:find_404              # Find 404s
```

Additionally you can run tasks on all sites at once. Just run these directly from your ~/Sites folder:

```bash
rake default                   # Show all the tasks
rake distribute[command]       # Run Rake task in each directory
rake setup                     # Review and configure each directory in here
```
