require 'rake'



module ObjectiveJ

    class BundleTask < Rake::Task

        PLATFORM_DIRECTORIES = 
        { 
            Platform::ObjJ              => 'objj.platform',
            Platform::Rhino             => 'rhino.platform',
            Platform::Browser           => 'browser.platform',
            Platform::BrowserDesktop    => 'browser-desktop.platform',
            Platform::BrowserIPhone     => 'browser-iphone.platform'
        }
        
        PLATFORM_FLAGS =
        {
            Platform::ObjJ              => [],
            Platform::Rhino             => ['PLATFORM_RHINO'],
            Platform::Browser           => ['PLATFORM_BROWSER', 'PLATFORM_DOM'],
            Platform::BrowserDesktop    => ['PLATFORM_BROWSER', 'PLATFORM_DOM', 'PLATFORM_DESKTOP'],
            Platform::BrowserIPhone     => ['PLATFORM_BROWSER', 'PLATFORM_DOM', 'PLATFORM_IPHONE', 'PLATFORM_MOBILE']
        }

        # Objective-J Bundle spec containing the metadata for this bundle.
        attr_accessor :bundle_spec
                
        def self.overwrite_accessor(name, &block)
            remove_method name
            define_method(name, &block)
        end
        
        overwrite_accessor :bundle_spec= do |spec|

            @bundle_spec = spec
            
            @bundle_spec.validate
            
            resources_path = File.join(@bundle_spec.build_path, 'Resources')
            copied_resources = []

            # create file tasks for copied resources
            @bundle_spec.resources.each do |resource|

                copied_resource = File.join(resources_path, File.basename(resource))

                file_d copied_resource => [resource] do
                    cp_r(resource, resources_path)
                end
                
                copied_resources << copied_resource
            end

            info_plist_path = @bundle_spec.build_path + '/Info.plist'
            info_plist = @bundle_spec.info_plist
            
            info_plist['CPBundlePlatforms'] =  @bundle_spec.platforms;
            
            file_d info_plist_path do
                File.open(info_plist_path, 'w') do |file|
                    file.puts info_plist.to_plist
                end
            end

            preprocessed_files = []
            
            # create file tasks for object files
            @bundle_spec.platforms.uniq.each do |platform|
                
                executable_path = File.join(@bundle_spec.build_path, PLATFORM_DIRECTORIES[platform], @bundle_spec.name + '.sj')
                enhance([executable_path])
                
                file_d executable_path do
                    BundleTask.compact(@bundle_spec.build_path)
                end
                
                # Yes its unfortunate that we need to regenerate the whole executable if the Info.plist changes.  Oh well.
                file_d executable_path => info_plist_path

                @bundle_spec.sources.each do |source|
    
                    preprocessed_file = File.join(@bundle_spec.build_path, PLATFORM_DIRECTORIES[platform], File.basename(source))
    
                    file_d preprocessed_file => source do
                        IO.popen("objjc #{resolve_flags(@bundle_spec.flags)} #{resolve_flags(PLATFORM_FLAGS[platform])} #{source} -o #{preprocessed_file}") do |objjc|
                            puts objjc.read
                        end
                    end
                    
                    preprocessed_files << preprocessed_file
                    
                    file_d executable_path => preprocessed_file
                end
            end

            # copy license file
            license_path = nil
            
            # check if a license type has been specified
            if @bundle_spec.license != nil
                
                copied_license = @bundle_spec.build_path + '/LICENSE'

                case @bundle_spec.license
                    when License::LGPL_v2_1
                        license_path = File.expand_path(File.join(File.dirname(__FILE__), '../LGPL-v2.1'))
                    else
                        license_path = license
                end
                
                file_d copied_license => license_path do
                    cp(license_path, copied_license)
                end
            end

            enhance(preprocessed_files + copied_resources + [info_plist_path])
        end

        def BundleTask.compact(path, *patterns)
        
            puts 'Compacting ' + path
            
            info_plist_path = File.join(path, 'Info.plist')
            info_plist = Plist::parse_xml(info_plist_path)
            
            absolute_path = File.expand_path(path) + '/'

            patterns = patterns.map { |pattern| "#{path}/#{pattern}" }
            
            bundle_name = info_plist['CPBundleName']
            replaced_files = []

            FileList.new(File.join(path, '**', '*.platform')).each do |platform|
            
                FileList.new(File.join(platform, '*.j')) do |list|
                    
                    list.include(*patterns)
                    
                    executable_path = File.join(platform, bundle_name) + '.sj'
                    platform_absolute_path = File.expand_path(platform) + '/'
                    
                    File.open(executable_path, 'w+') do |executable|
                    
                        executable.write '@STATIC;1.0;'
                        
                        list.each do |fileName|
                        
                            File.open(fileName) do |file|
                            
                                if fileName.index(platform_absolute_path) == 0
                                    fileName = File.expand_path(fileName)[platform_absolute_path.length..-1]
                                else
                                    fileName = File.expand_path(fileName)[absolute_path.length..-1]
                                end
                                
                                executable.write "p;#{fileName.length};#{fileName}#{file.read}"
                                
                                replaced_files << fileName
                            end
                        end
                    end                    
                end
            end

            info_plist['CPBundleReplacedFiles'] = replaced_files.uniq
            info_plist['CPBundleExecutable'] = bundle_name + '.sj'
            
            File.open(info_plist_path, 'w') do |file|
                file.puts info_plist.to_plist
            end
            
        end
    end
end
