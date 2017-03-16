require 'colorize'

# http://stackoverflow.com/a/11320444/300224
Rake::TaskManager.record_task_metadata = true

################################################################################
## Your Rakefile can override these variables
################################################################################
@source_dir = '.'            # Editable source code, preferrably in git repo
@build_dir = 'BUILD'         # Built HTML code
@backup_dir = 'BACKUPS'      # Local home for backups of remote server
@remote_dir = '/dev/null'    # Your remote server, use rsync format
@backup_targets = {}         # Hash from local name to remote directory
                             # uses rsync naming format, example:
                             # {
                             #   'www' => 'horseslov@172.16.11.23:/www',
                             #   'logs' => 'horseslov@172.16.11.23:/logs'
                             # }
@build_excludes = [          # Files you do NOT want copied from SOURCE to BUILD
  'Gemfile',                 # use rsync format
  'Gemfile.lock',
  '.bundle',
  '.git',
  'vendor',
  '/tmp'
]

def create_build_dir (build_dir=@build_dir)
  FileUtils.mkdir_p build_dir
  #TODO: output if directory did not exist and we created it
end

namespace :git do
  def source_dir_is_git?
    return false if !File.directory?(@source_dir)
    return system("cd #{@source_dir} && git rev-parse --git-dir > /dev/null 2> /dev/null")
  end

  desc "Incorporate changes from the remote repository into the current branch"
  task :pull do
    if !source_dir_is_git?
      puts "There is no git directory, skipping"
      next
    end
    puts '⚡️ Pulling git'.blue
    sh "cd '#{@source_dir}'; git pull"
    puts '✅ Pulled'.green
  end

  desc "Displays paths that have differences between the index file and the current HEAD commit"
  task :status do
    if !source_dir_is_git?
      puts "There is no git directory, skipping"
      next
    end
    puts 'Here are differences between git\'s index file and the current HEAD commit'.blue
    sh "cd #{@source_dir} && git status --short"
  end

  desc "Print the modified date for all files under source control"
  task :stale_report do
    if !source_dir_is_git?
      puts "There is no git directory, skipping"
      next
    end
    puts '📋 Here is the modification date for each file'.blue
    sh "cd #{@source_dir} && git ls-files -z | xargs -0 -n1 -I{} -- git log -1 --date=short --format='%ad {}' {}", noop: true
    puts 'Modified   File'.blue
    sh "cd #{@source_dir} && git ls-files -z | xargs -0 -n1 -I{} -- git log -1 --date=short --format='%ad {}' {}", verbose: false
  end

  desc "Save the commit hash to VERSION in the build directory"
  task :save_version do
    if !source_dir_is_git?
      puts "There is no git directory, skipping"
      next
    end
    hash = `cd #{@source_dir} && git rev-parse HEAD`.chomp
    local_changes = `git diff --shortstat`.chomp.length
    File.write(@build_dir + '/VERSION', local_changes ? "#{hash}*\n" : "#{hash}*")
    puts 'Saved git version to VERSION file'.green
  end
end

namespace :jekyll do
  desc "Build Jekyll site"
  task :build do
    create_build_dir
    puts 'Building Jekyll'.blue
    sh "bundle exec jekyll build --incremental --source '#{@source_dir}' --destination '#{@build_dir}'"
    puts 'Built'.green
  end

  desc "Run a Jekyll test server"
  task :test do
    create_build_dir
    puts 'Running test server'.blue
    sh "bundle exec jekyll serve --source '#{@source_dir}' --destination '#{@build_dir}'"
  end
end

# Interact with a production environment
namespace :rsync do
  desc "Copy the source directory to the build directory, excluding some files"
  task :copy_build do
    puts 'Copying source directory to build directory'.blue
    rsync_opts = %w[--archive --delete]
    from = @source_dir + '/'
    to = @build_dir + '/'
    excludes = @build_excludes
    excludes << @backup_dir
    excludes << @build_dir
    excludes.each do |exclude|
      rsync_opts << '--exclude'
      rsync_opts << exclude
    end
    sh 'rsync', *rsync_opts, from, to
    puts 'Copied'.green
  end

  desc "Bring remote files to build directory (use rsync-style paths)"
  task :pull, [:remote] do |t, args|
    args.with_defaults(:remote => @remote_dir)
    puts 'Pulling website from remote'.blue
    rsync_opts = %w[-vr --delete]
    from = args.remote + '/'
    to = @build_dir + '/'
    sh 'rsync', *rsync_opts, from, to
    puts 'Pulled'.green
  end

  desc "Send build directory to remote server (use rsync-style paths)"
  task :push, [:remote] do |t, args|
    args.with_defaults(:remote => @remote_dir)
    puts 'Pushing website to remote'.blue
    rsync_opts = %w[-r -c -v --ignore-times --chmod=ugo=rwX --delete]
    from = @build_dir + '/'
    to = args.remote + '/'
    sh 'rsync', *rsync_opts, from, to
    puts 'Pushed'.green
  end

  desc "Backup items from remote server"
  task :backup do
    puts "Backing up remote server".blue
    rsync_opts = %w[-vaL --delete --exclude .git]
    @backup_targets.each do |local_dir, remote_dir|
      from = remote_dir
      to = @backup_dir + '/' + local_dir
      FileUtils.mkdir_p to
      sh 'rsync', *rsync_opts, from, to
    end
    puts "Backup complete".green
  end
end

# A few nice things you might like
namespace :seo do
  desc "Find 404s"
  task :find_404 do
    puts "Finding 404 errors".blue
    sh 'zgrep', '-r', ' 404 ', "#{@backup_dir}/logs"
    puts "Found".green
  end

  desc "Find 301s"
  task :find_301 do
    puts "Finding 301 errors".blue
    sh 'zgrep', '-r', ' 301 ', "#{@backup_dir}/logs"
    puts "Found".green
  end
end

# Validation for built html folder
namespace :html do
  desc "Checks everything with htmlproofer that is reasonable to check"
  task :check do
    puts "⚡️  Checking HTML".blue
    sh "bundle exec htmlproofer --check-sri --check-external-hash --check-html --check-img-http --check-opengraph --enforce-https --timeframe 6w #{@build_dir}" do |ok, res|
      if !ok
        puts 'Errors found'
        exit(1)
      end
    end
    puts "☀️  Checked HTML".green
  end

  desc "Checks HTML with htmlproofer, skip external links"
  task :check_onsite do
    puts "⚡️  Checking HTML, skipping external links".blue
    sh "bundle exec htmlproofer --disable-external --check-sri --check-html --check-opengraph --enforce-https #{@build_dir}" do
      puts 'Errors found'
      exit(1)
    end
    puts "☀️  Checked HTML".green
  end

  desc "Find all external links"
  task :find_external_links do
    puts "⚡️  Finding all external links".blue
    sh "egrep -oihR '\\b(https?|ftp|file)://[-A-Z0-9+@/%=~_|!:,.;]*[A-Z0-9+@/%=~_|]' #{@build_dir} || true"
  end
end

desc "Delete all built code"
task :clean do
  puts "Deleting all built code".red
  FileUtils.rm_rf(@build_dir)
  FileUtils.rm_rf(@backup_dir)
  puts "Deleting complete".green
end

desc "Show all the tasks"
task :default do
  puts ''
  puts '⚡️ THIS RAKEFILE USES LIGHTNING SITES'.blue
  puts ''

  # http://stackoverflow.com/a/1290119/300224
  Rake::Task["git:status"].invoke

  puts ''
  puts 'Here are all available namespaced rake tasks:'.blue
  Rake::application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  Rake::application.options.show_task_pattern = /:/
  Rake::application.display_tasks_and_comments

  puts ''
  puts 'Here are all available local rake tasks:'.blue
  Rake::application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  Rake::application.options.show_task_pattern = /^[^:]*$/
  Rake::application.display_tasks_and_comments
end
