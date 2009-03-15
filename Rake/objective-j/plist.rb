require 'rake'

module ObjectiveJ
    PLIST_START = '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">'
    PLIST_END = '</plist>'
end

class Module

    def objj_extension(method)
            
        if instance_methods.include?(method)
            $stderr.puts "WARNING: Possible conflict with Objective-J extension: #{self}##{method} already exists"
        else
            yield
        end
    end

end

class Array

    objj_extension('to_plist') do
        def to_plist(start = true)
        
            str = '<array>'
            
            each do |value|
                str += value.to_plist(false)
            end
            
            str = str + '</array>'
            str = ObjectiveJ::PLIST_START + str + ObjectiveJ::PLIST_END if start
            
            return str
        end
    end
end

class FalseClass

    objj_extension('to_plist') do
        def to_plist(start = true)

            str = '<false/>'
            str = ObjectiveJ::PLIST_START + str + ObjectiveJ::PLIST_END if start
            
            return str
        end
    end
end

class Float
    
    objj_extension('to_plist') do
        def to_plist(start = true)

            str = '<real>' + to_s + '</real>'
            str = ObjectiveJ::PLIST_START + str + ObjectiveJ::PLIST_END if start

            return str
        end
    end
end

class Hash

    objj_extension('to_plist') do
        def to_plist(start = true)
            
            str = '<dict>'
            
            each do |key, value|
                str += '<key>' + key.html_encode + '</key>' + value.to_plist(false)
            end
            
            str += '</dict>'
            str = ObjectiveJ::PLIST_START + str + ObjectiveJ::PLIST_END if start
            
            return str
        end
    end
end

class Integer
    
    objj_extension('to_plist') do
        def to_plist(start = true)

            str = '<integer>' + to_s + '</integer>'
            str = ObjectiveJ::PLIST_START + str + ObjectiveJ::PLIST_END
            
            return str
        end
    end
end

class String 

    objj_extension('to_plist') do
        def to_plist(start = true)

            str = '<string>' + html_encode + '</string>'
            str = ObjectiveJ::PLIST_START + str + ObjectiveJ::PLIST_END if start
            
            return str
        end
    end

    objj_extension('html_encode') do
        def html_encode
            return self.gsub(/</, '&lt;').
                        gsub(/>/, '&gt;').
                        gsub(/"/,'&quot;').
                        gsub(/'/, '&apos;').
                        gsub(/&/, '&amp;')
        end
    end
end

class TrueClass

    objj_extension('to_plist') do
        def to_plist(start = true)

            str = '<true/>'
            str = ObjectiveJ::PLIST_START + str + ObjectiveJ::PLIST_END if start

            return str
        end
    end
end
