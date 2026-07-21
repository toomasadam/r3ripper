# frozen_string_literal: true

require_relative "lib/rubyripper/base"

Gem::Specification.new do |spec|
  spec.name          = "rubyripper"
  spec.version       = $rr_version.gsub('a', '.pre.a') # Standardize version for RubyGems
  spec.authors       = ["Bouke Woudstra"]
  spec.email         = ["boukewoudstra@gmail.com"]

  spec.summary       = "A secure ripper for Linux/BSD/OSX"
  spec.description   = "Rubyripper aims to deliver high quality rips from audio cd's to your computer drive by ripping tracks multiple times and comparing results."
  spec.homepage      = "https://github.com/boukew/rubyripper" # Assuming a modern home
  spec.license       = "GPL-3.0"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/boukew/rubyripper/blob/master/README"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["rubyripper_cli", "rubyripper_gtk2"] # Kept original names for now
  spec.require_paths = ["lib"]

  spec.add_dependency "gettext"
  spec.add_dependency "base64"
  spec.add_dependency "rexml"
  spec.add_dependency "json"
end
