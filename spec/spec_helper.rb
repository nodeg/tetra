# frozen_string_literal: true

require "aruba/rspec"
require "simplecov"
require "simplecov-cobertura"
require "vcr"
require "webmock/rspec"
require "tetra"

SimpleCov.start do
  # Use the Cobertura formatter for CI, but keep HTML for local browsing
  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter,
                                                       SimpleCov::Formatter::CoberturaFormatter
                                                     ])
end

VCR.configure do |config|
  # Where VCR will save the recorded network responses (cassettes)
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"

  # Tell VCR to use webmock to intercept HTTP requests
  config.hook_into :webmock

  # Automatically use VCR when a test block has the `vcr: true` metadata tag
  config.configure_rspec_metadata!

  # Prevents VCR from blocking localhost requests if Aruba or other tools need them
  config.ignore_localhost = true
end

Aruba.configure do |config|
  # Increase the default timeout from 3 seconds to 15 seconds.
  config.exit_timeout = 15
  # Optional: Increase I/O wait time if your tool is slow to output text
  config.io_wait_timeout = 2
end

module Tetra
  # Diagnostic-only helper: wraps a block and prints its wall-clock duration
  # to real stdout (visible in the raw CI log regardless of RSpec formatter),
  # so we can see which step - the mvn build vs. generate-all's kit
  # archiving - actually dominates the coarse specs' wall time.
  # Remove once the real bottleneck is confirmed.
  module StepTiming
    def time_step(label)
      start = Time.now
      result = yield
      $stdout.puts "[TIMING] #{label}: #{(Time.now - start).round(2)}s"
      result
    end
  end
end

RSpec.configure do |config|
  config.include Aruba::Api
  config.include Tetra::StepTiming, type: :aruba
  # If running in a CI environment, use the verbose 'documentation' formatter
  config.formatter = :documentation if ENV["CI"]

  config.around do |example|
    # Capture original state of all env vars we intend to touch
    original_env = {
      "PATH" => ENV.fetch("PATH", nil),
      "GIT_AUTHOR_NAME" => ENV.fetch("GIT_AUTHOR_NAME", nil),
      "GIT_AUTHOR_EMAIL" => ENV.fetch("GIT_AUTHOR_EMAIL", nil),
      "GIT_COMMITTER_NAME" => ENV.fetch("GIT_COMMITTER_NAME", nil),
      "GIT_COMMITTER_EMAIL" => ENV.fetch("GIT_COMMITTER_EMAIL", nil)
    }

    bin_path = File.expand_path(File.join(__dir__, "..", "bin"))

    # Apply changes to global ENV (affects Ruby unit tests)
    # Subprocesses spawned by Aruba inherit this modified PATH automatically
    ENV["PATH"] = "#{bin_path}#{File::PATH_SEPARATOR}#{original_env["PATH"]}"
    ENV["GIT_AUTHOR_NAME"] = "Tetra Test"
    ENV["GIT_AUTHOR_EMAIL"] = "test@example.com"
    ENV["GIT_COMMITTER_NAME"] = "Tetra Test"
    ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"

    # Apply changes to Aruba (affects subprocesses/coarse tests)
    if respond_to?(:set_environment_variable)
      # NOTE: set_environment_variable overwrites.
      set_environment_variable("GIT_AUTHOR_NAME", "Tetra Test")
      set_environment_variable("GIT_AUTHOR_EMAIL", "test@example.com")
      set_environment_variable("GIT_COMMITTER_NAME", "Tetra Test")
      set_environment_variable("GIT_COMMITTER_EMAIL", "test@example.com")
    end

    begin
      example.run
    ensure
      # Restore original environment state
      original_env.each do |key, value|
        if value.nil?
          ENV.delete(key)
        else
          ENV[key] = value
        end
      end
    end
  end

  config.before do
    # Reset the LicenseMapper state before every single test
    Tetra::LicenseMapper.reset! if defined?(Tetra::LicenseMapper)
  end
end

module Tetra
  # custom mock methods
  module Mockers
    # creates a minimal tetra project
    def create_mock_project
      @project_path = File.join("spec", "data", "test-project")

      Tetra::Project.init(@project_path, include_bundled_software: false)

      @project = Tetra::Project.new(@project_path)
    end

    def delete_mock_project
      FileUtils.rm_rf(@project_path)
    end

    # creates an executable in kit that will print its parameters
    # in a test_out file for checking. Returns mocked executable
    # full path
    def create_mock_executable(executable_name)
      Dir.chdir(@project_path) do
        dir = mock_executable_dir(executable_name)
        FileUtils.mkdir_p(dir)
        executable_path = mock_executable_path(executable_name)
        File.open(executable_path, "w") { |io| io.puts "echo $0 $*>test_out" }
        File.chmod(0o777, executable_path)
        executable_path
      end
    end

    # returns the path for a mocked executable's directory
    def mock_executable_dir(executable_name)
      File.join("kit", executable_name, "bin")
    end

    # returns the path for a mocked executable
    def mock_executable_path(executable_name)
      File.join(mock_executable_dir(executable_name), executable_name)
    end
  end
end
