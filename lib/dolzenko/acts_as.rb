class Class
  def acts_as(*args)
    modules_with_options = []
    for arg in args
      if arg.is_a?(Module)
        modules_with_options << [arg]
      elsif arg.is_a?(Hash)
        raise ArgumentError, "Options without module" unless modules_with_options[-1][0].is_a?(Module)
        modules_with_options[-1][1] = arg
      end
    end
    
    klass = self
    for mod, options in modules_with_options
      klass.send(:instance_exec, options, &mod::ClassContextProc) if defined?(mod::ClassContextProc)
      klass.send(:include, mod::InstanceMethods) if defined?(mod::InstanceMethods)
      klass.extend(mod::ClassMethods) if defined?(mod::ClassMethods)
    end  
  end
end

module NeverTooDry
  ClassContextProc = proc do |options|
    attr_accessor :some_attr
    
    class_eval <<-RUBY
      def #{options[:meta_method_name]}; end
    RUBY
  end
  
  module InstanceMethods
    def instance_method; end
  end
  
  module ClassMethods
    def class_method; end
  end
end

module Dummy; end

class C
  acts_as NeverTooDry, { :meta_method_name => "meta_method" }, 
          Dummy
end


C.class_method

c = C.new
c.some_attr = 123
c.meta_method
c.instance_method