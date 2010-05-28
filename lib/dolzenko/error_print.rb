# Formats the Exception so that it looks *familiar*,
# i.e. exactly like your interpreter does it.
#
# Port of MRI native `error_print` function.
class Exception
  require "English"
  
  def error_print
    self.class.error_print(self)
  end
  
  def self.error_print(e = $ERROR_INFO)
    warn_print = ""
    backtrace = e.backtrace
    backtrace = [ backtrace ] if backtrace.is_a?(String) # 1.9 returns single String for SystemStackError

    warn_print << backtrace[0]
    if e.is_a?(RuntimeError) && e.message.empty?
      warn_print << ": unhandled exception\n"
    else
      if e.message.empty?
        warn_print << ": #{ e.class.name }\n"
      else
        split_message = e.message.split("\n")
        warn_print << ": "
        if split_message.size == 1
          warn_print << "#{ e.message } (#{ e.class.name })\n"
        else
          warn_print << split_message[0]
          warn_print << " (#{ e.class.name })\n"
          warn_print << split_message[1..-1].join("\n").chomp << "\n"
        end
      end
    end

    len = backtrace.size

# int skip = eclass == rb_eSysStackError;
    skip = e.is_a?(SystemStackError)

# #define TRACE_MAX (TRACE_HEAD+TRACE_TAIL+5)
# #define TRACE_HEAD 8
# #define TRACE_TAIL 5
    trace_head = 8
    trace_tail = 5
    trace_max = (trace_head + trace_tail + 5)
#
#	for (i = 1; i < len; i++) {
    i = 1
    while i < len
#	    if (TYPE(ptr[i]) == T_STRING) {
#		warn_printf("\tfrom %s\n", RSTRING_PTR(ptr[i]));
#	    }
      warn_print << "\tfrom %s\n" % e.backtrace[i]

#	    if (skip && i == TRACE_HEAD && len > TRACE_MAX) {
      if skip && i == trace_head && len > trace_max
#		warn_printf("\t ... %ld levels...\n",
#			    len - TRACE_HEAD - TRACE_TAIL);
        warn_print << "\t ... %d levels...\n" % (len - trace_head - trace_tail)
#		i = len - TRACE_TAIL;
        i = len - trace_tail
#	    }
      end
#	}
      i += 1
    end
    warn_print
  end
end


if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    # Main test suite runner
    require "spec"
    require "require_gist"; require_gist "371861/7dbcff4b266451b70cca183ce24917340587e8d3/shell_out.rb", "1e8bbc0ef3d1d078a4e57eb03225913c3a1e4fe5" # http://gist.github.com/371861

    describe "Exception.error_print" do
      include ShellOut
      %w(normal
          multiline
          empty_message
          non_empty_message
          runtime_empty
          runtime_non_empty
          sys_stack).each do |type|
        it "outputs the same message as the native interpreter does for #{ type } exception" do
          native = shell_out("ruby #{ __FILE__ } native raise_#{ type }", :out => :return)

          native.should include(__FILE__)

          error_printed = shell_out("ruby #{ __FILE__ } error_print raise_#{ type }", :out => :return)

          error_printed.should include(__FILE__)

          error_printed.should == native
        end
      end

    end
    exit ::Spec::Runner::CommandLine.run
  else
    # Helper
    def raise_normal
      f10
    end

    def raise_multiline
      raise "qwe\nasd\nzxc"
    end

    def raise_empty_message
      raise ArgumentError, ""
    end

    def raise_non_empty_message
      raise ArgumentError, "qwe"
    end

    def raise_runtime_empty
      raise
    end

    def raise_runtime_non_empty
      raise RuntimeError, "runtime non empty"
    end

    def raise_sys_stack
      baz
    end

    # puts (0..20).map { |i| "def f#{i}() f#{i+1}(); end"}.join("\n")
    def f0() f1(); end
    def f1() f2(); end
    def f2() f3(); end
    def f3() f4(); end
    def f4() f5(); end
    def f5() f6(); end
    def f6() f7(); end
    def f7() f8(); end
    def f8() f9(); end
    def f9() f10(); end
    def f10() f11(); end
    def f11() f12(); end
    def f12() f13(); end
    def f13() f14(); end
    def f14() f15(); end
    def f15() f16(); end
    def f16() f17(); end
    def f17() f18(); end
    def f18() f19(); end
    def f19() f20(); end
    def f20
      raise(ArgumentError, "multi\nline\nerror")
    end


    def foo; bar; end; def bar; foo; end; def baz; foo; end;

    class NonExistingException < Exception
    end

    begin
      eval ARGV[1]
      # we need to keep the same backtraces to make comparison adequate
      # since NonExistingException will never be raised - the exception
      # will propagate to the top level and interpreter will do it's job
    rescue (ARGV[0] == "native" ? NonExistingException : Exception) => e
      puts Exception.error_print
    end
  end
end