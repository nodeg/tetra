# frozen_string_literal: true

module Tetra
  # encapsulates tar
  class Tar
    include ProcessRunner

    # decompresses a file in a target directory
    def decompress(tarfile, directory)
      # Use Array format to prevent shell injection.
      result = run(["tar", "xvf", tarfile, "--directory", directory], echo: false, stdin_data: nil)

      result&.strip
    end
  end
end
