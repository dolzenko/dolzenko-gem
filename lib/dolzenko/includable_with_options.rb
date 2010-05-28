# Check Thomas Sawyer take on the problem http://github.com/rubyworks/paramix
module IncludableWithOptions
  class << self
    attr_accessor :last_default_options
  end

  def self.included(includable_with_options)
    %w(string/methodize kernel/constant module/basename module/spacename).each { |facets_core_ext| require "facets/#{ facets_core_ext }" }

    raise "IncludableWithOptions should be included by the Module" unless includable_with_options.instance_of?(Module)

    options_class_var_name = "@@#{ includable_with_options.basename.methodize }_options"

    unless IncludableWithOptions.last_default_options.nil?
      includable_with_options.send(:class_variable_set, options_class_var_name, IncludableWithOptions.last_default_options)
      IncludableWithOptions.last_default_options = nil
    end

    context = Kernel.constant(includable_with_options.spacename)

    option_setting_duplicator = <<-CODE
      def #{ context != Kernel ? "self." : "" }#{ includable_with_options.basename }(options = nil)
        m = Kernel.constant("#{ includable_with_options.name }").dup
        m.send(:class_variable_set, "#{ options_class_var_name }", options)
        m
      end    
    CODE

    context.module_eval(option_setting_duplicator)
  end
end

def IncludableWithOptions(options = {})
  m = Kernel.const_get(:IncludableWithOptions).dup
  # Because of Ruby bug (?) model function +included+ won't be able to access @@default_options:
  # http://redmine.ruby-lang.org/issues/show/3080
  # m.send(:class_variable_set, :@@default_options, options[:default])
  IncludableWithOptions.last_default_options = options[:default] 
  m
end

if $PROGRAM_NAME == __FILE__

  module MyStuff
    module SystemWithTweaks
      include IncludableWithOptions(:default => {})

      def system(*args)
        puts "@@system_with_tweaks_options #{ @@system_with_tweaks_options }"
        puts "Executing command: #{ args.join(" ") }" if @@system_with_tweaks_options[:echo]
        result = Kernel.system(*args)
        raise "Command #{ args.join(" ") } exited with a nonzero exit status" if @@system_with_tweaks_options[:raise_exceptions]
        result
      end
    end
  end

  module MyStuff
    class D
      include MyStuff::SystemWithTweaks(:asd => 123)

      def m
        system "echo 'just echoing'"
      end
    end
  end


  module SystemWithTweaks
    include IncludableWithOptions(:default => { :echo => true })

    def system(*args)
      puts "Executing command: #{ args.join(" ") }" if @@system_with_tweaks_options[:echo]
      result = Kernel.system(*args)
      raise "Command #{ args.join(" ") } exited with a nonzero exit status" if @@system_with_tweaks_options[:raise_exceptions]
      result
    end
  end

  class C
    include SystemWithTweaks(:echo => true)

    def m
      system "ls"
    end
  end

  module MyStuff 
    class B
      include MyStuff::SystemWithTweaks(:raise_exceptions => true)

      def m
        system "does_not_exist"
      end
    end
  end

  puts "Top level include with options"
  C.new.m

  puts "Namespaced include without options"
  MyStuff::D.new.m

  puts "Namespaced include with options"
  MyStuff::B.new.m
end