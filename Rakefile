#!/usr/bin/env ruby

require 'rake'
require 'common'


subprojects = %w{Objective-J Foundation AppKit Tools}

%w(build clean).each do |task_name|
  task task_name do
    subrake(subprojects)
  end
end

#task :deploy => [:build]