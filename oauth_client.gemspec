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

  s.rubyforge_project = "oauth_client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "mocha"
  s.add_development_dependency "typhoeus"
end
