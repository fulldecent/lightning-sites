# http://stackoverflow.com/a/11320444/300224
Rake::TaskManager.record_task_metadata = true

desc "Review and configure each directory in here"
task :setup do
  puts "🌩  Preparing your websites for lightning deployment".green

  folders = Dir.glob('*/')
  if folders.count == 0
    puts 'There are no directories to setup. Please create a directory:'.red
    puts '    mkdir example.com'.yellow
    puts 'Then come back here and run:'.red
    puts '    rake setup'.yellow
    next
  end

  folders.each do |f|
    puts '', ("📂  Found " + f).yellow
    folder_rakefile = f + "Rakefile"
    if File.exists?(folder_rakefile)
      puts '   ✅  Found Rakefile at ' + folder_rakefile.yellow
      setup_is_good = true

      class RakeBrowser
        attr_reader :tasks

        include Rake::DSL
        def task(*args, &block)
          @tasks << args.first.keys.first.id2name
        end

        def initialize(file)
          @tasks = []
          Dir.chdir(File.dirname(file)) do
            eval(File.read(File.basename(file)))
          end
          @variables = instance_variables.map { |name| [name, instance_variable_get(name)] }
        end

        def variables
          @variables = Hash.new
          instance_variables.each do |name|
            @variables[name] = instance_variable_get(name)
          end
          return @variables
        end
      end
      browser = RakeBrowser.new(f + "Rakefile")
      browser.tasks.each do |task|
        puts "        Task: " + task
      end

      if browser.variables[:@staging_dir]
        puts "   ✅  Staging directory is " + f.yellow + browser.variables[:@staging_dir].yellow
      else
        puts "   ❌  Staging directory is not specified".red
        setup_is_good = false
      end

      if browser.variables[:@source_dir]
        puts "   ✅  Source directory is " + f.yellow + browser.variables[:@source_dir].yellow
      else
        puts "   ❌  Source directory is not specified".red
        setup_is_good = false
      end

      if browser.variables[:@bobobo]
        puts "BOBOBO is ".red +  browser.variables[:@bobobo].to_s.red
      end

      if setup_is_good == false
        puts "   Some problems were found with the Rakefile at ".red + folder_rakefile.red
        puts "   Please see documentation at https://github.com/fulldecent/Sites".red
      end
    else
      puts '   No Rakefile found at '.yellow + folder_rakefile.yellow
      puts '   If this directory is not using '
      puts "   FIXME: Add automatic configurator here".red
    end
  end
end

#
# CONFIGURATION
#

production_servers = ['SERVERA', 'SERVERB']


#
# COMMANDS TO SUB-RAKEFILES
#

desc "Run Rake task in each directory"
task :distribute, :command do |t, args|
  require 'Shellwords'
  Dir.glob('./*/Rakefile').each do |f|
    puts '#'.pink, ("# Processing " + File.dirname(f)).pink, '#'.pink
    theCommand = args[:command].shellescape
    sh 'cd ' + File.dirname(f) + "; rake #{theCommand}"
  end
end

desc "Find 404 responses on production servers"
task :find_404 do
  Rake::Task[:distribute].invoke("seo:find_404")
end

desc "Find 301 responses on production servers"
task :find_301 do
  Rake::Task[:distribute].invoke("seo:find_301")
end

desc "Check for on-site HTML errors"
task :html_check_onsite do
  Rake::Task[:distribute].invoke("html:check_onsite")
end

desc "Check for on-site HTML errors"
task :html_check_links do
  Rake::Task[:distribute].invoke("html:check_links")
end



### UPDATE THIS:
desc "Run deliver in each directory"
task :deliver do
  sh 'for a in $(ls ./*/Rakefile); do (cd $(dirname $a); rake -f Rakefile deliver); done'
end

desc "Run status in each directory"
task :status do
  Dir.glob('./*/Rakefile').each do |f|
    puts ("Processing " + File.dirname(f)).pink
    sh 'cd ' + File.dirname(f) + '; rake -f Rakefile status'
  end
end


###
### update these:
###
desc "FIXME: Find errors on production servers"
task :find_errors do
  command = "cut -d' ' -f9- /var/log/httpd/*error.log | sort | uniq -c | sort -nr"
  Rake::Task[:run_on_production_servers].invoke(command)
end

desc "FIXME: Find slow loading pages production servers"
task :find_slow do
  command = "awk '{if($NF>500000)print $7 }' /var/log/httpd/*ssl-access.log | sort | uniq -c | sort -rn | head"
  Rake::Task[:run_on_production_servers].invoke(command)
end

desc "FIXME: Find sales from adwords on production servers"
task :adwords_sales do
  command = "bash /root/adwordssales.sh"
  Rake::Task[:run_on_production_servers].invoke(command)
end


#
# OTHER UTILITIES
#

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

desc "Show all the tasks"
task :default do
  Rake::application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  Rake::application.options.show_task_pattern = //
  Rake::application.display_tasks_and_comments
end
