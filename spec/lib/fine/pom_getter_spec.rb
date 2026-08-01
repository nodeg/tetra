# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat
describe Tetra::PomGetter, :vcr do
  # rubocop:enable RSpec/SpecFilePathFormat
  let(:pom_getter) { described_class.new }

  describe "#get_pom" do
    it "gets the pom from a jar" do
      dir_path = File.join("spec", "data", "commons-logging")
      jar_path = File.join(dir_path, "commons-logging-1.3.4.jar")
      path, status = pom_getter.get_pom(jar_path)

      expect(status).to eq :found_in_jar
      expect(File).to exist(path)

      FileUtils.rm(path)
    end

    it "gets the pom from sha1" do
      dir_path = File.join("spec", "data", "antlr")
      jar_path = File.join(dir_path, "antlr-2.7.2.jar")
      path, status = pom_getter.get_pom(jar_path)

      expect(status).to eq :found_via_sha1
      expect(File).to exist(path)

      FileUtils.rm(path)
    end

    it "gets the pom from a heuristic" do
      dir_path = File.join("spec", "data", "nailgun")
      jar_path = File.join(dir_path, "nailgun-0.7.1.jar")
      path, status = pom_getter.get_pom(jar_path)

      expect(status).to eq :found_via_heuristic
      expect(File).to exist(path)

      FileUtils.rm(path)
    end
  end
end
