# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/SpecFilePathFormat
describe Tetra::Project do
  # rubocop:enable RSpec/SpecFilePathFormat
  include Tetra::Mockers

  # Map instance variables from Tetra::Mockers to let helpers
  let(:project) { @project }           # rubocop:disable RSpec/InstanceVariable
  let(:project_path) { @project_path } # rubocop:disable RSpec/InstanceVariable

  before do
    create_mock_project
  end

  after do
    delete_mock_project
  end

  describe "version" do
    it "returns no project version in case no dry-run happened" do
      expect(project.version).to be_nil
    end

    it "returns a project version after dry-run" do
      project.dry_run
      project.finish([])
      expect(project.version).not_to be_nil
    end
  end

  describe "#project?" do
    it "checks if a directory is a tetra project or not" do
      expect(described_class).to be_project(project_path)
      expect(described_class).not_to be_project(File.join(project_path, ".."))
    end
  end

  describe "#find_project_dir" do
    it "recursively finds the parent project directory" do
      expanded_path = File.expand_path(project_path)
      expect(described_class.find_project_dir(expanded_path)).to eq expanded_path
      expect(described_class.find_project_dir(File.expand_path("src", project_path))).to eq expanded_path
      expect(described_class.find_project_dir(File.expand_path("kit", project_path))).to eq expanded_path

      expect do
        described_class.find_project_dir(File.expand_path("..", project_path))
      end.to raise_error(Tetra::NoProjectDirectoryError)
    end
  end

  describe "full_path" do
    it "returns the project's full path" do
      expect(project.full_path).to eq File.expand_path(project_path)
    end
  end

  describe "#template_files" do
    it "returns the list of template files without bundles" do
      expect(project.template_files(false)).to include("kit" => ".")
    end

    it "returns the list of template files with bundles" do
      # NOTE: Adjust the version string if your bundled ant version differs
      expect(project.template_files(true)).to have_key("bundled/apache-ant-1.10.15")
      expect(project.template_files(true)["bundled/apache-ant-1.10.15"]).to eq "kit"
    end
  end

  describe "#init" do
    it "inits a new project" do
      kit_path = File.join(project_path, "kit")
      expect(Dir).to exist(kit_path)

      src_path = File.join(project_path, "src")
      expect(Dir).to exist(src_path)
    end
  end

  describe "#dry_running?" do
    it "checks if a project is dry running" do
      project.from_directory do
        expect(project).not_to be_dry_running
        project.dry_run
        expect(project).to be_dry_running
        project.finish([])
        expect(project).not_to be_dry_running
      end
    end
  end

  describe "#src_patched?" do
    it "checks whether src is dirty" do
      project.from_directory do
        project.dry_run
        project.finish([])
        expect(project).not_to be_src_patched

        FileUtils.touch(File.join("src", "test"))
        expect(project).to be_src_patched
      end
    end
  end

  describe "#finish" do
    it "ends the current dry-run phase after a successful build" do
      project.from_directory do
        File.write(File.join("src", "test"), "A")
      end

      expect(project.dry_run).to be_truthy

      project.from_directory do
        File.write(File.join("src", "test"), "B")
        FileUtils.touch(File.join("src", "test2"))
      end

      expect(project.finish([])).to be_truthy
      expect(project).not_to be_dry_running

      project.from_directory do
        expect(`git rev-list --all`.split("\n").length).to eq 3
        expect(File.read("src/test")).to eq "A"

        expect(`git diff-tree --no-commit-id --name-only -r HEAD~`.split("\n")).to include("src/test")
        expect(File).not_to exist("src/test2")

        expect(`git show HEAD`.split("\n").map(&:strip)).to include("tetra: file-changed: src/test")
      end
    end

    it "ends the current dry-run phase after a failed build" do
      project.from_directory do
        File.write(File.join("src", "test"), "A")
        File.write(File.join("kit", "test"), "A")
      end

      expect(project.dry_run).to be_truthy

      project.from_directory do
        File.write(File.join("src", "test"), "B")
        FileUtils.touch(File.join("src", "test2"))
        File.write(File.join("kit", "test"), "B")
        FileUtils.touch(File.join("kit", "test2"))
      end

      expect(project.abort).to be_truthy
      expect(project).not_to be_dry_running

      project.from_directory do
        expect(`git rev-list --all`.split("\n").length).to eq 1
        expect(File.read("src/test")).to eq "A"
        expect(File).not_to exist("src/test2")

        expect(File.read("kit/test")).to eq "A"
        expect(File).not_to exist("kit/test2")
      end
    end
  end

  describe "#dry_run" do
    it "starts a dry running phase" do
      project.from_directory do
        FileUtils.touch(File.join("src", "test"))
      end

      project.from_directory("src") do
        expect(project.dry_run).to be_truthy
      end

      project.from_directory do
        expect(project).to be_dry_running
        expect(`git rev-list --all`.split("\n").length).to eq 2
        expect(`git diff-tree --no-commit-id --name-only -r HEAD`.split("\n")).to include("src/test")
      end
    end
  end

  describe "#produced_files" do
    it "gets a list of produced files" do
      project.from_directory do
        File.write(File.join("src", "added_outside_dry_run"), "A")
      end

      expect(project.dry_run).to be_truthy
      project.from_directory do
        File.write(File.join("src", "added_in_first_dry_run"), "A")
        File.write("added_outside_directory", "A")
      end
      expect(project.finish([])).to be_truthy

      expect(project.dry_run).to be_truthy
      project.from_directory do
        File.write(File.join("src", "added_in_second_dry_run"), "A")
      end
      expect(project.finish([])).to be_truthy

      list = project.produced_files
      expect(list).to include("added_in_second_dry_run")

      expect(list).not_to include("added_in_first_dry_run")
      expect(list).not_to include("added_outside_dry_run")
      expect(list).not_to include("added_outside_directory")
    end
  end

  describe "#write_source_patches" do
    it "writes patches from the tarball generated by archive_source" do
      project.from_directory do
        test_file = File.join("src", "Test.java")
        FileUtils.touch(test_file)
        project.commit_sources("first version", true)

        File.write(test_file, "A")
        project.commit_sources("patched version", false)

        patches = project.write_source_patches.map { |f| File.basename(f) }
        expect(patches).to include("0001-patched-version.patch")

        patch_contents = File.readlines(File.join("packages", "test-project", "0001-patched-version.patch"))
        expect(patch_contents).to include("--- a/#{test_file}\n")
      end
    end
  end

  describe "#purge_jars" do
    it "moves jars in kit/jars" do
      project.from_directory do
        File.write(File.join("src", "test.jar"), "jarring")
      end

      project.purge_jars

      project.from_directory do
        expect(File).to be_symlink(File.join("src", "test.jar"))
        expect(File.readlink(File.join("src", "test.jar"))).to eq "../kit/jars/test.jar"
        expect(File.readlines(File.join("kit", "jars", "test.jar"))).to include("jarring")
      end
    end
  end
end
