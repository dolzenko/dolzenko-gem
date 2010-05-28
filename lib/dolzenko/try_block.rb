module TryBlock
  def self.install!
    unless Object.include?(self)
      Object.send(:include, self)
      Object.send(:public, :try_block)
    end
  end

  def try_block(&block)
    raise ArgumentError, "should be given block" unless block

    return if self.nil?

    caller_size = caller.size
    
    # JRuby reports this weird ":1" line in caller
    if RUBY_PLATFORM =~ /\bjava\b/ && caller[-1] == ":1"
      caller_size -= 1
    end
    
    begin
      self.instance_eval(&block)
    rescue NoMethodError => e
      if e.backtrace.size - caller_size == 3 &&
              e.message =~ /^undefined method.+for nil:NilClass$/

        return nil
      end
      raise
    end
  end
end

def TryBlock(&block)
  raise ArgumentError, "should be given block" unless block

  return if self.nil?

  caller_size = caller.size

  # JRuby reports this weird ":1" line in caller
  if RUBY_PLATFORM =~ /\bjava\b/ && caller[-1] == ":1"
    caller_size -= 1
  end

  begin
    yield
  rescue NoMethodError => e
    if e.backtrace.size - caller_size == 2 &&
            e.message =~ /^undefined method.+for nil:NilClass$/
      return nil
    end
    raise
  end
end

if $PROGRAM_NAME == __FILE__
  require "test/unit"

  class TestBlockTry < Test::Unit::TestCase
    def setup
      TryBlock.install!
    end
    
    def test_properly_eats_exception_on_nil_object_from_call_site
      some_nil = nil

      assert_nil TryBlock { some_nil.something_else }

      assert_nil "qwerty".try_block { some_nil.something_else }

      assert_nil some_nil.try_block { something_else }

      assert_nil [false].try_block { detect { |e| e }.something }
    end

    def test_name_error_in_block
      assert_raises NameError do
        TryBlock { no_such_name }
      end

      assert_raises NameError do
        "qwerty".try_block { no_such_name }
      end
    end

    def test_doesnt_eat_general_exception
      assert_raises RuntimeError do
        TryBlock { raise "FAIL" }
      end
      
      assert_raises RuntimeError do
        "qwerty".try_block { raise "FAIL" }
      end
    end

    def test_doesnt_eat_general_exception_originated_from_somewhere_else
      proc_raiser = proc { raise "FAIL" }
      obj_raiser = "qwerty".tap { |obj| def obj.raiser; raise "FAIL" end }

      assert_raises RuntimeError do
        TryBlock { proc_raiser[] }
      end

      assert_raises RuntimeError do
        obj_raiser.try_block { raiser }
      end

      assert_raises RuntimeError do
        [1].try_block { detect { |e| raise "FAIL" } }
      end
    end

    def test_doesnt_eat_nil_object_exception_originated_from_somewhere_else
      some_nil = nil
      no_method_raiser = proc { some_nil.doesnt_exist_on_nil }
      obj_no_method_raiser = "qwerty".tap { |obj| def obj.raiser; doesnt_exist_on_string() end }

      if RUBY_VERSION < '1.9'
          # ["try_block.rb:97",
          # "try_block.rb:118:in `[]'",
          # "try_block.rb:118:in `test_doesnt_eat_nil_object_exception_originated_from_somewhere_else'",
          # "try_block.rb:37:in `BlockTry'",
          # "try_block.rb:118:in `test_doesnt_eat_nil_object_exception_originated_from_somewhere_else'", <= call site
        assert_raises(NoMethodError) do
          TryBlock do
            no_method_raiser[]
          end
        end
      else
        # ["try_block.rb:97:in `block in test_doesnt_eat_nil_object_exception_originated_from_somewhere_else'",
        # "try_block.rb:112:in `[]'",
        # "try_block.rb:112:in `block (2 levels) in test_doesnt_eat_nil_object_exception_originated_from_somewhere_else'",
        # "try_block.rb:37:in `BlockTry'",
        # "try_block.rb:112:in `block in test_doesnt_eat_nil_object_exception_originated_from_somewhere_else'", <= call site
        # ...
        assert_raises(NoMethodError) { TryBlock { no_method_raiser[] } } # this will only work in 1.9
      end


      assert_raises NoMethodError do
        obj_no_method_raiser.try_block { raiser }
      end
    end

    def test_hash_digging
      h = { :asd => 123, :rty => 456}
      assert_nil TryBlock { h[:qwe][:asd][:zxc] }
      assert_equal 123, TryBlock { h[:asd] }
      
      assert_nil h.try_block { self[:qwe][:asd][:zxc] }
      assert_nil h.try_block { |ha| ha[:qwe][:asd][:zxc] }
      assert_equal 456, h.try_block { |ha| ha[:rty] }
    end

    def test_asserts_passed_block
      assert_raises ArgumentError do
        TryBlock.try_block
      end

      assert_raises ArgumentError do
        "qwerty".try_block
      end
    end

    def test_core_ext
      assert_nil nil.try_block { 42 }
      assert_equal 6, "qwerty".try_block { length }
    end

    def test_meta_method
      obj_raiser = Class.new.tap { |c| c.module_eval("def raiser; raise 'FAIL' end ") }

      assert_raises(RuntimeError) { TryBlock { obj_raiser.new.raiser } }
      assert_raises(RuntimeError) { obj_raiser.new.try_block { raiser } }
    end

    def test_eval
      assert_raises(NoMethodError) { eval("TryBlock { 'qwerty'.doesnt_exist_on_string }") }
      assert_nil(eval("TryBlock { nil.doesnt_exist_on_nil }")) unless RUBY_PLATFORM =~ /\bjava\b/ 

      assert_raises(NoMethodError) { eval("'qwerty'.try_block { doesnt_exist_on_string() }") }
      assert_nil(eval("'qwerty'.try_block { nil.doesnt_exist_on_nil }")) unless RUBY_PLATFORM =~ /\bjava\b/

      assert_equal 6, eval("'qwerty'.try_block { length }")
      assert_nil(eval("[false].try_block { detect { |e| e }.doesnt_exist_on_nil.also_doesnt_exist_on_nil }")) unless RUBY_PLATFORM =~ /\bjava\b/
    end
  end
end