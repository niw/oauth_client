require "rubygems"
require "bundler/setup"

$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require "test/unit"

# As of Mocha version 0.9.8, you need to explicitly load Mocha after the test framework.
# e.g. by adding "require 'mocha'" at the bottom of test/test_helper.rb.
# See http://github.com/floehopper/mocha/blob/master/README.rdoc
require "mocha"
