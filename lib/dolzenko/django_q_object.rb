# Django Q object for Rails 2, 3
#
# http://dolzhenko.org/blog/2010/07/django-f-and-q-objects-for-rails/
#
# http://docs.djangoproject.com/en/dev/topics/db/queries/#complex-lookups-with-q-objects
#
# Let's you build ORed, ANDed, and negated conditions without dropping to
# writing SQL.
#
# User.where(~Q(:user_id => nil))
#
#   instead of User.where("user_id IS NOT NULL")
#
# User.where(Q(:user_id => nil) | Q(:id => nil))
#
#   instead of User.where("user_id IS NULL OR id IS NULL")
#
# User.where(~(Q(:user_id => nil) & Q(:id => nil)))
#
#   instead of User.where("user_id IS NOT NULL AND id IS NOT NULL")
#
# On Ruby 1.9 Object#! can be used to negate conditions
#
# User.where(!Q(:user_id => nil))
#

require "dolzenko/alias_method_chain_once"

class Q
  def |(other)
    OrQ.new(self, other)
  end

  def &(other)
    AndQ.new(self, other)
  end

  def ~
    NotQ.new(self)
  end

  alias_method "!", "~"
end

class BinaryQ < Q
  attr_accessor :op1, :op2

  def initialize(op1, op2)
    self.op1, self.op2 = op1, op2
  end

  def empty?
    false
  end
end

class UnaryQ < Q
  attr_accessor :op1

  def initialize(*args)
    self.op1 = (args.size == 1 ? args[0] : args)
  end

  def to_q_sql(klass)
    klass.send(:sanitize_sql, op1)
  end

  def empty?
    op1.empty?
  end
end

class AndQ < BinaryQ
  def to_q_sql(klass)
    "(#{ op1.to_q_sql(klass) }) AND (#{ op2.to_q_sql(klass) })"
  end
end

class NotQ < UnaryQ
  def to_q_sql(klass)
    "(NOT (#{ op1.to_q_sql(klass) }))"
  end
end

class OrQ < BinaryQ
  def to_q_sql(klass)
    "(#{ op1.to_q_sql(klass) }) OR (#{ op2.to_q_sql(klass) })"
  end
end

def Q(*args)
  UnaryQ.new(*args)
end

if $PROGRAM_NAME == __FILE__
  require File.expand_path('../../config/environment', __FILE__)
end

module ActiveRecord
  if defined?(Relation)
    # Rails 3
    class Relation
      def build_where_with_q_object(*args)
        if args.size == 1 && args[0].is_a?(Q)
          return args[0].to_q_sql(klass)
        end

        build_where_without_q_object(*args)
      end

      alias_method_chain_once :build_where, :q_object
    end
  else
    # Rails 2
    class Base
      class << self
        def sanitize_sql_for_conditions_with_q_object(*args)
          if args.size == 1 && args[0].is_a?(Q)
            return args[0].to_q_sql(klass)
          end

          sanitize_sql_for_conditions_without_q_object(*args)
        end

        alias_method_chain_once :sanitize_sql_for_conditions, :q_object
      end
    end
  end
end

module ActiveRecord
  class Base
    def self.Q(*args)
      UnaryQ.new(*args).to_q_sql(self)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  class User < ActiveRecord::Base
  end

  require 'rspec/expectations'
  require 'rspec/core'

  Rspec.configure do |c|
    c.mock_with :rspec
  end

  describe Q do
    Rspec::Matchers.define :be_like_conditions do |expected|
      match do |actual|
        actual.to_q_sql(User) == expected
      end
    end

    it { Q(:email => nil).should
    be_like_conditions("`users`.`email` IS NULL") }

    it { (~Q(:user_id => nil)).should
    be_like_conditions("(NOT (`users`.`user_id` IS NULL))") }

    it { (!Q(:user_id => nil)).should
    be_like_conditions("(NOT (`users`.`user_id` IS NULL))") }

    it { (User.Q(:is_avatar => nil)).should == "`users`.`is_avatar` IS NULL" }

    it { (User.Q("name LIKE :like OR email LIKE :like", :like => "%#{ 42 }%")).should == "name LIKE '%42%' OR email LIKE '%42%'" }

    it { (Q(:league_id => nil) & Q("path LIKE ?", "prefix/%")).should
    be_like_conditions("(`users`.`league_id` IS NULL) AND (path LIKE 'prefix/%')") }

    it { (Q(:to_account_id => 2) | Q(:from_account_id => 1)).should
    be_like_conditions("(`users`.`to_account_id` = 2) OR (`users`.`from_account_id` = 1)") }

    it { (!Q(:user_id => nil) & Q(:email => nil)).should
    be_like_conditions("((NOT (`users`.`user_id` IS NULL)) AND (`users`.`email` IS NULL)") }
  end
end
