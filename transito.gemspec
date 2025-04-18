# coding: utf-8

files = `git ls-files -- lib/*`.split("\n") +
      ["README.md","CHANGELOG.md","LICENSE",".yardopts",".yard_redcarpet_ext", "lib/transito.jar", "Jarfile"]
cruby_files = files.grep /cruby/
jruby_files = files.grep(/jruby/) + ["lib/transito.jar", "Jarfile"]

Gem::Specification.new do |spec|
  spec.name          = "transito"
  spec.version       = "0.8.dev"
  spec.authors       = ["Maurício Szabo", "Russ Olsen","David Chelimsky","Yoko Harada"]
  spec.email         = ["russ@cognitect.com","dchelimsky@cognitect.com","yoko@cognitect.com"]
  spec.summary       = %q{Transito marshalling for Ruby with some special behaviors}
  spec.description   = %q{Transito marshalling for Ruby with some special behaviors}
  spec.homepage      = "http://github.com/cognitect/transito-ruby"
  spec.license       = "Apache License 2.0"

  spec.required_ruby_version = '>= 2.1.10'

  if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
    spec.files    = files - cruby_files
    spec.platform = 'java'
    spec.add_dependency "lock_jar",                   "~> 0.12.0"
    spec.add_development_dependency "rake-compiler",  "~> 0.9.2"
    private_key_path = nil # not yet supported
    public_key_path = nil  # not yet supported
  else
    spec.files    = files - jruby_files
    spec.add_dependency "oj", "~> 3.16.10"
    spec.add_dependency 'base64', '~> 0.2.0'
    spec.add_dependency "msgpack", "~> 1.1.0"
    spec.add_development_dependency "yard", "~> 0.9.11"
    private_key_path = File.expand_path(File.join(ENV['HOME'], '.gem', 'transito-ruby', 'gem-private_key.pem'))
    public_key_path  = File.expand_path(File.join(ENV['HOME'], '.gem', 'transito-ruby', 'gem-public_cert.pem'))
  end

  spec.test_files    = `git ls-files -- spec/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_dependency "addressable",       "~> 2.3"
  spec.add_development_dependency "rake",  "~> 10.1"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "wrong", "~> 0.7.1"

  if ENV['SIGN_GEM'] && private_key_path && File.exist?(private_key_path)
    spec.signing_key = private_key_path
    spec.cert_chain  = [public_key_path]
  end
end
