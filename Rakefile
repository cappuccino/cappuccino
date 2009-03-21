#!/usr/bin/env ruby

require 'common'
require 'rake'
require 'rake/clean'


subprojects = %w{Objective-J Foundation AppKit Tools}

%w(build clean clobber).each do |task_name|
    task task_name do
        subrake(subprojects, task_name)
    end
end

$DEBUG_ENV                      = File.join($BUILD_DIR, 'Debug', 'env')
$RELEASE_ENV                    = File.join($BUILD_DIR, 'Release', 'env')

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

task :tools_download => [$TOOLS_DOWNLOAD_ENV, $TOOLS_DOWNLOAD_EDITORS, $TOOLS_DOWNLOAD_README, $TOOLS_DOWNLOAD_INSTALLER]

task :starter_download => [$STARTER_DOWNLOAD_APPLICATION, $STARTER_DOWNLOAD_README]

file_d $STARTER_DOWNLOAD_APPLICATION => [$TOOLS_DOWNLOAD_ENV] do

    ENV['PATH'] = "#{File.join($TOOLS_DOWNLOAD_ENV, 'bin')}:#{ENV['PATH']}"

    rm_rf($STARTER_DOWNLOAD_APPLICATION)
    mkdir_p($STARTER_DOWNLOAD)
    system %{capp #{$STARTER_DOWNLOAD_APPLICATION} -t Application }

end

file_d $STARTER_DOWNLOAD_README => [$STARTER_README] do
    cp($STARTER_README, $STARTER_DOWNLOAD_README)
end

task :install => [:downloads] do
    system %{cd #{$TOOLS_DOWNLOAD} && sudo sh ./install-tools }
end

=begin
TODO: ojunit stuff:

<git-clone-pull repository = "git://github.com/280north/ojunit.git" dest = "${Build}/Release/ojunit" />
        
        <copy todir = "${Build.Cappuccino.Tools.Lib}/ojunit">
            <fileset dir = "${Build}/Release/ojunit" includes = "**/*.j" />
        </copy>
        
        <copy file = "Tools/ojunit/ojtest" tofile = "${Build.Cappuccino.Tools.Bin}/ojtest" />
        
TODO: documentation

TODO: zip/tar.        
=end
