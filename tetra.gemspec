# frozen_string_literal: true

require_relative "lib/tetra/version"

Gem::Specification.new do |spec|
  spec.name        = "tetra"
  spec.version     = Tetra::VERSION
  spec.authors     = ["Dominik Gedon", "Silvio Moioli"]
  spec.email       = ["dominik.gedon@suse.com", "silvio.moioli@suse.com"]
  spec.homepage    = "https://github.com/uyuni-project/tetra"
  spec.summary     = "A tool to package Java projects"
  spec.description = <<~TEXT
    Tetra simplifies the creation of spec files and archives
    to distribute Java projects in RPM format.
  TEXT

  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/uyuni-project/tetra/issues",
    "homepage_uri" => "https://rubygems.org/gems/tetra",
    "source_code_uri" => "https://github.com/uyuni-project/tetra",
    "rubygems_mfa_required" => "true",
    "allowed_push_host" => "https://rubygems.org"
  }

  spec.required_ruby_version = ">= 3.4"
  spec.files = Dir.glob(
    [
      "bin/*",
      "lib/**/*",
      "*.md",
      "LICENSE",
      "COPYING"
    ],
    File::FNM_DOTMATCH
  ).select { |f| File.file?(f) }

  required_template_paths = [
    "lib/template/kit/",
    "lib/template/packages/",
    "lib/template/src/",
    "lib/template/bashrc",
    "lib/template/kit.spec",
    "lib/template/package.spec"
  ]

  # lightweight spec asserting required template paths are present.
  missing_template_paths = required_template_paths.reject do |path|
    spec.files.any? { |file| file.start_with?(path) }
  end
  unless missing_template_paths.empty?
    raise "gemspec packaging regression: missing template files under #{missing_template_paths.join(", ")}"
  end

  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.rdoc_options << "--exclude=lib/template/bundled"

  # Dependencies
  spec.add_dependency "clamp", "~> 1.5"
  spec.add_dependency "json_pure", ">= 2.6.3", "< 2.9.0"
  spec.add_dependency "rexml", ">= 3.2.9", "< 3.5.0"
  spec.add_dependency "rubyzip", "~> 3.4"
  spec.add_dependency "text", "~> 1.3"
end
