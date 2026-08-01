# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat
describe Tetra::Kit do
  # rubocop:enable RSpec/SpecFilePathFormat
  include Tetra::Mockers

  let(:project) { @project } # rubocop:disable RSpec/InstanceVariable
  let(:instance) { described_class.new(project) }

  before do
    create_mock_project
  end

  after do
    delete_mock_project
  end

  describe "#find_executable" do
    it "finds an executable in kit" do
      create_mock_executable("any")
      expect(instance.find_executable("any")).to eq mock_executable_dir("any")
    end

    it "doesn't find an executable in kit" do
      expect(instance.find_executable("any")).to be_nil
    end
  end
end
