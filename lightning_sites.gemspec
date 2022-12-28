Gem::Specification.new do |spec|
  spec.name          = "lightning_sites"
  spec.version       = "1.4.25"
  spec.authors       = ["William Entriken"]
  spec.email         = ["github.com@phor.net"]

  spec.summary       = "Lightning deployment for your ~/Sites folders"
  spec.description   = "Lightning Sites gives you beautifully simple deployment for your ~/Sites folders, inspired by Fastlane. We support all deployment setups."
  spec.homepage      = "https://github.com/fulldecent/Sites"
  spec.license       = "MIT"
  spec.files         = ["lib/lightning_sites.rb"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "colorize", "~> 0.8.1"
  spec.add_runtime_dependency "html-proofer", "~> 5.0", ">= 5.0.3"
  spec.add_runtime_dependency "rake", ">= 12"
  spec.add_runtime_dependency "web-puc", "~> 0.4", ">= 0.4.1"
  spec.add_runtime_dependency "html-proofer-mailto_awesome", "~> 1.0", ">= 1.0.3"
  spec.add_runtime_dependency "w3c_validators", "~> 1.3", ">= 1.3.7"
  spec.add_runtime_dependency "minitest"
end
