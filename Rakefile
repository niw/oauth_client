require "rubygems"
require "bundler/setup"

require "rake"
require "rake/testtask"

task :default => [:test]

Rake::TestTask.new(:test) do |t| 
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end 
Rake::Task["test"].comment = "Run all tests in test directory"
