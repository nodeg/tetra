# frozen_string_literal: true

require "spec_helper"

describe "`tetra`", type: :aruba do
  let(:my_package) { "mypackage" }
  let(:commons_package) { "commons-collections" }
  let(:zip_archive) { "commons-collections.zip" }
  let(:tar_archive) { "commons-collections.tar.gz" }

  # Define the expected directory structures as attributes
  let(:base_dirs) { %w[.git kit src] }
  let(:archive_dirs) { %w[.git kit src packages] }

  it "shows an error if required parameters are not set" do
    run_command_and_stop("tetra init", fail_on_error: false)

    expect(last_command_started.stderr).to include("parameter 'PACKAGE_NAME': no value provided")
  end

  it "shows an error if required parameters are not set, even if options are set" do
    run_command_and_stop("tetra init -n", fail_on_error: false)

    expect(last_command_started.stderr).to include("parameter 'PACKAGE_NAME': no value provided")
  end

  it "shows an error if no sources are specified and -n is not set" do
    run_command_and_stop("tetra init #{my_package}", fail_on_error: false)

    expect(last_command_started.stderr).to include("please specify a source archive")
    expect(my_package).not_to be_an_existing_directory
  end

  it "inits a new project without sources" do
    run_command_and_stop("tetra init --no-archive #{my_package}")

    expect(last_command_started.output).to include("Project inited in #{my_package}/.")
    expect(my_package).to be_an_existing_directory

    cd(my_package)

    expect(base_dirs).to all(be_an_existing_directory)
  end

  it "inits a new project with a zip source file" do
    # Use binread for binary files to avoid encoding issues
    archive_source = File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.zip")
    archive_contents = File.binread(archive_source)

    write_file(zip_archive, archive_contents)

    run_command_and_stop("tetra init #{commons_package} #{zip_archive}")

    output = last_command_started.output
    expect(output).to include("Project inited in #{commons_package}/.")
    expect(output).to include("Sources decompressed in #{commons_package}/src/")
    expect(output).to include("original archive copied in #{commons_package}/packages/.")
    expect(output).to include("Please add any other precompiled build dependency to kit/.")

    expect(commons_package).to be_an_existing_directory

    cd(commons_package)

    expect(archive_dirs).to all(be_an_existing_directory)

    # Verify extraction
    expect(File.join("src", Tetra::CCOLLECTIONS)).to be_an_existing_directory
    expect(File.join("src", Tetra::CCOLLECTIONS, "pom.xml")).to be_an_existing_file

    # Verify archive storage
    expect(File.join("packages", commons_package, zip_archive)).to be_an_existing_file

    # Verify Git history
    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("Initial sources added from archive")
  end

  it "inits a new project with a tar source file" do
    # Use binread for binary files
    archive_source = File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.tar.gz")
    archive_contents = File.binread(archive_source)

    write_file(tar_archive, archive_contents)

    run_command_and_stop("tetra init #{commons_package} #{tar_archive}")

    output = last_command_started.output
    expect(output).to include("Project inited in #{commons_package}/.")
    expect(output).to include("Sources decompressed in #{commons_package}/src/")
    expect(output).to include("original archive copied in #{commons_package}/packages/.")
    expect(output).to include("Please add any other precompiled build dependency to kit/.")

    expect(commons_package).to be_an_existing_directory

    cd(commons_package)

    expect(archive_dirs).to all(be_an_existing_directory)

    # Verify extraction
    expect(File.join("src", Tetra::CCOLLECTIONS)).to be_an_existing_directory
    expect(File.join("src", Tetra::CCOLLECTIONS, "pom.xml")).to be_an_existing_file

    # Verify archive storage
    expect(File.join("packages", commons_package, tar_archive)).to be_an_existing_file

    # Verify Git history
    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("Initial sources added from archive")
  end
end
