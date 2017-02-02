module Danger
  # Enforces that .xcodeproj structure is tidy.
  # It wraps around [Synx](https://github.com/venmo/synx) tool to perform the check.
  #
  # @example Ensure that the project is synchronized
  #
  #          danger_synx.ensure_clean_structure
  #
  # @see  turekj/danger-synx
  # @tags synx, xcodeproj
  #
  class DangerSynx < Plugin

    # An attribute that you can read/write from your Dangerfile
    #
    # @return   [Array<String>]
    attr_accessor :my_attribute

    # A method that you can call from your Dangerfile
    # @return   [Array<String>]
    #
    def ensure_clean_structure
      unless precheck_synx_installation?
        fail "synx > 0.2.1 is not in the user's PATH and has failed to install with brew"
        return
      end

      warn 'Trying to merge code on a Monday' if Date.today.wday == 1
    end

    def precheck_synx_installation?
      if not synx_installed?
        `brew install synx`
      elsif not synx_required_version?
        `brew upgrade synx`
      end

      synx_installed? and synx_required_version?
    end

    def synx_installed?
      `which synx`.strip.start_with? '/'
    end

    def synx_required_version?
      if match = `synx --version`.match(/Synx (\d+)\.(\d+)\.(\d+)/i)
        major, minor, patch = match.captures
        Integer(major) >= 0 and Integer(minor) >= 2 and Integer(patch) > 1
      end
    end

  end
end
