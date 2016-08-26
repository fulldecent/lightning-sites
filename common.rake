##
## EVERY SITE MUST DEFINE THESE VARIABLES:
##
## @source_dir                 Raw source code
## @staging_dir                Built HTML code
##
##
## OPTIONAL VARIABLES FOR DEPLOYMENT:
##
## @production_dir             A local or remote directory (rsync format) to deploy to
## @production_backup_dir      Where backups go
## @production_backup_targets  Hash of {folder => what_should_backup_to_there}
##
##
## REQUIRED VARIABLES FOR GIT COMMANDS:
##
## @git_clone_url       Git server clone URL
## @git_branch          Branch we use
##

# http://stackoverflow.com/a/11320444/300224
Rake::TaskManager.record_task_metadata = true

require 'shellwords'

desc "Show all the tasks"
task :default do
  Rake::application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  Rake::application.options.show_task_pattern = //
  Rake::application.display_tasks_and_comments
end

namespace :git do
  def source_dir_is_git?
    return false if !File.directory?(@source_dir)
    sh "cd #{@source_dir} && git rev-parse --git-dir > /dev/null 2> /dev/null" do |ok, res|
      return ok
    end
  end

  desc "Download and create a copy of code from git server"
  task :clone do
    puts 'Cloning repository'.pink
    sh "git clone -b #{@git_branch} --single-branch #{@git_clone_url} #{@source_dir}"
    puts 'Clone complete'.green
  end

  desc "Fetch and merge from git server, using current checked out branch"
  task :pull do
    puts 'Pulling git'.pink
    sh "cd '#{@source_dir}'; git pull"
    puts 'Pulled'.green
  end

  desc "Shows status of all files in git repo"
  task :status do
    if !source_dir_is_git?
      puts "There is no git directory, skipping"
      next
    end
    puts 'Showing `git status` of all source files'.pink
    sh "cd #{@source_dir} && git status --short"
  end

  desc "Print the modified date for all files under source control"
  task :stale_report do
    if !source_dir_is_git?
      puts "There is no git directory, skipping"
      next
    end
    sh "cd #{@source_dir} && git ls-files -z | xargs -0 -n1 -I{} -- git log -1 --format='%ai {}' {} | cut -b 1-11,27-"
  end
end

namespace :jekyll do
  desc "Build Jekyll site"
  task :build do
    puts 'Building Jekyll'.pink
    sh "jekyll build --incremental --source '#{@source_dir}' --destination '#{@staging_dir}'"
    puts 'Built'.green
  end

  desc "Run a Jekyll test server"
  task :test do
    puts 'Running test server'.pink
    sh "jekyll serve --source '#{@source_dir}' --destination '#{@staging_dir}'"
  end
end

# Interact with a production environment
namespace :rsync do
  desc "Bring deployed web server files local"
  task :pull do
    raise '@production_dir is not defined' unless defined? @production_dir
    raise '@staging_dir is not defined' unless defined? @staging_dir
    puts 'Pulling website'.pink
    rsync_opts = '-vr --delete --exclude .git --exclude cache'
    remote = "#{@production_dir}/"
    local = "#{@staging_dir}/"
    sh "rsync #{rsync_opts} '#{remote}' '#{local}'"
    puts 'Pulled'.green
  end

  desc "Push local files to production web server"
  task :push do
    raise '@production_dir is not defined' unless defined? @production_dir
    raise '@staging_dir is not defined' unless defined? @source_dir
    puts 'Pushing website'.pink
    rsync_opts = '-r -c -v --ignore-times --chmod=ugo=rwX --delete --exclude .git --exclude cache'
    remote = "#{@production_dir}/"
    local = "#{@staging_dir}/"
    sh "rsync #{rsync_opts} '#{local}' '#{remote}'"
    puts 'Pushed'.green
  end

  desc "Backup production"
  task :backup do
    raise '@production_backup_dir is not defined' unless defined? @production_backup_dir
    raise '@production_backup_targets is not defined' unless defined? @production_backup_targets
    puts "Backing up production".pink
    rsync_opts = '-vaL --delete --exclude .git'
    @production_backup_targets.each do |local_dir, remote_dir|
      remote = "#{remote_dir}"
      local = "#{@production_backup_dir}/#{local_dir}/"
      sh 'mkdir', '-p', local
      sh "rsync #{rsync_opts} '#{remote}' '#{local}'"
    end
    puts "Backup complete".green
  end
end

namespace :seo do
  desc "Find 404s"
  task :find_404 do
    puts "Finding 404 errors".pink
    sh 'zgrep', '-r', ' 404 ', "#{@production_backup_dir}/logs"
#    sh "zgrep -r ' 404 ' '#{@production_backup_dir}/logs'"
    puts "Found".green
  end

  desc "Find 301s"
  task :find_301 do
    puts "Finding 301 errors".pink
    sh "zgrep -r ' 301 ' '#{@production_backup_dir}/logs'"
    puts "Found".green
  end
end

namespace :html do
  desc "Checks HTML with htmlproofer, excludes offsite broken link checking"
  task :check_onsite do
    puts "⚡️  Checking HTML".pink
    sh "bundle exec htmlproofer --disable-external --check-html --checks-to-ignore ScriptCheck,LinkCheck,HtmlCheck #{@staging_dir} > /dev/null || true"
    puts "☀️  Checked HTML".green
  end

  desc "Checks links with htmlproofer"
  task :check_links do
    puts "⚡️  Checking links".pink
    sh "bundle exec htmlproofer --checks-to-ignore ScriptCheck,ImageCheck #{@staging_dir} || true"
    puts "☀️  Checked HTML".green
  end

  desc "Find all external links"
  task :find_external_links do
    puts "⚡️  Finding all external links".pink
    sh "egrep -oihR '\\b(https?|ftp|file)://[-A-Z0-9+@/%=~_|!:,.;]*[A-Z0-9+@/%=~_|]' #{@staging_dir} || true"
  end
end

desc "Delete all local code and backups"
task :distclean do
  puts "Deleting all local code and backups".pink
  FileUtils.rm_rf(@source_dir)
  FileUtils.rm_rf(@staging_dir)
  FileUtils.rm_rf(@production_backup_dir)
  puts "Deleting complete".green
end

# https://stackoverflow.com/questions/1489183/colorized-ruby-output
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end
