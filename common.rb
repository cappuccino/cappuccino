require 'rake'

def gem_command
    case RUBY_PLATFORM
    when /win32/
        'gem.bat'
    when /java/
        'jruby -S gem'
    else
        'gem'
    end
end

begin
    require 'rubygems'
    require 'plist'
rescue LoadError
    puts 'Plist gem not installed, installing...'
    cmd = "#{gem_command} install plist"
    puts cmd
    puts %x(#{cmd})
end

# Read in and set up development environment variables.
if !ENV['BUILD_PATH']

    # Global Cappuccino build directory
    if ENV['CAPP_BUILD']
        ENV['BUILD_PATH'] = ENV['CAPP_BUILD']
        
    # Maintain backwards compatibility with steam.
    elsif ENV['STEAM_BUILD']
        ENV['BUILD_PATH'] = ENV['STEAM_BUILD']

    # Just build here.
    else 
        ENV['BUILD_PATH'] = File.join(File.dirname(__FILE__), 'Build')
    end
end

ENV['BUILD_PATH'] = File.expand_path(ENV['BUILD_PATH'])

if !ENV['CONFIG']
    ENV['CONFIG'] = 'Release'
end

$CONFIGURATION              = ENV['CONFIG']
$BUILD_DIR                  = ENV['BUILD_PATH']
$PRODUCT_DIR                = File.join($BUILD_DIR, $CONFIGURATION)
$ENVIRONMENT_DIR            = File.join($BUILD_DIR, $CONFIGURATION, 'env')
$ENVIRONMENT_BIN_DIR        = File.join($ENVIRONMENT_DIR, 'bin')
$ENVIRONMENT_LIB_DIR        = File.join($ENVIRONMENT_DIR, 'lib') 
$ENVIRONMENT_FRAMEWORKS_DIR = File.join($ENVIRONMENT_LIB_DIR, 'Frameworks')

$HOME_DIR        = File.expand_path(File.dirname(__FILE__))
$LICENSE_FILE    = File.expand_path(File.join(File.dirname(__FILE__), 'LICENSE'))

if !(defined? COMMON_DO_ONCE)
    
    COMMON_DO_ONCE = true
    
    $LOAD_PATH << File.join($HOME_DIR, 'Tools', 'Rake', 'lib')
    ENV['PATH'] = $ENVIRONMENT_BIN_DIR + ':' + ENV['PATH']
end

require 'objective-j'

def serialized_env
    env = ""
    env += %{CONFIG="#{ENV['CONFIG']}" } if ENV['CONFIG']
    env += %{BUILD_DIR="#{ENV['BUILD_DIR']}" } if ENV['BUILD_DIR']

    return env

end

def subrake(directories, task_name)
    directories.each do |directory|
      if (File.directory?(directory) && File.file?(File.join(directory, "Rakefile")))
        ok = system(%{cd #{directory} && #{$serialized_env} #{$0} #{task_name}})
        rake abort unless ok
      else
        puts "warning: subrake missing: " + directory +" (this is not necessarily an error, "+directory+" may be optional)"
      end
    end
end

def executable_exists?(name)
  ENV["PATH"].split(":").any? {|p| File.executable? File.join(p, name) }
end

$OBJJ_TEMPLATE_EXECUTABLE   = File.join($HOME_DIR, 'Tools', 'Rake', 'lib', 'objj-executable')

def make_objj_executable(path)
    cp($OBJJ_TEMPLATE_EXECUTABLE, path)
    File.chmod 0755, path
end

task :build
task :default => [:build]

task :release do
    ENV['CONFIG'] = 'Release'
    spawn_rake(:build)
end

task :debug do
    ENV['CONFIG'] = 'Debug'
    spawn_rake(:build)
end

task :all => [:debug, :release]

task 'clean-debug' do
    ENV['CONFIG'] = 'Debug'
    spawn_rake(:clean)
end

task :cleandebug => ['clean-debug']

task 'clean-release' do
    ENV['CONFIG'] = 'Release'
    spawn_rake(:clean)
end

task :cleanrelease => ['clean-release']

task 'clean-all' => ['clean-debug', 'clean-release']
task :cleanall => ['clean-all']

task 'clobber-debug' do
    ENV['CONFIG'] = 'Debug'
    spawn_rake(:clobber)
end

task :clobberdebug => ['clobber-debug']

task 'clobber-release' do
    ENV['CONFIG'] = 'Release'
    spawn_rake(:clobber)
end

task :clobberrelease => ['clobber-release']

task 'clobber-all' => ['clobber-debug', 'clobber-release']
task :clobberall => ['clobber-all']

def spawn_rake(task_name)
    system %{#{$serialized_env} #{$0} #{task_name}}
end
