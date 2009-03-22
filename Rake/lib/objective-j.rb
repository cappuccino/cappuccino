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

        def Platform.directory(aPlatform)
            return PLATFORM_DIRECTORIES[aPlatform]
        end

        def Platform.flags(aPlatform)
            return PLATFORM_FLAGS[aPlatform]
        end
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

def resolve_flags(flags)

    case flags
    when nil then ''
    when String then '-D' + flags
    when Array then flags.map { |flag| '-D' + flag }.join(' ')
    when Hash then flags.map { |flag, value| '-D' + flag + (value != '' ? '=' + value : '') }.join(' ')
    end
end
