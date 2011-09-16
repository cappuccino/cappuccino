require File.join(File.dirname(__FILE__), "repositories.rb")
require File.join(File.dirname(__FILE__), "dependencies.rb")

# Keep this structure to allow the build system to update version numbers.
VERSION_NUMBER = "1.0.0.016"


# Shorten expressions
def jars(*args)
 args.collect {|arg| project(arg).package(:jar)}
end

desc "Cappuccino Distribution"
define "cappuccino" do
  project.version = VERSION_NUMBER
  project.group = "com.intalio.cloud.cappuccino"

  file(_("target/patch")).enhance do
    mkdir_p "target/patch"
  end

  file(_("target/Frameworks")).enhance do
    mkdir_p "target/Frameworks/Debug"
        system <<-BASH
export BUILD_PATH="target/Build"
jake debug release
BASH

    cp_r "target/Build/Release/AppKit", "target/Frameworks/"
    cp_r "target/Build/Release/Foundation", "target/Frameworks/"
    cp_r "target/Build/Release/Objective-J", "target/Frameworks/"
    cp_r "target/Build/Debug/AppKit", "target/Frameworks/Debug/"
    cp_r "target/Build/Debug/Foundation", "target/Frameworks/Debug/"
    cp_r "target/Build/Debug/Objective-J", "target/Frameworks/Debug/"
  end

  # file(_("target/Build")).enhance do
  # end
  read_m = ::Buildr::Packaging::Java::Manifest.parse(File.read(_("META-INF/MANIFEST.MF"))).main
  read_m["Copyright"]="Intalio, Inc 2011"
  read_m["Bundle-Version"]=VERSION_NUMBER.gsub(/SNAPSHOT/, "#{Time.now.to_i}")
  read_m.delete("Jetty-WarFragmentFolderPath")
  read_m.delete("Jetty-WarPatchFragmentFolderPath")
  package(:jar).with :manifest => read_m
  #package(:jar).include _("target/patch"), :as => "patch"
  package(:jar).include _("target/Frameworks"), :as => "META-INF/resources/Frameworks"

  #do not include those: they are at best not read harmful.
  #package(:bundle).include _("build.properties"), :as => "build.properties"
  #package(:bundle).meta_inf << file('META-INF/web-fragment.xml')

end


