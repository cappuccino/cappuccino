repositories.remote = ["http://release.intalio.com/m2repo"]
  #, "http://www.intalio.org/public/maven2", "http://dist.codehaus.org/mule/dependencies/maven2", "http://repository.jboss.com/maven2", "http://repo1.maven.org/maven2", "http://mirrors.ibiblio.org/pub/mirrors/maven2" ]

repositories.release_to[:username] ||= "release"
repositories.release_to[:url] ||= "sftp://release.intalio.com/home/release/m2repo"
repositories.release_to[:permissions] ||= 0664
