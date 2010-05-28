# Django F object for Rails 3
# http://docs.djangoproject.com/en/dev/topics/db/queries/#query-expressions
#
# Let's you reference columns (and do simple calculations on them)
# from conditions and updates.
#
# User.where(:updated_at => F(:created_at))
#
#   instead of User.where("updated_at = created_at")
#
# User.where(:updated_at => F(:created_at) + 1)
#
#   instead of User.where("updated_at = created_at + 1")
#
# User.where(:updated_at => F(:created_at) + F(:updated_at))
#
#   instead of User.where("updated_at = created_at + updated_at")
#
# User.update_all(:mirror_id => F(:id))
#
#   instead of User.update_all("mirror_id = id")
#
# user = User.find(1)
# user.mirror_id = F(:id) + 1
# user.save
#
#   issues UPDATE `users` SET `mirror_id` = `users`.`id` + 1 WHERE (`users`.`id` = 1)
#
#

require "require_gist"; require_gist "383954/ea5a41269aac073b596b21fe392098827186a32b/alias_method_chain_once.rb", "a6f068593bb45fe6c9956205f672ac4a0c2e1671" # http://gist.github.com/383954

class F
  attr_accessor :attr_name
  attr_accessor :klass
  attr_accessor :operator
  attr_accessor :operand

  def initialize(attr_name)
    self.attr_name = attr_name.to_s
  end

  def to_sql(formatter = nil)
    self.klass ||= formatter.environment.relation.klass
    sql = klass.my_quote_columns(attr_name)
    if operator && operand
      operand.klass = klass if operand.is_a?(F)
      sql << " #{ operator } #{ operand.is_a?(F) ? operand.to_sql(formatter) : klass.connection.quote(operand) }"
    end
    sql
  end

  def empty?
    false
  end

  %w(+ - * /).each do |op|
    define_method(op) do |arg|
      self.operator = op
      self.operand = arg
      self
    end
  end
end

def F(attr_name)
  F.new(attr_name)
end

if $PROGRAM_NAME == __FILE__
  require File.expand_path('../../config/environment', __FILE__)
end

module ActiveRecord
  class Base
    def self.my_quote_columns(*column_names)
      quoted_table_name = connection.quote_table_name(table_name)
      column_names.map { |column_name| "#{ quoted_table_name }.#{ connection.quote_column_name(column_name) }" }.join(", ")
    end
  end
end

module ActiveRecord
  module ConnectionAdapters #:nodoc:
    class Column
      def type_cast_with_f_object(value)
        return value if value.is_a?(F)
        type_cast_without_f_object(value)
      end
      
      alias_method_chain_once :type_cast, :f_object
    end
  end
  

  class Relation
    def build_where_with_f_object(*args)
      if args.size == 1 && args[0].is_a?(Hash)
        hash_conditions = args[0]
        hash_conditions.each { |_, v| v.klass = klass if v.is_a?(F) }
      end

      build_where_without_f_object(*args)
    end

    alias_method_chain_once :build_where, :f_object
  end

  class Base
    class << self
      def sanitize_sql_hash_for_assignment_with_f_object(assignments)
        f_assignments, normal_assignments = assignments.partition { |_, v| v.is_a?(F) }
        
        f_sql = f_assignments.map do |attr, f_obj|
          "#{connection.quote_column_name(attr)} = #{connection.quote_column_name(f_obj.attr_name)}"
        end.join(", ")

        normal_sql = sanitize_sql_hash_for_assignment_without_f_object(normal_assignments)
        
        [(f_sql if f_sql.present?), (normal_sql if normal_sql.present?)].compact.join(", ")
      end

      alias_method_chain_once :sanitize_sql_hash_for_assignment, :f_object
    end
  end

  module AttributeMethods
    module Write
      def write_attribute_with_f_object(attr_name, value)
        write_attribute_without_f_object(attr_name, value)

        # cancel number and any other type of conversions
        if value.is_a?(F)
          value.klass = self.class
          @attributes[attr_name] = value
        end
      end

      alias_method_chain_once :write_attribute, :f_object
    end
    
    module TimeZoneConversion
      module ClassMethods
        def define_method_attribute_with_f_object=(attr_name)
          send(:define_method_attribute_without_f_object=, attr_name)

          method_body, line = <<-EOV, __LINE__ + 1
            def #{attr_name}_with_f_object=(time)
              if time.is_a?(F)
                time.klass = self.class
                write_attribute(:#{attr_name}, time)
              else
                send(:#{attr_name}_without_f_object=, time)
              end
            end

            alias_method_chain_once :#{attr_name}=, :f_object unless respond_to?(:#{attr_name}_without_f_object=)
          EOV
          generated_attribute_methods.module_eval(method_body, __FILE__, line)
        end
        
        alias_method_chain_once :define_method_attribute=, :f_object
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  class User < ActiveRecord::Base
  end

  require 'rspec/core'
  require 'rspec/expectations'
  require 'rspec/matchers'

  Rspec.configure do |c|
    c.mock_with :rspec
  end

  describe F do
    Rspec::Matchers.define :end_with do |expected|
      match do |actual|
        actual.end_with?(expected) 
      end
    end

    specify { User.where(:updated_at => F(:created_at)).to_sql.should
    end_with("(`users`.`updated_at` = `users`.`created_at`)") }
    
    specify { User.where(:updated_at => F(:created_at) + 1).to_sql.should
    end_with("(`users`.`updated_at` = `users`.`created_at` + 1)") }

    specify { User.where(:updated_at => F(:created_at) + F(:updated_at)).to_sql.should
    end_with("(`users`.`updated_at` = `users`.`created_at` + `users`.`updated_at`)") }

    specify { User.where(:updated_at => F(:created_at) + F(:updated_at)).to_sql.should
    end_with("(`users`.`updated_at` = `users`.`created_at` + `users`.`updated_at`)") }

    def update_sql(f_obj)
      id_attr = User.scoped.arel_table.find_attribute_matching_name("id")
      Arel::Update.new(User.scoped, id_attr => f_obj).to_sql.strip
    end

    specify { update_sql(F(:di)).should
    end_with("SET `id` = `users`.`di`") }

    specify { update_sql(F(:di) + 1).should
    end_with("SET `id` = `users`.`di` + 1") }
    
    specify { update_sql(F(:di) + F(:id)).should
    end_with("SET `id` = `users`.`di` + `users`.`id`") }
  end
end
