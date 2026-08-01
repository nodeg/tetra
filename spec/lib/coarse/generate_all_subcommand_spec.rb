# frozen_string_literal: true

require "spec_helper"

describe "`tetra generate-all`", type: :aruba do
  # rubocop:disable RSpec/ExampleLength
  it "generates specs and tarballs for a sample package, source archive workflow" do
    # Use binread for binary files
    archive_source = File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.zip")
    archive_contents = File.binread(archive_source)
    write_file("commons-collections.zip", archive_contents)

    # init project
    run_command_and_stop("tetra init commons-collections commons-collections.zip", exit_timeout: 120)

    cd(File.join("commons-collections", "src", Tetra::CCOLLECTIONS))

    # first dry-run, all normal (Interactive & Slow)
    time_step("source archive workflow: first mvn build") do
      run_command("tetra dry-run --very-very-verbose", exit_timeout: 240)
      type("mvn package -DskipTests")
      type("\u{0004}") # ^D (Ctrl+D)
      stop_all_commands
    end

    expect(last_command_started.output).to include("[INFO] BUILD SUCCESS")
    expect(last_command_started.output).to include("Checking for tetra project")

    # first generate-all, all normal
    time_step("source archive workflow: first generate-all") do
      run_command_and_stop("tetra generate-all", exit_timeout: 300)
    end

    expect(last_command_started.output).to include("commons-collections-kit.spec generated")
    expect(last_command_started.output).to include("commons-collections-kit.tar.xz generated")
    expect(last_command_started.output).to include("build.sh generated")
    expect(last_command_started.output).to include("commons-collections.spec generated")

    # patch one file
    append_to_file("README.txt", "patched by tetra test")

    # second dry-run fails: sources changed
    run_command_and_stop("tetra dry-run", fail_on_error: false)
    expect(last_command_started.output).to include("Changes detected in src")
    expect(last_command_started.output).to include("Dry run not started")

    # run patch
    run_command_and_stop("tetra patch")

    # third dry-run succeeds with patch (Interactive & Slow)
    time_step("source archive workflow: second mvn build") do
      run_command("tetra dry-run", exit_timeout: 240)
      type("mvn package -DskipTests")
      type("\u{0004}")
      stop_all_commands
    end

    expect(last_command_started.output).to include("[INFO] BUILD SUCCESS")

    time_step("source archive workflow: second generate-all") do
      run_command_and_stop("tetra generate-all --very-very-verbose", exit_timeout: 300)
    end

    expect(last_command_started.output).to include("commons-collections-kit.spec generated")
    expect(last_command_started.output).to include("commons-collections-kit.tar.xz generated")
    expect(last_command_started.output).to include("build.sh generated")
    expect(last_command_started.output).to include("commons-collections.spec generated")
    expect(last_command_started.output).to include("0001-Sources-updated.patch generated")

    # rubocop:disable RSpec/ExpectActual
    spec_path = "../../packages/commons-collections/commons-collections.spec"
    expect(spec_path).to have_file_content(/0001-Sources-updated.patch/)
    # rubocop:enable RSpec/ExpectActual
  end
  # rubocop:enable RSpec/ExampleLength

  # rubocop:disable RSpec/ExampleLength
  it "generates specs and tarballs for a sample package, manual source workflow" do
    # Use binread
    archive_source = File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.zip")
    archive_contents = File.binread(archive_source)
    write_file("commons-collections.zip", archive_contents)

    # init project
    run_command_and_stop("tetra init -n commons-collections")

    # add sources
    run_command_and_stop("unzip commons-collections.zip -d commons-collections/src")

    cd("commons-collections")

    # first dry-run fails: sources changed
    run_command_and_stop("tetra dry-run", fail_on_error: false)
    expect(last_command_started.output).to include("Changes detected in src")
    expect(last_command_started.output).to include("Dry run not started")

    # run change-sources
    run_command_and_stop("tetra change-sources ../commons-collections.zip")
    expect(last_command_started.output).to include("New sources committed")

    # second dry-run, all normal (Interactive & Slow)
    cd(File.join("src", Tetra::CCOLLECTIONS))

    time_step("manual source workflow: first mvn build") do
      run_command("tetra dry-run", exit_timeout: 240)
      type("mvn package -DskipTests")
      type("\u{0004}")
      stop_all_commands
    end

    expect(last_command_started.output).to include("[INFO] BUILD SUCCESS")

    # first generate-all, all normal
    time_step("manual source workflow: first generate-all") do
      run_command_and_stop("tetra generate-all", exit_timeout: 120)
    end

    expect(last_command_started.output).to include("commons-collections-kit.spec generated")
    expect(last_command_started.output).to include("commons-collections-kit.tar.xz generated")
    expect(last_command_started.output).to include("build.sh generated")
    expect(last_command_started.output).to include("commons-collections.spec generated")

    # patch one file
    append_to_file("README.txt", "patched by tetra test")

    # second dry-run fails: sources changed
    run_command_and_stop("tetra dry-run", fail_on_error: false)
    expect(last_command_started.output).to include("Changes detected in src")
    expect(last_command_started.output).to include("Dry run not started")

    # run patch
    run_command_and_stop("tetra patch")

    # third dry-run succeeds with patch (Interactive & Slow)
    time_step("manual source workflow: second mvn build") do
      run_command("tetra dry-run", exit_timeout: 240)
      type("mvn package -DskipTests")
      type("\u{0004}")
      stop_all_commands
    end

    expect(last_command_started.output).to include("[INFO] BUILD SUCCESS")

    time_step("manual source workflow: second generate-all") do
      run_command_and_stop("tetra generate-all", exit_timeout: 300)
    end

    expect(last_command_started.output).to include("commons-collections-kit.spec generated")
    expect(last_command_started.output).to include("commons-collections-kit.tar.xz generated")
    expect(last_command_started.output).to include("build.sh generated")
    expect(last_command_started.output).to include("commons-collections.spec generated")
    expect(last_command_started.output).to include("0001-Sources-updated.patch generated")

    # rubocop:disable RSpec/ExpectActual
    spec_path = "../../packages/commons-collections/commons-collections.spec"
    expect(spec_path).to have_file_content(/0001-Sources-updated.patch/)
    expect(spec_path).to have_file_content(/commons-collections.zip/)
    # rubocop:enable RSpec/ExpectActual
  end
  # rubocop:enable RSpec/ExampleLength
end
