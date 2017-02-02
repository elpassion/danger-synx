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
      warn 'Trying to merge code on a Monday' if Date.today.wday == 1
    end

    def synx_installed?
      `which synx`.strip.start_with? '/'
    end
  end
end
