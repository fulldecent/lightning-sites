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

You set up each site with a simple rakefile and customize as necessary. Then you can perform powerful tasks quickly, including validation, backups and even SEO tasks.


# Instant setup

**The easiest way to to use Lightning Sites is to [clone the example repository](https://github.com/fulldecent/html-website-template).** It is a one-page website, about horses, and includes everything a modern website should have. You do NOT need to be a programmer to use that template, it is very end-user friendly. Click the link and see the features checklist if you are interested.

# Slow setup

Create a `Gemfile` and add `lightning_sites` to it

```ruby
source "https://rubygems.org"

gem "lightning_sites"
```

And install with:

```sh
gem install bundler
bundle init; echo "gem 'lightning_sites'" >> Gemfile
export NOKOGIRI_USE_SYSTEM_LIBRARIES=true
bundle install
```

Next, create a `Rakefile` by starting with this and editing server credentials:

```ruby
abort('Please run this using `bundle exec rake`') unless ENV["BUNDLE_BIN_PATH"]
require 'lightning_sites' # https://github.com/fulldecent/lightning-sites

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

* Update `.gitignore` to include `tmp`, `BUILD/` and `BACKUP/`
* Update `_travis.yml` to call `bundle exec rake test`, [see full example here](https://github.com/fulldecent/html-website-template/blob/master/.travis.yml)
* Update Jekyll excludes in `_config.yml`, if you have one, and exclude these new files and gitignores

# How to use it

Here are the amazing new commands you can use right away.

```bash
bundle exec rake build
bundle exec rake test
bundle exec rake publish
```

Here is the full list of tasks. This list comes up by default when you run `bundle exec rake`.

```bash
rake git:pull                  # Incorporate changes from the remote repository into the current branch
rake git:save_version          # Save the commit hash to VERSION in the build directory
rake git:stale_report          # Print the modified date for all files under source control
rake git:status                # Displays paths that have differences between the index file and the current HEAD commit
rake html:check                # Checks everything with htmlproofer that is reasonable to check
rake html:check_onsite         # Checks HTML with htmlproofer, skip external links
rake html:find_external_links  # Find all external links
rake jekyll:build              # Build Jekyll site
rake jekyll:test               # Run a Jekyll test server
rake rsync:backup              # Backup items from remote server
rake rsync:copy_build          # Copy the source directory to the build directory, excluding some files
rake rsync:pull[remote]        # Bring remote files to build directory (use rsync-style paths)
rake rsync:push[remote]        # Send build directory to remote server (use rsync-style paths)
rake seo:find_301              # Find 301s
rake seo:find_404              # Find 404s
```
