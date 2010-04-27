require "yaml"

GEM_NAME = "dolzenko"

current_version = YAML.load(`gem specification #{ GEM_NAME } -r`)["version"] rescue Gem::Version.new("0.0.0")
new_version = (current_version.segments[0..-2] + [current_version.segments[-1].succ]).join(".")
ENV["GEM_VERSION"] = new_version

puts "Releasing #{ GEM_NAME } #{ new_version }"

system "gem build dolzenko.gemspec"

system "gem push dolzenko-#{ new_version }"

system "git push"