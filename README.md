# Sites

:cloud: Lightning deployment for your ~/Sites folders


# How to set it up

Clone this repository into your ~/Sites directory. Then make a folder for each website you manage. In each of your sites, add a `Rakefile` like the following:

    # Uses rake tasks from https://github.com/fulldecent/Sites
    load '../common.rake'

    # Rsync options
    @production_server = 'myserver.com'
    @production_user = 'root'
    @production_www_dir = '/var/www/vhosts/myserver.com'
    @production_backup_dir = 'production_backup'
    @production_backup_targets =
    {
      'www' => "/var/www/vhosts/myserver.com",
      'tls' => '/etc/pki/tls/',
      'mysql' => '/var/lib/mysqlbackup/default/newest',
      'postfix' => '/etc/postfix',
      'logs' => '/var/log/httpd'
    }

    @source_dir = 'source'
    @staging_dir = 'staging'

    @git_clone_url = 'git@github.com:fulldecent/mtssites.git'
    @git_branch = @production_server

    desc "Run all build and deployment tasks, for continuous delivery"
    task :deliver => ['git:pull', 'jekyll:build', 'rsync:push']


# How to use it

Now you can deploy a site with:

    rake deploy

And you can do other fun tasks for each site like:

    rake clean                    # Delete all local code and backups
    rake default                  # Show all the tasks
    rake deliver                  # Run all build and deployment tasks, for con...
    rake git:clone                # Download and create a copy of code from git...
    rake git:pull                 # Fetch and merge from git server, using curr...
    rake git:status               # Shows status of all files in git repo
    rake html:check_links         # Checks HTML with htmlproofer, excludes offsit...
    rake html:check_onsite        # Checks HTML with htmlproofer, excludes offsit...
    rake jekyll:build             # Build Jekyll site
    rake jekyll:test              # Run a Jekyll test server
    rake rsync:production_backup  # Backup production
    rake rsync:pull               # Bring deployed web server files local
    rake rsync:push               # Push local files to production web server
    rake seo:find_301             # Find 301s
    rake seo:find_404             # Find 404s

Additionally there are tasks you can run on all sites at once. Just run these directly from your ~/Sites folder:

    rake adwords_sales        # FIXME: Find sales from adwords on production se...
    rake default              # Show all the tasks
    rake deliver              # Run deliver in each directory
    rake distribute[command]  # Run Rake task in each directory
    rake find_301             # Find 301 responses on production servers
    rake find_404             # Find 404 responses on production servers
    rake find_errors          # FIXME: Find errors on production servers
    rake find_slow            # FIXME: Find slow loading pages production servers
    rake html_check_links     # Check for on-site HTML errors
    rake html_check_onsite    # Check for on-site HTML errors
    rake status               # Run status in each directory
