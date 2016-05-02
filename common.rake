##
## COMMON REQUIRED VARIABLE DEFINITIONS:
##
## @production_server   Where we deploy this site
## @production_user     SSH user
## @production_www_dir  Deploy directory
##
## @staging_dir         Built HTML code
##
## REQUIRED VARIABLES FOR GIT COMMANDS:
##
## @git_clone_url       Git server clone URL
## @git_branch          Branch we use
## @source_dir          Raw source code
##
## REQUIRED VARIABLES FOR JEKYLL
##
## @source_dir          Raw source code
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
    puts 'Showing `git status` of all source files'.pink
    sh "cd #{@source_dir} && git status --short"
  end
end

namespace :jekyll do
  desc "Build Jekyll site"
  task :build do
    puts 'Building Jekyll'.pink
    sh "jekyll build --source '#{@source_dir}' --destination '#{@staging_dir}'"
    puts 'Built'.green
  end

  desc "Run a Jekyll test server"
  task :test do
    puts 'Running test server'.pink
    sh "jekyll serve --source '#{@source_dir}' --destination '#{@staging_dir}'"
  end
end

namespace :rsync do
  desc "Bring deployed web server files local"
  task :pull do
    puts 'Pulling website'.pink
    rsync_opts = '-vr --delete --exclude .git --exclude cache'
    remote = "#{@production_user}@#{@production_server}:#{@production_www_dir}/"
    local = "#{@staging_dir}/"
    sh "rsync #{rsync_opts} '#{remote}' '#{local}'"
    puts 'Pulled'.green
  end

  desc "Push local files to production web server"
  task :push do
    puts 'Pushing website'.pink
    rsync_opts = '-r -c -v --ignore-times --chmod=ugo=rwX --delete --exclude .git --exclude cache'
    remote = "#{@production_user}@#{@production_server}:#{@production_www_dir}/"
    local = "#{@staging_dir}/"
    sh "rsync #{rsync_opts} '#{local}' '#{remote}'"
    puts 'Pushed'.green
  end

  desc "Backup production"
  task :production_backup do
    puts "Backing up production".pink
    rsync_opts = '-va --delete --exclude .git'
    @production_backup_targets.each do |local_dir, remote_dir|
      remote = "#{@production_user}@#{@production_server}:#{remote_dir}"
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
    sh "zgrep -r ' 404 ' '#{@production_backup_dir}/logs'"
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
    #sh "htmlproofer --disable-external --check-html #{@staging_dir} || true"
    sh "htmlproofer --disable-external --check-html --checks-to-ignore ScriptCheck,LinkCheck,HtmlCheck #{@staging_dir} > /dev/null || true"
    puts "☀️  Checked HTML".green
  end

  desc "Checks HTML with htmlproofer, excludes offsite broken link checking"
  task :check_links do
    puts "Checking links".pink
    sh "htmlproofer --verbose --checks-to-ignore ScriptCheck,ImageCheck #{@staging_dir} || true"
    puts "Checked HTML".green
  end
end



desc "Delete all local code and backups"
task :clean do
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
