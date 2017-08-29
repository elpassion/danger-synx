# Danger Synx

A Danger plugin for [Synx](https://github.com/venmo/synx/). 

## Installation

Currently only Bundler installations are supported. Add following contents to your `Gemfile`:

    gem 'danger-synx'
    gem 'synx', :github => 'turekj/synx', :branch => 'v0.3'
    
And run `bundle install`. 

The plugin relies on a Synx fork because [PR #125](https://github.com/venmo/synx/pull/125) is not yet merged with the core app.

## Usage

Add following line to the `Dangerfile`:

    synx.ensure_clean_structure

`ensure_clean_structure` task runs Synx on every `.xcodeproj` file that is added/modified by a pull request. Issues are gathered and reported in a following format:

| Project file | Issue |
| --- | --- |
| MessyProject.xcodeproj | File reference RootController.swift is not synchronized with file system. |
| MessyProject.xcodeproj | Group /MessyGroup is not sorted alphabetically. |

## Roadmap

- [x] Reporting synx issues for added/modified `.xcodeproj` files.
- [ ] Indicate unused files (`--prune`).
- [ ] Allow custom exclusions for directories (`--exclusion`).
- [ ] Support for toggleable unsorted group reports (`--no-sort-by-name`).
- [x] Support for `--no-sort-by-name` option.

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rspec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
