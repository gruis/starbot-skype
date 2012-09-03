require File.expand_path("../lib/starbot/skype", __FILE__)
require "rubygems"
::Gem::Specification.new do |s|
  s.name                        = 'starbot-skype'
  s.version                     = Starbot::Skype::VERSION
  s.platform                    = ::Gem::Platform::RUBY
  s.authors                     = ['Gavin Brock', 'Caleb Crane', 'Eric Platon']
  s.email                       = ["starbot@simulacre.org"]
  s.homepage                    = "http://www.github.com/simulacre/simbot"
  s.summary                     = 'Run starbot on Skype'
  s.description                 = 'Starbot answers questions and volunteers information'
  s.required_rubygems_version   = ">= 1.3.6"
  s.rubyforge_project           = 'starbot-skype'
  s.files                       = Dir["lib/**/*.rb", "bin/*", "*.md"]
  s.require_paths               = ['lib']
  s.executables                 = Dir["bin/*"].map{|f| f.split("/")[-1] }

  #s.add_dependency 'starbot'
end
