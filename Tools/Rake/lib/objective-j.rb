require 'rake'
require 'date'
require 'plist'

module ObjectiveJ

    class Platform
        ObjJ            = 'objj'
        
        Rhino           = 'rhino'
        Desktop         = 'desktop'
        Browser         = 'browser'
        BrowserDesktop  = 'browser-desktop'
        BrowserIPhone   = 'browser-iphone'
        BrowseriPhone   = 'browser-iphone'
    end

end  # module ObjectiveJ

module ObjectiveJ
    
    module License
        LGPL_v2_1    = 'LGPL_v2_1'
    end
    
end

module ObjectiveJ

    class Bundle

        class Type

            Application = :Application
            Framework   = :Framework

            CODE_STRINGS =
            {
                Application => '280N',
                Framework   => 'FMWK'
            }

            def Type.code_string(type)
                return CODE_STRINGS[type] || type.to_s
            end
        end
    end
end

def file_d(*args, &block)
    
    fileTask = Rake::FileTask.define_task(*args, &block)

    fileDirectory = File.dirname(fileTask.name)
    directory fileDirectory
    
    file fileTask.name => fileDirectory
end

def copy_resources(files, destination, &block)

    copied_resources = []

    files.each do |resource|
        baselength = File.basename(resource).length

        if File.directory? resource
            FileList[resource + '/**/*'].each do |subresource|
                if File.file? subresource

                    copied_resource = File.join(destination, subresource[(resource.length - baselength) .. -1])

                    custom_resource = true
                    custom_resource = block.call(subresource, copied_resource) if block_given?

                    if custom_resource == true
                        file_d copied_resource => [subresource] do
                            cp_r(subresource, copied_resource)
                        end

                        copied_resources << copied_resource
                    elsif custom_resource
                        copied_resources << custom_resource
                    end
                end
            end
        else
            copied_resource = File.join(destination, File.basename(resource))

            custom_resource = true
            custom_resource = block.call(resource, copied_resource) if block_given?

            if custom_resource == true
                file_d copied_resource => [resource] do
                    cp_r(resource, copied_resource)
                end

                copied_resources << copied_resource
            elsif custom_resource
                copied_resources << custom_resource
            end
        end
    end

    return copied_resources
end
