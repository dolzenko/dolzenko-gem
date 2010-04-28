## Comfort

### Definition

    require "English"
    require "yaml"
    require "open-uri"
    autoload :FileUtils, "fileutils"
    autoload :OptionParser, "optparse"
    module Net
      autoload :HTTP, "net/http"
    end
    require "active_support/all"
    require "facets"
    require "require_gist"
    require_gist "371861/abc6d24346864e5cb33b4eab330569565b1dd8c2/shell_out.rb", "72b19c8955f87f9b408a92a77440cda987b1a01f" # http://gist.github.com/371861
    require_gist "375386/642be35e02a09b7dc5736f462ea1d8368864ffa8/error_print.rb", "12f893f4abd1f0ea19d198f6ff1ac66d8b8675ea" # http://gist.github.com/375386

### Price

    > time ruby -v -W2 -e 'require "dolzenko"'

    ruby 1.8.7 (2009-12-24 patchlevel 248) [i686-linux], MBARI 0x8770, Ruby Enterprise Edition 2010.01

    real 0.89 user 0.40 sys 0.48

    ruby 1.8.7 (2010-01-10 patchlevel 249) [i686-linux]

    real 0.78 user 0.40 sys 0.36

    ruby 1.8.7 (2008-08-11 patchlevel 72) [i386-mswin32]

    real 3.75 user 0.00 sys 0.01

    ruby 1.9.2dev (2010-04-02 trunk 27162) [i686-linux]

    real 7.17 user 6.32 sys 0.72 
    # WTF??? http://redmine.ruby-lang.org/issues/show/3010 ?
