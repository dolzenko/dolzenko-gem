require "active_support/all"
require "active_record"
require "cgi"

# http://dolzhenko.org/blog/2010/07/safe-string-interpolation-in-ruby/
module SafeInterpolate
  def generic_interpolate(string_block, interpolator)
    raise ArgumentError, "block returning string to interpolate must be provided" unless string_block 
    string_with_interpolations = string_block.call
    string_with_interpolations.gsub(/\#\{([^}]*)\}/) do
      result = eval($1, string_block.binding)
      interpolator[result]
    end
  end

  # Examples
  #
  #     include SafeInterpolate
  #     ...
  #     sql_interpolate { 'name = #{ name }' } # => "name = 'Bob'"
  def sql_interpolate(&string_block)
    generic_interpolate(string_block, ActiveRecord::Base.connection.method(:quote))
  end

  def html_interpolate(&string_block)
    generic_interpolate(string_block, ERB::Util.method(:html_escape))
  end

  def uri_interpolate(&string_block)
    generic_interpolate(string_block, CGI.method(:escape))
  end
end

if $PROGRAM_NAME == __FILE__
  require 'rspec/core'
  require 'rspec/expectations'
  require 'rspec/matchers'

  describe "SafeInterpolate#sql_interpolate" do
    include SafeInterpolate

    tmp_db_file = '/tmp/test.sqlite'

    before(:all) do
      ActiveRecord::Base.configurations = { 'test' => { :adapter => 'sqlite3', :database => tmp_db_file, :timeout => 5000 } }
      ActiveRecord::Base.establish_connection('test')
    end

    after(:all) do
      ActiveRecord::Base.remove_connection
      File.delete(tmp_db_file) rescue nil
    end

    it "returns string passed in block" do
      sql_interpolate { '42' }.should == "42"
    end

    it "interpolates expressions" do
      num = 1
      str = '123'
      sql_interpolate { 'before #{ num } #{ str } after' }.should == 'before 1 \'123\' after'
    end

    it "properly quotes SQL sensitive characters" do
      str = "'asd'; DROP TABLE users"
      sql_interpolate { '#{ str }' }.should == "'''asd''; DROP TABLE users'"
    end
  end

  describe "SafeInterpolate#html_interpolate" do
    include SafeInterpolate

    it "properly quotes HTML sensitive characters" do
      str = '&"><'
      html_interpolate { '<p>#{ str }</p>' }.should == "<p>&amp;&quot;&gt;&lt;</p>"
    end
  end

  describe "SafeInterpolate#uri_interpolate" do
    include SafeInterpolate

    it "properly quotes URI sensitive characters" do
      str = ':&? ='
      uri_interpolate { 'http://example.com?q=#{ str }' }.should == "http://example.com?q=%3A%26%3F+%3D"
    end
  end
end