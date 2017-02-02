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
        fail "synx > 0.2.1 is not in the user's PATH and has failed to install with brew"
        return
      end

      generate_output synx_issues
    end

    # Checks whether Synx in a correct version is installed in the system.
    # If not, tries to recover by installing it.
    # Returns true if Synx is present or installation was successful.
    #
    # @return bool
    #
    def precheck_synx_installation?
      if not synx_installed?
        `brew install synx`
      elsif not synx_required_version?
        `brew upgrade synx`
      end

      synx_installed? and synx_required_version?
    end

    # Tests whether Synx is already installed.
    #
    # @return bool
    #
    def synx_installed?
      `which synx`.strip.start_with? '/'
    end

    # Tests whether Synx meets > 0.2.1 version requirement.
    #
    # @return bool
    #
    def synx_required_version?
      if match = `synx --version`.match(/Synx (\d+)\.(\d+)\.(\d+)/i)
        major, minor, patch = match.captures
        Integer(major) >= 0 and Integer(minor) >= 2 and Integer(patch) > 1
      end
    end

    # Triggers Synx on all projects that were modified or added
    # to the project. Returns accumulated list of issues
    # for those projects.
    #
    # @return [String]
    #
    def synx_issues
      (git.modified_files + git.added_files).select { |f| f.include? '.xcodeproj' }.reduce([]) { |i, f| i + synx_project(f) }
    end

    # Triggers Synx in a dry-run mode on a project file.
    # Parses output and returns a list of issues.
    #
    # @param  project_path  String
    #         Path of .xcodeproj to Synx
    #
    # @return [String]
    #
    def synx_project(project_path)
      output = `synx -w warning "#{project_path}"`.lines
      output.map(&:strip).select { |o| o.start_with? 'warning: ' }.map { |o| o.slice(9, o.size - 9) }
    end

    def generate_output(issues)
      warn("Synx detected #{issues.size} structural issue(s)")
    end
    private :generate_output

  end
end
