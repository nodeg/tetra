# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat
describe Tetra::Ant do
  # rubocop:enable RSpec/SpecFilePathFormat
  include Tetra::Mockers

  let(:project) { create_mock_project }
  let(:path) { create_mock_executable("ant") }

  before do
    project
    path
  end

  after do
    delete_mock_project
  end

  describe "#get_ant_commandline" do
    it "returns commandline options for running Ant" do
      project.from_directory do
        commandline = described_class.commandline(".", mock_executable_dir("ant"))
        expect(commandline).to eq File.join(".", path)
      end
    end
  end
end
