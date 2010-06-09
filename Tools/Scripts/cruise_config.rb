Project.configure do |project|
  
  project.email_notifier.emails = ['objjbuild@googlegroups.com']
  project.build_command = 'Tools/Scripts/ci.sh'

end
