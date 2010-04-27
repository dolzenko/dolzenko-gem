lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
Gem::Specification.new do |s|
  s.name        = "dolzenko"
  s.version     = ENV["GEM_VERSION"]
  s.authors     = ["Evgeniy Dolzhenko"]
  s.email       = ["dolzenko@gmail.com"]
  s.homepage    = "http://github.com/dolzenko/dolzenko-gem"
  s.summary     = "Tiny meta gem which makes dolzenko happy"
  s.files       = Dir.glob("lib/**/*") + %w(dolzenko.gemspec)
  s.add_dependency("facets", "2.8.3")
  s.add_dependency("activesupport", "3.0.0.beta3")
end