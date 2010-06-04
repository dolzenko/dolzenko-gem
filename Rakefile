task :release do
  sh "git add -i"
  sh "git commit"
  sh "ruby push_and_release.rb"
  sh "github browse"
end

task :default => :release