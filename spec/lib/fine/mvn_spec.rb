# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat
describe Tetra::Mvn do
  # rubocop:enable RSpec/SpecFilePathFormat
  include Tetra::Mockers

  let(:project) { @project } # rubocop:disable RSpec/InstanceVariable
  let(:path) { @path }       # rubocop:disable RSpec/InstanceVariable

  before do
    create_mock_project
    @path = create_mock_executable("mvn")
  end

  after do
    delete_mock_project
  end

  describe "#get_mvn_commandline" do
    it "returns commandline options for running maven" do
      project.from_directory do
        commandline = described_class.commandline(".", mock_executable_dir("mvn"))

        # Use implicit string concatenation for cleaner multi-line expectation
        # Note: Since we pass "." as project_path, the result should be relative
        expected_commandline = "./#{path} " \
                               "-Dmaven.repo.local=./kit/m2 " \
                               "--settings ./kit/m2/settings.xml " \
                               "--strict-checksums"

        expect(commandline).to eq expected_commandline
      end
    end
  end
end
