#!/usr/bin/env ruby

require 'common'
require 'rake'
require 'rake/clean'


subprojects = %w{External Objective-J Foundation AppKit Tools External/ojunit}

%w(build clean clobber).each do |task_name|
    task task_name do
        subrake(subprojects, task_name)
    end
end

$DEBUG_ENV                      = File.join($BUILD_DIR, 'Debug', 'env')
$RELEASE_ENV                    = File.join($BUILD_DIR, 'Release', 'env')

$DOXYGEN_CONFIG                 = File.join('Tools', 'Documentation', 'Cappuccino.doxygen')
$DOCUMENTATION_BUILD            = File.join($BUILD_DIR, 'Documentation')

$TOOLS_README                   = File.join('Tools', 'READMEs', 'TOOLS-README')
$TOOLS_EDITORS                  = File.join('Tools', 'Editors')
$TOOLS_INSTALLER                = File.join('Tools', 'Install', 'install-tools')
$TOOLS_DOWNLOAD                 = File.join($BUILD_DIR, 'Cappuccino', 'Tools')
$TOOLS_DOWNLOAD_ENV             = File.join($TOOLS_DOWNLOAD, 'objj')
$TOOLS_DOWNLOAD_EDITORS         = File.join($TOOLS_DOWNLOAD, 'Editors')
$TOOLS_DOWNLOAD_README          = File.join($TOOLS_DOWNLOAD, 'README')
$TOOLS_DOWNLOAD_INSTALLER       = File.join($TOOLS_DOWNLOAD, 'install-tools')

$STARTER_README                 = File.join('Tools', 'READMEs', 'STARTER-README')
$STARTER_DOWNLOAD               = File.join($BUILD_DIR, 'Cappuccino', 'Starter')
$STARTER_DOWNLOAD_APPLICATION   = File.join($STARTER_DOWNLOAD, 'NewApplication')
$STARTER_DOWNLOAD_README        = File.join($STARTER_DOWNLOAD, 'README')

task :downloads => [:starter_download, :tools_download]

file_d $TOOLS_DOWNLOAD_ENV => [:debug, :release] do
    rm_rf($TOOLS_DOWNLOAD_ENV)
    cp_r(File.join($RELEASE_ENV, '.'), $TOOLS_DOWNLOAD_ENV)
    cp_r(File.join($DEBUG_ENV, 'lib', 'Frameworks', '.'), File.join($TOOLS_DOWNLOAD_ENV, 'lib', 'Frameworks', 'Debug'))
end

file_d $TOOLS_DOWNLOAD_EDITORS => [$TOOLS_EDITORS] do
    cp_r(File.join($TOOLS_EDITORS, '.'), $TOOLS_DOWNLOAD_EDITORS)
end

file_d $TOOLS_DOWNLOAD_README => [$TOOLS_README] do
    cp($TOOLS_README, $TOOLS_DOWNLOAD_README)
end

file_d $TOOLS_DOWNLOAD_INSTALLER => [$TOOLS_INSTALLER] do
    cp($TOOLS_INSTALLER, $TOOLS_DOWNLOAD_INSTALLER)
end

task :objj_gem do
    #subrake('Tools/Rake', :objj_gem)
end

task :tools_download => [$TOOLS_DOWNLOAD_ENV, $TOOLS_DOWNLOAD_EDITORS, $TOOLS_DOWNLOAD_README, $TOOLS_DOWNLOAD_INSTALLER, :objj_gem]

task :starter_download => [$STARTER_DOWNLOAD_APPLICATION, $STARTER_DOWNLOAD_README]

task :deploy => [:tools_download, :starter_download, :docs] do
    #copy the docs into the starter pack
    cp_r(File.join($DOCUMENTATION_BUILD, 'html', '.'), File.join($STARTER_DOWNLOAD, 'Documentation'))

    cappuccino_output_path = File.join($BUILD_DIR, 'Cappuccino')

    #zip the starter pack
    starter_zip_output = File.join($BUILD_DIR, 'Cappuccino', 'Starter.zip')
    rm_rf(starter_zip_output)

    `cd #{cappuccino_output_path} && zip -r -8 Starter.zip Starter`

    #zip the tools pack
    tools_zip_output = File.join($BUILD_DIR, 'Cappuccino', 'Tools.zip')
    rm_rf(tools_zip_output)

    `cd #{cappuccino_output_path} && zip -r -8 Tools.zip Tools`
end

file_d $STARTER_DOWNLOAD_APPLICATION => [$TOOLS_DOWNLOAD_ENV] do

    ENV['PATH'] = "#{File.join($TOOLS_DOWNLOAD_ENV, 'bin')}:#{ENV['PATH']}"

    rm_rf($STARTER_DOWNLOAD_APPLICATION)
    mkdir_p($STARTER_DOWNLOAD)
    system %{capp gen #{$STARTER_DOWNLOAD_APPLICATION} -t Application --noconfig }

end

file_d $STARTER_DOWNLOAD_README => [$STARTER_README] do
    cp($STARTER_README, $STARTER_DOWNLOAD_README)
end

task :install => [:downloads] do
    if ENV['prefix']
        prefix = "--prefix #{ENV['prefix']}"
    else
        prefix = ''
    end
    system %{cd #{$TOOLS_DOWNLOAD} && sudo sh ./install-tools #{prefix} }
end

task :test => [:build] do
  tests = "'" + FileList['Tests/**/*.j'].join("' '") + "'"
  build_result = %x{ojtest #{tests} }
  
  if build_result.match(/Test suite failed/i)
    puts "tests failed, aborting the build"
    puts build_result
    rake abort
  else  
    puts build_result
  end
end

task :docs do
    if executable_exists? "doxygen"
      system %{doxygen #{$DOXYGEN_CONFIG} }
      rm_rf $DOCUMENTATION_BUILD
      mv "debug.txt", "Documentation"
      mv "Documentation", $DOCUMENTATION_BUILD
    else
        puts 'doxygen not installed. skipping documentation generation.'
    end
end

task :submodules do
    if executable_exists? "git"
        system %{git submodule init && git submodule update}
    else
        puts "Git not installed"
        rake abort
    end
end

=begin
        
TODO: documentation

TODO: zip/tar.        
=end
