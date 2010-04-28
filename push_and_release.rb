require "yaml"

GEM_NAME = "dolzenko"

current_version = YAML.load(`gem specification #{ GEM_NAME } -r`)["version"] || Gem::Version.new("0.0.0")
new_version = (current_version.segments[0..-2] + [current_version.segments[-1].succ]).join(".")
ENV["GEM_VERSION"] = new_version

puts "Releasing #{ GEM_NAME } #{ new_version }"

system "gem build #{ GEM_NAME }.gemspec --verbose"

system "gem push #{ GEM_NAME }-#{ new_version }.gem --verbose"

File.delete("#{ GEM_NAME }-#{ new_version }.gem")

system "git push"

system "gem install #{ GEM_NAME } --version=#{ new_version } --remote --update-sources --verbose"