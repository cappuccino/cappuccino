
require 'objective-j'
require 'rake'

module Rake
    class Application
        # Is there a better (read:supported) way to do this?
        def add_task(name, task)
            @tasks[name.to_s] = task
        end
    end
end

module ObjectiveJ

    class BundleTask < Rake::Task
    
        def initialize(name)
            super name, Rake.application
            Rake.application.add_task name, self
            
            # Each attribute has a default value (possibly nil).  Here, we
            # initialize all attributes to their default value.  This is done
            # through the accessor methods, so special behaviours will be honored.
            # Furthermore, we take a _copy_ of the default so each specification
            # instance has its own empty
            # arrays, etc.
            @@attributes.each do |name, default|
                self.send "#{name}=", copy_of(default)
            end

            @loaded = false
            @@list << self
            yield self if block_given?
            @@gather.call(self) if @@gather
            define
        end

        # ------------------------- Class variables.
        
        # List of Specification instances.
        @@list = []
        
        # Optional block used to gather newly defined instances.
        @@gather = nil
        
        # List of attribute names: [:name, :version, ...]
        @@required_attributes = []
        
        # List of _all_ attributes and default values: [[:name, nil], [:bindir, 'bin'], ...]
        @@attributes = []
        
        # List of array attributes
        @@array_attributes = []
        
        # Map of attribute names to default values.
        @@default_value = {}
        
        # ------------------------- Convenience class methods.
        
        def self.attribute_names
          @@attributes.map { |name, default| name }
        end
        
        def self.attribute_defaults
          @@attributes.dup
        end
        
        def self.default_value(name)
          @@default_value[name]
        end
        
        def self.required_attributes
          @@required_attributes.dup
        end
        
        def self.required_attribute?(name)
          @@required_attributes.include? name.to_sym
        end
        
        def self.array_attributes
          @@array_attributes.dup
        end

        # ------------------------- Infrastructure class methods.
        
        # A list of Specification instances that have been defined in this Ruby instance.
        def self.list
          @@list
        end
        
        ##
        # Used to specify the name and default value of a specification attribute.  The side
        # effects are:
        # * the name and default value are added to the @@attributes list and
        #   @@default_value map
        # * a standard _writer_ method (<tt>attribute=</tt>) is created
        # * a non-standard _reader method (<tt>attribute</tt>) is created
        #
        # The reader method behaves like this:
        #   def attribute
        #     @attribute ||= (copy of default value)
        #   end
        #
        # This allows lazy initialization of attributes to their default values.
        #
        def self.attribute(name, default=nil)
          @@attributes << [name, default]
          @@default_value[name] = default
          attr_accessor(name)
        end

        # Same as :attribute, but ensures that values assigned to the
        # attribute are array values by applying :to_a to the value.
        def self.array_attribute(name)
          @@array_attributes << name
          @@attributes << [name, []]
          @@default_value[name] = []
          module_eval %{
            def #{name}
              @#{name} ||= []
            end
            def #{name}=(value)
              @#{name} = value.to_a
            end
          }
        end
        
        # Same as attribute above, but also records this attribute as mandatory.
        def self.required_attribute(*args)
          @@required_attributes << args.first
          attribute(*args)
        end
        
        # Sometimes we don't want the world to use a setter method for a particular attribute.
        # +read_only+ makes it private so we can still use it internally.
        def self.read_only(*names)
          names.each do |name|
            private "#{name}="
          end
        end
        
        # Shortcut for creating several attributes at once (each with a default value of
        # +nil+).
        def self.attributes(*args)
          args.each do |arg|
            attribute(arg, nil)
          end
        end
        
        # Some attributes require special behaviour when they are accessed.  This allows for
        # that.
        def self.overwrite_accessor(name, &block)
          remove_method name
          define_method(name, &block)
        end

        ##
        # Defines a _singular_ version of an existing _plural_ attribute (i.e. one whose value
        # is expected to be an array).  This means just creating a helper method that takes a
        # single value and appends it to the array.  These are created for convenience, so
        # that in a spec, one can write
        #
        #   s.require_path = 'mylib'
        #
        # instead of
        #
        #   s.require_paths = ['mylib']
        #
        # That above convenience is available courtesy of
        #
        #   attribute_alias_singular :require_path, :require_paths
        #
        def self.attribute_alias_singular(singular, plural)
          define_method("#{singular}=") { |val|
            send("#{plural}=", [val])
          }
          define_method("#{singular}") {
            val = send("#{plural}")
            val.nil? ? nil : val.first
          }
        end

        # ------------------------- REQUIRED framework attributes.

        required_attribute :name
        required_attribute :version
        #required_attribute :date
        attribute :date
        required_attribute :summary
        required_attribute :identifier
        required_attribute :platforms, [Platform::ObjJ]
        
        # ------------------------- OPTIONAL gemspec attributes.
        
        attributes :email, :homepage, :github_project, :description, :license_file, :license
        attributes :build_path, :intermediates_path
        #    attributes :autorequire, :default_executable
        #    attribute :platform,               Gem::Platform::RUBY
        
        array_attribute :authors
        array_attribute :sources
        array_attribute :resources
        array_attribute :flags
        #    array_attribute :test_files
        #    array_attribute :executables
        #    array_attribute :extensions
        #    array_attribute :requirements
        #    array_attribute :dependencies
        
        #read_only :dependencies
        
        # ------------------------- ALIASED gemspec attributes.
        
        #    attribute_alias_singular :executable,   :executables
        attribute_alias_singular :author, :authors
        attribute_alias_singular :flag, :flags
        attribute_alias_singular :platform, :platforms
        #    attribute_alias_singular :require_path, :require_paths
        #    attribute_alias_singular :test_file,    :test_files
        
        # ------------------------- RUNTIME attributes (not persisted).
        
        attr_writer :loaded
        attr_accessor :loaded_from
        
        # ------------------------- Special accessor behaviours (overwriting default).

#        overwrite_accessor :version= do |version|
#            @version = Version.create(version)
#        end
    
        overwrite_accessor :date= do |date|
          # We want to end up with a Time object with one-day resolution.  This is
          # the cleanest, most-readable, faster-than-using-Date way to do it.
          case date
          when String then
            @date = Time.parse date
          when Time then
            @date = Time.parse date.strftime("%Y-%m-%d")
          when Date then
            @date = Time.parse date.to_s
          else
            @date = Time.today
          end
        end

        overwrite_accessor :date do
          self.date = nil if @date.nil?  # HACK Sets the default value for date
          @date
        end
    
        overwrite_accessor :summary= do |str|
          if str
            @summary = str.strip.gsub(/(\w-)\n[ \t]*(\w)/, '\1\2').gsub(/\n[ \t]*/, " ")
          end
        end
    
        overwrite_accessor :description= do |str|
          if str
            @description = str.strip.gsub(/(\w-)\n[ \t]*(\w)/, '\1\2').gsub(/\n[ \t]*/, " ")
          end
        end

        def files
            (@sources || []) | (@resources || []) | (@license_file ? [@license_file] : [])
        end
        
        overwrite_accessor :intermediates_path do
            return @intermediates_path || name + '.build'
        end
        
        overwrite_accessor :build_path do
            return @build_path || './' + name
        end

        # ------------------------- Predicates.
    
        def loaded?; @loaded ? true : false ; end

    # ------------------------- Instance methods.

    ##
    # Returns the full name (name-version) of this Framework.
    #
    def full_name
        @name
    end

    # ------------------------- Comparison methods.

    ##
    # Compare specs (name then version).
    #
    def <=>(other)
      [@name, @version] <=> [other.name, other.version]
    end

    # Tests specs for equality (across all attributes).
    def ==(other)
      @@attributes.each do |name, default|
        return false unless self.send(name) == other.send(name)
      end
      true
    end

    # ------------------------- Validation and normalization methods.

    ##
    # Checks that the specification contains all required fields, and
    # does a very basic sanity check.
    #
    # Raises InvalidSpecificationException if the spec does not pass
    # the checks..
    def validate
=begin
      normalize
      if rubygems_version != RubyGemsVersion
        raise InvalidSpecificationException.new(%[
          Expected RubyGems Version #{RubyGemsVersion}, was #{rubygems_version}
        ].strip)
      end
=end
    @@required_attributes.each do |symbol|
        unless self.send(symbol)
            raise InvalidSpecificationException.new("Missing value for attribute #{symbol}")
        end
    end
=begin
      if require_paths.empty?
        raise InvalidSpecificationException.new("Framework spec needs to have at least one require_path")
      end
=end
    end

    ##
    # Normalize the list of files so that:
    # * All file lists have redundancies removed.
    # * Files referenced in the extra_rdoc_files are included in the package file list.
    #
    # Also, the summary and description are converted to a normal format.
    def normalize
=begin
      if @extra_rdoc_files
        @extra_rdoc_files.uniq!
        @files ||= []
        @files.concat(@extra_rdoc_files)
      end
=end
      @files.uniq! if @files
    end

        def copy_of(obj)
            case obj
            when Numeric, Symbol, true, false, nil then obj
            else obj.dup
            end
        end

#########


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
        
        def define

            validate
            
            resources_path = File.join(build_path, 'Resources')
            copied_resources = []

            # create file tasks for copied resources
            resources.each do |resource|

                copied_resource = File.join(resources_path, File.basename(resource))

                file_d copied_resource => [resource] do
                    cp_r(resource, resources_path)
                end
                
                copied_resources << copied_resource
            end

            info_plist_path = build_path + '/Info.plist'
            info_plist = { 'CPBundleName' => name, 'CPBundleIdentifier' => identifier, 'CPBundleInfoDictionaryVersion' => 6.0, 'CPBundleVersion' => version }
            
            info_plist['CPBundlePlatforms'] =  platforms;
            
            file_d info_plist_path do
                File.open(info_plist_path, 'w') do |file|
                    file.puts info_plist.to_plist
                end
            end

            preprocessed_files = []
            
            # create file tasks for object files
            platforms.uniq.each do |platform|
                
                executable_path = File.join(build_path, PLATFORM_DIRECTORIES[platform], name + '.sj')
                enhance([executable_path])
                
                file_d executable_path do
                    BundleTask.compact(build_path)
                end
                
                # Yes its unfortunate that we need to regenerate the whole executable if the Info.plist changes.  Oh well.
                file_d executable_path => info_plist_path

                sources.each do |source|
    
                    preprocessed_file = File.join(build_path, PLATFORM_DIRECTORIES[platform], File.basename(source))
    
                    file_d preprocessed_file => source do
                        IO.popen("objjc #{resolve_flags(flags)} #{resolve_flags(PLATFORM_FLAGS[platform])} #{source} -o #{preprocessed_file}") do |objjc|
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
            if license != nil
                
                copied_license = build_path + '/LICENSE'

                case license
                    when License::LGPL_v2_1
                        license_path = File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'licenses', '/LGPL-v2.1'))
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

    end  # class BundleSpecification

end # module ObjectiveJ
