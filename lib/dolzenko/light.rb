require "English"
require "yaml"
require "open-uri"

# These can be autoloaded consistently (i.e. define single constant)
autoload :FileUtils, "fileutils"
autoload :OptionParser, "optparse"
autoload :OpenStruct, "ostruct"
module Net
  autoload :HTTP, "net/http"
end
autoload :StringIO, "stringio"
