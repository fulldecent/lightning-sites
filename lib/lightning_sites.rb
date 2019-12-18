require 'html-proofer'
require 'mail_to_awesome'
require 'rake'
require 'w3c_validators'
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
  'Rakefile',                # use rsync format
  'Gemfile',
  'Gemfile.lock',
  '.bundle',
  '.git',
  '.gitignore',
  '.travis.yml',
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
    File.write(@build_dir + '/VERSION', local_changes > 0 ? "#{hash}*" : "#{hash}")
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
    rsync_opts = %w[--archive --delete --delete-excluded]
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

  desc "Validate meta descriptions"
  task :validate_meta_descriptions do
    tag = "meta[name='description']"
    max_length = 160
    failed = false
    files = `find #{@build_dir} -type f -name "*.html"`.split("\n")
    files.each { |file|
      begin
        @doc = Nokogiri::XML(File.open(file))
      rescue => msg
        puts "#{msg}".red
        break
      end

      if @doc.at(tag).nil?
        failed = true
        puts "#{file}\n\tMeta description not provided".red
        break
      end

      content = @doc.at(tag)['content']
      if content.length >= max_length
        failed = true
        puts "#{file}\n\tMeta description over #{max_length} characters".red
      elsif content.length == 0
        failed = true
        puts "#{file}\n\tMeta description is empty".red
      end
    }
    if failed
      abort "Validation failed".red
    else
      puts "Validation complete".green
    end
  end
end

# Validation for built html folder
namespace :html do
  desc "Checks everything with htmlproofer that is reasonable to check"
  task :check do
    puts "⚡️  Checking HTML".blue
    options = {
        :check_sri => true,
        :check_external_hash => true,
        :check_html => true,
        :check_img_http => true,
        :check_opengraph => true,
        :enforce_https => true,
        :cache => {
          :timeframe => '6w'
        }
    }
    begin
      HTMLProofer.check_directory("#{@build_dir}", options).run
    rescue => msg
      abort "#{msg}".red
    end
  end

  desc "Checks HTML with htmlproofer, skip external links"
  task :check_onsite do
    puts "⚡️  Checking HTML, skipping external links".blue
    options = {
        :disable_external => true,
        :check_sri => true,
        :check_html => true,
        :check_opengraph => true,
        :enforce_https => true,
        :cache => {
            :timeframe => '6w'
        }
    }
    begin
      HTMLProofer.check_directory("#{@build_dir}", options).run
    rescue => msg
      abort "#{msg}".red
    end
  end

  desc "Checks mailto links with htmlproofer custom test"
  task :check_mailto_awesome do
    puts "⚡️  Checking mailto links".blue
    checks_to_ignore = HTMLProofer::Check.subchecks.map(&:name)
    checks_to_ignore.delete 'MailToAwesome'
    options = {
        :check_mailto_awesome => true,
        :checks_to_ignore => checks_to_ignore,
        :cache => {
            :timeframe => '6w'
        }
    }
    begin
      HTMLProofer.check_directory("#{@build_dir}", options).run
    rescue => msg
      abort "#{msg}".red
    end
  end

  desc "Find all external links"
  task :find_external_links do
    puts "⚡️  Finding all external links".blue
    sh "egrep -oihR '\\b(https?|ftp|file)://[-A-Z0-9+@/%=~_|!:,.;]*[A-Z0-9+@/%=~_|]' #{@build_dir} || true"
  end

  desc "Find old versions of Bootstrap"
  task :web_puc do
    puts "⚡️  Checking for old Bootstrap dependencies".blue
    sh "bundle exec web-puc #{@build_dir}"
  end

  desc "Validate sitemap"
  task :validate_sitemap, :sitemap_path do |t, args|
    args.with_defaults(:sitemap_path => "#{@build_dir}")
    sitemap_path = "#{args[:sitemap_path]}/sitemap.xml"
    puts "⚡️  Validating sitemap".blue
    if File.exist? sitemap_path
      begin
        File.open(sitemap_path) { |f| Nokogiri::XML(f) { |config| config.strict } }
        puts "Validation complete".green
      rescue Nokogiri::XML::SyntaxError => msg
        abort "#{msg}".red
      end
    else
      abort "Sitemap.xml doesn't exists in #{sitemap_path}".red
    end
  end

  desc "Validate css files"
  task :validate_css do
    include W3CValidators
    puts "⚡️  Validating css files".blue
    @validator = CSSValidator.new

    files = `find #{@build_dir} -type f -name "*.css"`.split("\n")
    found_errors = false
    files.each{ |file|
      results = @validator.validate_file(file)

      if results.errors.length > 0
        found_errors = true
        puts file.red
        results.errors.each do |err|
          puts err.to_s.red
        end
      end
    }
    if found_errors
      abort "CSS validation failed".red
    else
      puts "Validation complete".green
    end
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
