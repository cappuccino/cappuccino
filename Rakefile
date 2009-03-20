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

$DEBUG_ENV = File.join($BUILD_DIR, 'Release', 'env')
$RELEASE_ENV = File.join($BUILD_DIR, 'Release', 'env')
$TOOLS_ENV = File.join($BUILD_DIR, 'Cappuccino', 'Tools', 'objj')

$STARTER_DOWNLOAD = File.join($BUILD_DIR, 'Cappuccino', 'Starter')
$STARTER_APPLICATION = File.join($BUILD_DIR, 'Cappuccino', 'Starter', 'NewApplication')

task :downloads => [:starter_download, :tools_download]

file_d $TOOLS_ENV => [:debug, :release] do
    cp_r(File.join($RELEASE_ENV, '.'), $TOOLS_ENV)
    cp_r(File.join($DEBUG_ENV, 'lib', 'Frameworks', '.'), File.join($TOOLS_ENV, 'lib', 'Frameworks', 'Debug'))
end

task :tools_download => [$TOOLS_ENV]

task :starter_download => [$STARTER_APPLICATION]

file_d $STARTER_APPLICATION => [$TOOLS_ENV] do

    ENV['PATH'] = "#{File.join($TOOLS_ENV, 'bin')}:#{ENV['PATH']}"

    rm_rf($STARTER_APPLICATION)
    mkdir_p($STARTER_DOWNLOAD)
    system %{capp #{$STARTER_APPLICATION} -t Application }

end

task :install => [:downloads] do

end
