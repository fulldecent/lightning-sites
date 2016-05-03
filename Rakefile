# http://stackoverflow.com/a/11320444/300224
Rake::TaskManager.record_task_metadata = true

class RakeBrowser
  attr_reader :tasks
  attr_reader :variables
  attr_reader :loads
  @last_description = ''
  @namespace = ''

  include Rake::DSL

  def desc(description)
    @last_description = description
  end

  def namespace(name=nil, &block) # :doc:
    old = @namespace
    @namespace = "#{name}:#{@namespace}"
    yield(block)
    @namespace = old
  end

  def task(*args, &block)
    if args.first.respond_to?(:id2name)
      @tasks << "#{@namespace}" + args.first.id2name
    elsif args.first.keys.first.respond_to?(:id2name)
      @tasks << "#{@namespace}" + args.first.keys.first.id2name
    end
  end

  def load(filename)
    @loads << filename
  end

  def initialize(file)
    @tasks = []
    @loads = []
    Dir.chdir(File.dirname(file)) do
      eval(File.read(File.basename(file)))
    end
    @variables = Hash.new
    instance_variables.each do |name|
      @variables[name] = instance_variable_get(name)
    end
  end
end

desc "Review and configure each directory in here"
task :setup do
  puts "🌩  Preparing your websites for lightning deployment".green
  total_sites = 0
  good_sites = 0

  folders = Dir.glob('*/')
  if folders.count == 0
    puts 'There are no directories to setup. Please create a directory:'.red
    puts '    mkdir example.com'.yellow
    puts 'Then come back here and run:'.red
    puts '    rake setup'.yellow
    next
  end

  folders.each do |f|
    puts '', ("☁️  Found " + f).yellow
    folder_rakefile = f + "Rakefile"
    total_sites = total_sites + 1

    unless File.exists?(folder_rakefile)
      puts '     No Rakefile found at ' + folder_rakefile
      puts "     To setup 🌩 Lightning Deployment, add a Rakefile to this directory"
      puts "     FIND AN EXAMPLE SITE RAKEFILE AT https://github.com/fulldecent/Sites".red
      next
    end

    puts '     Found Rakefile at ' + folder_rakefile.yellow
    setup_is_good = true
    browser = RakeBrowser.new(f + "Rakefile")

    if browser.loads.include?('../common.rake')
      puts "     Common rakefile is loaded"
    else
      puts "     Common rakefile is not loaded".red
      setup_is_good = false
    end

    if browser.variables[:@source_dir]
      puts "     Source directory is " + f.yellow + browser.variables[:@source_dir].yellow
    else
      puts "     Source directory is not specified".red
      setup_is_good = false
    end

    if browser.variables[:@staging_dir]
      puts "     Staging directory is " + f.yellow + browser.variables[:@staging_dir].yellow
    else
      puts "     Staging directory is not specified".red
      setup_is_good = false
    end

    browser.tasks.each do |task|
      puts "     Custom task: " + task
    end

    if setup_is_good
      good_sites = good_sites + 1
      puts "     🌩  Boom, this site is good to go".green
    else
      puts "     Some problems were found with the Rakefile at ".red + folder_rakefile.red
      puts "     Please see documentation at https://github.com/fulldecent/Sites".red
    end
  end

  if good_sites > 0
    puts ""
    puts "🌩  Lightning deployment is setup for ".green + good_sites.to_s.green + " sites. To see the cool stuff you can do, type:".green
    puts "", "    rake".yellow, "    (Yup, that's it)", ""
  else
  end
end

desc "Run Rake task in each directory"
task :distribute, :command do |t, args|
  require 'Shellwords'
  Dir.glob('./*/Rakefile').each do |f|
    puts "🌩  ".cyan + File.dirname(f).cyan
    theCommand = args[:command].shellescape
    sh 'cd ' + File.dirname(f) + "; rake #{theCommand}"
  end
end

desc "Show all the tasks"
task :default do
  Rake::application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  Rake::application.options.show_task_pattern = //
  Rake::application.display_tasks_and_comments

  puts ""
  puts "The following tasks can also run from any site folder."
  puts "Or run them on all sites using: " + "distribute[command]".yellow
  puts ""
  puts "For descriptions, run " + "rake --tasks".yellow + " from any project folder."
  puts "FIXME: add these descriptions directly here!!"
  puts ""

  browser = RakeBrowser.new('common.rake')

  browser.tasks.each do |task|
    puts "  " + task
  end
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

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def cyan
    colorize(36)
  end
end
