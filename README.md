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
abort('Please run this using `bundle exec rake`') unless ENV["BUNDLE_BIN_PATH"]
#require 'lightning_sites' # https://github.com/fulldecent/lightning-sites
load 'LIGHTNINGSITES-BETA.rake'

@build_excludes.push('README.md','LICENSE','CONTRIBUTING.md')
production_base = 'horseslov@172.16.11.23:'
@remote_dir = "#{production_base}www"
@backup_targets = {
  'www' => "#{production_base}www",
  'logs' => "#{production_base}logs"
}

desc "Perform website build"
task :build => ['rsync:copy_build', 'git:save_version']

desc "Perform all testing on the built HTML"
task :test => [:build, 'html:check']

desc "Publish website to productions server"
task :publish => ['rsync:push']
```


# How to use it

Now you can deploy a site with your new task defined above:

```bash
bundle exec rake build
bundle exec rake test
bundle exec rake publish
```

And you can use these other fun built-in tasks. Tasks in your `Rakefile` simply composite some of these tasks.

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
