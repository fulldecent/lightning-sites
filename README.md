# :cloud: Lightning Sites

*Lightning Sites* gives you beautifully simple deployment for your ~/Sites folders. We support all deployment setups, such as:

 * Single developer and push when done
       [LOCALHOST] ----deploy---> [PRODUCTION]

 * The way you shouldn't edit PHP websites (but people do it anyway)
       [LOCALHOST] <---promote/demote---> [PRODUCTION]

 * Version-controlled with a build step
       [SCM] <-push/pull-> [LOCALHOST] --build-> [STAGING] --deploy-> [QA/PRODUCTION]

You set up each site with a simple rakefile and customize as necessary. Then you can perform tasks on multiple sites quickly, including validation, backups and even SEO tasks.


# How to set it up

**Just clone this repository into your ~/Sites directory and run `rake setup`.**

Each website you manage will live in a separate directory in the Sites folder. In each folder, add a `Rakefile` like the following:

```rake
# Uses rake tasks from https://github.com/fulldecent/Sites
load '../common.rake'

production_server = '911coned.com'
production_user = 'medtra10'
production_base = "#{production_user}@#{production_server}:"
@production_dir = "#{production_base}www"
@production_backup_dir = 'production_backup'
@production_backup_targets =
{
  'www' => "#{production_base}www",
  'logs' => "#{production_base}logs",
  'tls' => "#{production_base}/etc/pki/tls/",
  'mysql' => "#{production_base}/var/lib/mysqlbackup/default/newest",
  'postfix' => "#{production_base}/etc/postfix"
}

@source_dir = 'source'
@staging_dir = 'staging'

@git_clone_url = 'git@github.com:fulldecent/mtssites.git'
@git_branch = production_server

desc "Run all build and deployment tasks, for continuous delivery"
task :deliver => ['git:pull', 'jekyll:build', 'rsync:push']
```

# How to use it

Now you can deploy a site with:

```bash
rake deploy
```

And you can do other fun tasks for each site like:

```bash
rake clean              # Delete all local code and backups
rake default            # Show all the tasks
rake deliver            # Run all build and deployment tasks, for continuous delivery
rake git:clone          # Download and create a copy of code from git server
rake git:pull           # Fetch and merge from git server, using current checked out branch
rake git:stale_report   # Print the modified date for all files under source control
rake git:status         # Shows status of all files in git repo
rake html:check_links   # Checks links with htmlproofer
rake html:check_onsite  # Checks HTML with htmlproofer, excludes offsite broken link checking
rake jekyll:build       # Build Jekyll site
rake jekyll:test        # Run a Jekyll test server
rake rsync:backup       # Backup production
rake rsync:pull         # Bring deployed web server files local
rake rsync:push         # Push local files to production web server
rake seo:find_301       # Find 301s
rake seo:find_404       # Find 404s
```

Additionally there are tasks you can run on all sites at once. Just run these directly from your ~/Sites folder:

```bash
rake default              # Show all the tasks
rake distribute[command]  # Run Rake task in each directory
rake setup                # Review and configure each directory in here
```
