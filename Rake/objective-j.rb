require 'rake'
require 'date'

module ObjectiveJ

    class Platform
        OBJJ    = 'objj'
        RHINO   = 'rhino'
        BROWSER = 'browser'
    end

    ##
    # == ObjectiveJ::BundleSpecification
    #
    # The Specification class contains the metadata for a Framework.  Typically defined in a
    # Rakefile, and looks like this:
    #
    #   spec = ObjJ::BundleSpecification.new do |s|
    #     s.name = 'NewKit'
    #     s.version = '1.0'
    #     s.summary = 'Example framework specification'
    #     ...
    #   end
    #
    # There are many <em>framework attributes</em>, and the best place to learn about them in
    # the "Framework Reference" linked from the Cappuccino wiki.
    #

    class BundleSpecification

        # ------------------------- Specification version contstants.

        # The specification version applied to any new Specification instances created.  This
        # should be bumped whenever something in the spec format changes.
        CURRENT_SPECIFICATION_VERSION = 1
        
        # An informal list of changes to the specification.  The highest-valued key should be
        # equal to the CURRENT_SPECIFICATION_VERSION.
        SPECIFICATION_VERSION_HISTORY = {
          -1 => ['(RubyGems versions up to and including 0.7 did not have versioned specifications)'],
          1  => [
            'First Specification'
          ]
        }
        
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
        
        required_attribute :specification_version, CURRENT_SPECIFICATION_VERSION
        required_attribute :name
        required_attribute :version
        #required_attribute :date
        attribute :date
        required_attribute :summary
        required_attribute :identifier
        
        read_only :specification_version
        
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
=begin
        overwrite_accessor :test_files do
          # Handle the possibility that we have @test_suite_file but not @test_files.  This will
          # happen when an old gem is loaded via YAML.
          if @test_suite_file
            @test_files = [@test_suite_file].flatten
            @test_suite_file = nil
          end
          @test_files ||= []
        end
=end

        # ------------------------- Predicates.
    
        def loaded?; @loaded ? true : false ; end
    #    def has_unit_tests?; not test_files.empty?; end

        # ------------------------- Constructors.
        
        ##
        # Specification constructor.  Assigns the default values to the
        # attributes, adds this spec to the list of loaded specs (see
        # Specification.list), and yields itself for further initialization.
        #
        def initialize
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
        end
=begin
    ##
    # Special loader for YAML files.  When a Specification object is loaded from a YAML file,
    # it bypasses the normal Ruby object initialization routine (#initialize).  This method
    # makes up for that and deals with gems of different ages.
    #
    # 'input' can be anything that YAML.load() accepts: String or IO.
    #
    def Specification.from_yaml(input)
      spec = YAML.load(input)
      if(spec.class == FalseClass) then
        raise Gem::EndOfYAMLException
      end
      unless Specification === spec
        raise Gem::Exception, "YAML data doesn't evaluate to gem specification"
      end
      unless spec.instance_variable_get :@specification_version
        spec.instance_variable_set :@specification_version, NONEXISTENT_SPECIFICATION_VERSION
      end
      spec
    end
=end

        def BundleSpecification.load(filename)
          gemspec = nil
          fail "NESTED Specification.load calls not allowed!" if @@gather
          @@gather = proc { |gs| gemspec = gs }
          data = File.read(filename)
          eval(data)
          gemspec
        ensure
          @@gather = nil
        end

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
=begin
    # ------------------------- Export methods (YAML and Ruby code).

    # Returns an array of attribute names to be used when generating a YAML
    # representation of this object.  If an attribute still has its default
    # value, it is omitted.
    def to_yaml_properties
      mark_version
      @@attributes.map { |name, default| "@#{name}" }
    end

    # Returns a Ruby code representation of this specification, such that it
    # can be eval'ed and reconstruct the same specification later.  Attributes
    # that still have their default values are omitted.
    def to_ruby
      mark_version
      result = "Gem::Specification.new do |s|\n"
      @@attributes.each do |name, default|
        # TODO better implementation of next line (read_only_attribute? ... something like that)
        next if name == :dependencies or name == :specification_version
        current_value = self.send(name)
        result << "  s.#{name} = #{ruby_code(current_value)}\n" unless current_value == default
      end
      dependencies.each do |dep|
        version_reqs_param = dep.requirements_list.inspect
        result << "  s.add_dependency(%q<#{dep.name}>, #{version_reqs_param})\n"
      end
      result << "end\n"
    end
=end
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

    def to_s
        "#<Framework::Specification name=#{@name} version=#{@version}>"
    end
    
        def info_plist
            return { 'CPBundleName' => name, 'CPBundleIdentifier' => identifier, 'CPBundleInfoDictionaryVersion' => 6.0, 'CPBundleVersion' => version }
        end

    private
=begin
    def find_all_satisfiers(dep)
      Gem.source_index.each do |name,gem|
        if(gem.satisfies_requirement?(dep)) then
          yield gem
        end
      end
    end
=end
    # Duplicate an object unless it's an immediate value.
    def copy_of(obj)
      case obj
      when Numeric, Symbol, true, false, nil then obj
      else obj.dup
      end
    end

    # Return a string containing a Ruby code representation of the given object.
    def ruby_code(obj)
      case obj
      when String           then '%q{' + obj + '}'
      when Array            then obj.inspect
      when Gem::Version     then obj.to_s.inspect
      when Date, Time       then '%q{' + obj.strftime('%Y-%m-%d') + '}'
      when Numeric          then obj.inspect
      when true, false, nil then obj.inspect
      when Gem::Version::Requirement  then "Gem::Version::Requirement.new(#{obj.to_s.inspect})"
      else raise Exception, "ruby_code case not handled: #{obj.class}"
      end
    end

  end  # class BundleSpecification

end  # module ObjectiveJ

module ObjectiveJ
    
    module License
        LGPL_v2_1    = 'LGPL_v2_1'
    end
    
end

def file_d(*args, &block)

    fileTask = file_create(*args, &block)
    
    fileDirectory = File.dirname(fileTask.name)
    directory fileDirectory
    
    file fileTask.name => fileDirectory

end

def bundle(spec, *args, &block)
    task = ObjectiveJ::BundleTask.define_task(*args, &block)
    task.bundle_spec = spec
end
