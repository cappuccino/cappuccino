require 'rake'

# Read in and set up development environment variables.
if !ENV['BUILD_DIR'] 

    # Global Cappuccino build directory
    if ENV['CAPP_BUILD']
        ENV['BUILD_DIR'] = ENV['CAPP_BUILD']
        
    # Maintain backwards compatibility with steam.
    elsif ENV['STEAM_BUILD']
        ENV['BUILD_DIR'] = ENV['STEAM_BUILD']

    # Just build here.
    else 
        ENV['BUILD_DIR'] = File.join(File.dirname(__FILE__), 'Build')
    end
end

if !ENV['CONFIG']
    ENV['CONFIG'] = 'Release'
end

$CONFIGURATION              = ENV['CONFIG']
$BUILD_DIR                  = File.expand_path(ENV['BUILD_DIR'])
$PRODUCT_DIR                = File.join($BUILD_DIR, $CONFIGURATION)
$ENVIRONMENT_DIR            = File.join($BUILD_DIR, $CONFIGURATION, 'env')
$ENVIRONMENT_BIN_DIR        = File.join($ENVIRONMENT_DIR, 'bin')
$ENVIRONMENT_LIB_DIR        = File.join($ENVIRONMENT_DIR, 'lib') 
$ENVIRONMENT_FRAMEWORKS_DIR = File.join($ENVIRONMENT_LIB_DIR, 'Frameworks')

$HOME_DIR        = File.expand_path(File.dirname(__FILE__))
$LICENSE_FILE    = File.expand_path(File.join(File.dirname(__FILE__), 'LICENSE'))

if !(defined? COMMON_DO_ONCE)
    
    COMMON_DO_ONCE = true
    
    $LOAD_PATH << File.join($HOME_DIR, 'Rake')
    ENV['PATH'] = $ENVIRONMENT_BIN_DIR + ':' + ENV['PATH']
end

require 'objective-j'

$env = ""
$env += %{CONFIG="#{ENV['CONFIG']}" } if ENV['CONFIG']
$env += %{BUILD_DIR="#{ENV['BUILD_DIR']}" } if ENV['BUILD_DIR']

def subrake(directories)
    directories.each do |directory|
        system %{cd #{directory} && #{$env} #{$0}}
    end
end

# Shared Resrouces in env
$JSJAR_PATH = File.expand_path(File.join($HOME_DIR, 'Tools/Utilities/js.jar'))
$ENVIRONMENT_JS = File.join($ENVIRONMENT_LIB_DIR, 'js.jar')

file_d $ENVIRONMENT_JS do
    cp($JSJAR_PATH, $ENVIRONMENT_JS)
end

def js2java(inputfile, className, debug)
    
    debugString = '-nosource -debug' if debug
    
    IO.popen("java -classpath #{$JSJAR_PATH}:. #{debugString} org.mozilla.javascript.tools.jsc.Main -o #{className} #{inputfile}") do |shrinksafe|
        puts shrinksafe.read
    end
end

def cat(files, outfile)

    File.open(outfile, "w") do |concated|
    
        files.each do |file|
          concated.write IO.read(file)
        end 
    end
end

$OBJJ_TEMPLATE_EXECUTABLE   = File.join($HOME_DIR, 'Rake', 'Resources', 'objj-executable')

def make_objj_executable(path)
    cp($OBJJ_TEMPLATE_EXECUTABLE, path)
    File.chmod 0755, path
end

task :build => [$ENVIRONMENT_JS]
task :default => [:build]
