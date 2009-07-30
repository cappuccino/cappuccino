
require 'objective-j'
require 'rake'
require 'rake/clean'

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

        required_attribute :summary
        required_attribute :identifier
        required_attribute :include_nibs, false
        required_attribute :nib2cib_flags, []
        required_attribute :platforms, [Platform::ObjJ]
        required_attribute :type, Bundle::Type::Application
        
        # ------------------------- OPTIONAL gemspec attributes.
        
        attributes :email, :homepage, :github_project, :description, :license_file, :license
        attributes :build_path, :intermediates_path
        attribute :principal_class
        attribute :index_file
        attribute :info_plist
        #    attributes :autorequire, :default_executable
        #    attribute :platform,               Gem::Platform::RUBY
        
        array_attribute :authors
        attributes :sources
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
        attribute_alias_singular :nib2cib_flag, :nib2cib_flags
        attribute_alias_singular :platform, :platforms
        #    attribute_alias_singular :require_path, :require_paths
        #    attribute_alias_singular :test_file,    :test_files
        
        # ------------------------- RUNTIME attributes (not persisted).
        
        attr_writer :loaded
        attr_accessor :loaded_from
        
        # ------------------------- Special accessor behaviours (overwriting default).
    
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
        unless (self.send(symbol) or self.send(symbol) == false)
            raise Exception.new("Missing value for attribute #{symbol}")
#            raise InvalidSpecificationException.new("Missing value for attribute #{symbol}")
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
            Platform::Rhino             => ['-DPLATFORM_RHINO'],
            Platform::Browser           => ['-DPLATFORM_BROWSER', '-DPLATFORM_DOM'],
            Platform::BrowserDesktop    => ['-DPLATFORM_BROWSER', '-DPLATFORM_DOM', '-DPLATFORM_DESKTOP'],
            Platform::BrowserIPhone     => ['-DPLATFORM_BROWSER', '-DPLATFORM_DOM', '-DPLATFORM_IPHONE', '-DPLATFORM_MOBILE']
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

            copied_resources = copy_resources resources, resources_path do |resource, copied_resource, copied_resources|
                extname = File.extname(resource)

                if extname == '.xib' || extname == '.nib'
                    copied_resource = File.join(File.dirname(copied_resource), File.basename(copied_resource, extname)) + '.cib'

                    file_d copied_resource => [resource] do
                        IO.popen("nib2cib #{resource} #{copied_resource} #{nib2cib_flags.join(' ') || ''}") do |nib2cib|
                            nib2cib.sync = true

                            while str = nib2cib.gets
                                puts str
                            end
                        end
                        rake abort if ($? != 0)
                    end

                    { 'copy' => include_nibs, 'copied_resources' => [copied_resource] }
                else
                    extensionless = File.join(File.dirname(resource), File.basename(resource, extname))

                    if extname == '.cib' and (File.exists?(extensionless + '.xib') or File.exists?(extensionless + '.nib'))
                        { 'copy' => false }
                    else
                        { 'copy' => true }
                    end
                end
            end

            if type == Bundle::Type::Application and index_file

                index_file_path = File.join(build_path, File.basename(index_file))

                file_d index_file_path => [index_file] do |t|
                    cp(index_file, t.name)
                end

                enhance([index_file_path])

                frameworks_path = File.join(build_path, 'Frameworks')

                file_d frameworks_path do
                    IO.popen("capp gen -f " + build_path) do |capp|
                        capp.sync = true

                        while str = capp.gets
                            puts str
                        end
                    end
                    rake abort if ($? != 0)
                end

                enhance([frameworks_path])
            end

            info_plist_path = File.join(build_path, 'Info.plist')
            new_info_plist = { 'CPBundleName' => name, 'CPBundleIdentifier' => identifier, 'CPBundleInfoDictionaryVersion' => 6.0, 'CPBundleVersion' => version, 'CPBundlePackageType' => Bundle::Type.code_string(type) }
            
            new_info_plist['CPBundlePlatforms'] = platforms;

            if info_plist
                existing_info_plist = Plist::parse_xml(info_plist)
                new_info_plist = new_info_plist.merge existing_info_plist
                file_d info_plist_path => [info_plist]
            end

            if principal_class
                new_info_plist['CPPrincipalClass'] = principal_class
            end

            file_d info_plist_path do
                File.open(info_plist_path, 'w') do |file|
                    file.puts new_info_plist.to_plist
                end
            end

            executable_paths = []

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

            enhance(copied_resources + [info_plist_path])

			CLOBBER.include(build_path)

            enhance do
                needs_compact = false

                platforms.uniq.each do |platform|

                    platform_sources = sources
                    platform_sources = sources[platform] if sources.class == Hash

                    platform_sources = platform_sources.to_a.select { |file|
                        #if this file doesn't exist or isn't a .j file, don't preprocess it.
                        if !File.exist?(file) || File.extname(file) != '.j'
                            false
                        #if this file is newer than the generated file, preprocess it
                        else
                            preprocessed_file = File.join(build_path, PLATFORM_DIRECTORIES[platform], File.basename(file))
                            !File.exists?(preprocessed_file) || File.mtime(file) > File.mtime(preprocessed_file)
                        end
                    }

                    executable_path = File.join(build_path, PLATFORM_DIRECTORIES[platform], name + '.sj')
                    needs_compact = needs_compact || platform_sources.length > 0 || !File.exists?(executable_path)

                    preprocessed_files = platform_sources.map { |file| '-o ' + File.join(build_path, PLATFORM_DIRECTORIES[platform], File.basename(file)) }

                    # We no longer get this for free with file_d
                    FileUtils.mkdir_p File.join(build_path, PLATFORM_DIRECTORIES[platform])

                    IO.popen("objjc #{flags.join(' ')} #{PLATFORM_FLAGS[platform].join(' ')} #{platform_sources.join(' ')} #{preprocessed_files.join(' ')}") do |objjc|
                        objjc.sync = true

                        while str = objjc.gets
                            puts str
                        end
                    end
                    rake abort if ($? != 0)
                end

                BundleTask.compact(build_path) if needs_compact
            end
        end

        def BundleTask.compact(path, *patterns)
        
            puts 'Compacting ' + path
            
            info_plist_path = File.join(path, 'Info.plist')
            existing_info_plist = Plist::parse_xml(info_plist_path)
            
            absolute_path = File.expand_path(path) + '/'

            patterns = patterns.map { |pattern| "#{path}/#{pattern}" }
            
            bundle_name = existing_info_plist['CPBundleName']
            replaced_files = []

            FileList.new(File.join(path, '**', '*.platform')).each do |platform|
            
                FileList.new(File.join(platform, '*.j')) do |list|
                    
                    list.include(*patterns)
                    
                    executable_path = File.join(platform, bundle_name) + '.sj'
                    platform_absolute_path = File.expand_path(platform) + '/'
                    
                    File.open(executable_path, 'w+') do |executable|
                    
                        executable.write '@STATIC;1.0;'
                        
                        list.each do |fileName|
                        
                            fileName = File.expand_path(fileName)

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

            existing_info_plist['CPBundleReplacedFiles'] = replaced_files.uniq
            existing_info_plist['CPBundleExecutable'] = bundle_name + '.sj'
            
            File.open(info_plist_path, 'w') do |file|
                file.puts existing_info_plist.to_plist
            end
            
        end

    end  # class BundleSpecification

end # module ObjectiveJ
