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
