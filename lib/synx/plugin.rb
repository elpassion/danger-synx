module Danger
  # Enforces that .xcodeproj structure is tidy.
  # It wraps around [Synx](https://github.com/venmo/synx) tool to perform the check.
  #
  # @example Ensure that all added / modified project files are synchronized
  #
  #          danger_synx.ensure_clean_structure
  #
  # @see  turekj/danger-synx
  # @tags synx, xcodeproj
  #
  class DangerSynx < Plugin

    # Ensures clean project structure. Runs Synx on all .xcodeproj
    # files that where either added or modified.
    #
    # @return   [void]
    #
    def ensure_clean_structure
      unless precheck_synx_installation?
        fail "synx > 0.2.1 is not in the user's PATH and has failed to install with gem"
        return
      end

      generate_output synx_issues
    end

    # Checks whether Synx in a correct version is installed in the system.
    # If not, tries to recover by installing it.
    # Returns true if Synx is present or installation was successful.
    #
    # @return [bool]
    #
    def precheck_synx_installation?
      unless synx_installed?
        `gem install synx`
      end

      synx_installed?
    end

    # Returns a command to run for synx
    #
    # @return [String]
    def synx
      return "#{'bundle exec ' if File.exists?('Gemfile')}synx"
    end

    # Tests whether Synx is already installed and meets minimal
    # version requirements.
    #
    # @return [bool]
    #
    def synx_installed?
      if match = `#{synx} --version`.match(/Synx (\d+)\.(\d+)\.(\d+)/i)
        major, minor, patch = match.captures
        Integer(major) > 0 || Integer(minor) > 2 || Integer(patch) > 1
      else
        false
      end
    end

    # Triggers Synx on all projects that were modified or added
    # to the project. Returns accumulated list of issues
    # for those projects.
    #
    # @return [Array<(String, String)>]
    #
    def synx_issues
      (git.modified_files + git.added_files).select { |f| f.include? '.xcodeproj' }.reduce([]) { |i, f| i + synx_project(f) }
    end

    # Triggers Synx in a dry-run mode on a project file.
    # Parses output and returns a list of issues.
    #
    # @param  [String] modified_file_path
    #         Path of file contained in .xcodeproj to Synx
    #
    # @return [(String, String)]
    #
    def synx_project(modified_file_path)
      path = project_path modified_file_path
      name = project_name path
      output = `#{synx} -w warning "#{path}" 2>&1`.lines
      output.map(&:strip).select { |o| o.start_with? 'warning: ' }.map { |o| [name, strip_prefix(o)] }
    end

    private

    def project_path(modified_file_path)
      if match = modified_file_path.match('(.+\.xcodeproj)*+')
        return match[0]
      end
    end

    def project_name(project_path)
      project_path.split('/').last
    end

    def strip_prefix(output_line)
      output_line.slice(9, output_line.size - 9)
    end

    def generate_output(issues)
      if issues.count > 0
        warn("Synx detected #{issues.size} structural issue(s)")

        message = "### Synx structural issues\n\n"
        message << "| Project file | Issue |\n"
        message << "| --- | --- |\n"

        issues.each do |(project, issue)|
          message << "| #{project} | #{issue} |\n"
        end

        markdown message
      end
    end

  end
end
