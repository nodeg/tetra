# frozen_string_literal: true

module Tetra
  # runs programs in subprocesses
  module ProcessRunner
    include Logging

    # runs a noninteractive executable and returns its output as a string
    # raises ExecutionFailed if the exit status is not 0
    # optionally echoes the executable's output/error to standard output/error
    def run(commandline, echo: false, stdin_data: nil)
      log.debug "running `#{commandline}`"

      out_buffer = StringIO.new
      err_buffer = StringIO.new
      # Flatten handles nested arrays, Compact removes nils
      cmd_args = Array(commandline).flatten.compact.map(&:to_s)

      exit_status = spawn_and_capture(cmd_args, stdin_data, echo, out_buffer, err_buffer)

      out = out_buffer.string
      err = err_buffer.string
      raise_execution_failed(commandline, exit_status, out, err) unless exit_status.success?

      out
    end

    # runs an interactive executable in a subshell
    def run_interactive(command)
      log.debug "running interactive `#{command}`"

      # system() passes control to the subprocess
      cmd_args = Array(command).flatten.compact.map(&:to_s)
      success = system(*cmd_args)

      log.debug "`#{command}` exited with success #{success}"

      raise ExecutionFailed.new(command, $CHILD_STATUS.exitstatus, nil, nil) unless success
    end

    private

    # spawns commandline, writing stdin and reading stdout/stderr concurrently
    # (writing stdin to completion before draining stdout/stderr can deadlock
    # if the child fills its output pipe buffer before consuming all of stdin)
    # returns the resulting Process::Status
    def spawn_and_capture(cmd_args, stdin_data, echo, out_buffer, err_buffer)
      Open3.popen3(*cmd_args) do |stdin, stdout, stderr, wait_thr|
        threads = [
          Thread.new { write_stdin(stdin, stdin_data) },
          Thread.new { pipe_to_buffer(stdout, out_buffer, echo ? $stdout : nil) },
          Thread.new { pipe_to_buffer(stderr, err_buffer, echo ? $stderr : nil) }
        ]
        threads.each(&:join)

        wait_thr.value
      end
    end

    def write_stdin(stdin, stdin_data)
      stdin.write(stdin_data) if stdin_data
      stdin.close # Close stdin so the process knows input is finished
    end

    def pipe_to_buffer(io, buffer, echo_io)
      io.each_line do |line|
        echo_io&.print(line)
        buffer << line
      end
    end

    def raise_execution_failed(commandline, exit_status, out, err)
      log.warn("`#{commandline}` failed with status #{exit_status.exitstatus}")
      if !out.empty? || !err.empty?
        log.warn("Output follows:")
        log.warn(out) unless out.empty?
        log.warn(err) unless err.empty?
      end

      raise ExecutionFailed.new(commandline, exit_status.exitstatus, out, err)
    end
  end

  # raised when a command returns a non-zero status
  class ExecutionFailed < StandardError
    attr_reader :commandline, :status, :out, :err

    def initialize(commandline, status, out, err)
      @commandline = commandline
      @status = status
      @out = out
      @err = err
      super("Command failed: #{commandline} (status: #{status})")
    end

    def to_s
      "\"#{@commandline}\" failed with status #{@status}\n#{out}\n#{err}"
    end
  end
end
