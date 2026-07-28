# frozen_string_literal: true

require_relative "lib/r3ripper/base"

Gem::Specification.new do |spec|
  spec.name          = "r3ripper"
  spec.version       = $rr_version.gsub('a', '.pre.a') # Standardize version for RubyGems
  spec.authors       = ["Bouke Woudstra", "RubyRipperReborn Contributors"]
  spec.email         = ["boukewoudstra@gmail.com"]

  spec.summary       = "A secure digital audio extraction tool for Linux/BSD"
  spec.description   = "RubyRipperReborn (r3ripper) delivers high quality audio CD extraction with GTK+ 3 and CLI interfaces."
  spec.homepage      = "https://github.com/toomasadam/r3ripper"
  spec.license       = "GPL-3.0"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/toomasadam/r3ripper/blob/master/README.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["r3ripper", "r3ripper_gui", "rubyripper_cli", "rubyripper_gtk2"]
  spec.require_paths = ["lib"]

  spec.add_dependency "gettext"
  spec.add_dependency "base64"
  spec.add_dependency "rexml"
  spec.add_dependency "json"
end
