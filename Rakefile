require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name        = "acts_as_list_mm"
    gem.summary     = %Q{Gem version of acts_as_list for Mongo Mapper with Rails 2 and 3 support}
    gem.description = %Q{Make your Mongo Mapper model acts as a list. This acts_as extension provides the capabilities for sorting and reordering a number of objects in a list.
      The class that has this specified needs to have a +position+ column defined as an integer on the mapped database table.}
    gem.email       = "kmandrup@gmail.com"
    gem.homepage    = "http://github.com/rails/acts_as_list"
    gem.authors     = ["Tomas Celizna", "Kristian Mandrup"]
    gem.add_dependency "mongo_mapper", ">= 0.8.2"
    # gem.add_development_dependency "yard"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/rails3/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

# require 'yard'
# YARD::Rake::YardocTask.new do |t|
#   version = File.exist?('VERSION') ? File.read('VERSION') : ""
#   t.options += ['--title', "acts_as_list #{version} Documentation"]
# end
