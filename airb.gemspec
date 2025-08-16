# frozen_string_literal: true

require_relative "lib/airb/version"

Gem::Specification.new do |spec|
  spec.name = "airb"
  spec.version = Airb::VERSION
  spec.authors = ["Scott Werner"]
  spec.email = ["scott@sublayer.com"]

  spec.summary = "TODO: Write a short summary, because RubyGems requires one."
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/sublayerapp/airb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sublayerapp/airb"
  spec.metadata["changelog_uri"] = "https://github.com/sublayerapp/airb"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "vsm", "~> 0.1"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "async-rspec", "~> 1.17"
  spec.add_development_dependency "rubocop", "~> 1.79"
  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
