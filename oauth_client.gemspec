# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "oauth_client/version"

Gem::Specification.new do |s|
  s.name        = "oauth_client"
  s.version     = OauthClient::VERSION
  s.authors     = ["Yoshimasa Niwa"]
  s.email       = ["niw@niw.at"]
  s.homepage    = "http://niw.at"
  s.summary     =
  s.description = "A small OAuth client library."

  s.test_files       = `git ls-files -- test/*`.split("\n")
  s.extra_rdoc_files = `git ls-files -- README*`.split("\n")
  s.files            = `git ls-files -- {bin,lib}/*`.split("\n") +
                       s.test_files +
                       s.extra_rdoc_files
  s.executables      = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "mocha"
  s.add_development_dependency "typhoeus"
end
