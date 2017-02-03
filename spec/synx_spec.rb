require File.expand_path('../spec_helper', __FILE__)

module Danger
  describe Danger::DangerSynx do
    it 'should be a plugin' do
      expect(Danger::DangerSynx.new(nil)).to be_a Danger::Plugin
    end

    describe 'with Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @synx = @dangerfile.synx
      end

      describe :synx do
        it "should return synx when Gemfile is not present" do
          allow(File).to receive(:exists?).with('Gemfile').and_return(false)
          expect(@synx.synx).to eq('synx')
        end

        it "should return bundle exec synx when Gemfile is present" do
          allow(File).to receive(:exists?).with('Gemfile').and_return(true)
          expect(@synx.synx).to eq('bundle exec synx')
        end
      end

      describe :synx_installed? do
        before do
          allow(File).to receive(:exists?).with('Gemfile').and_return(true)
        end

        it "reports that synx is not installed if executable is not found" do
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('sh: synx not found')
          expect(@synx.synx_installed?).to be_falsy
        end

        it "reports that synx is not installed if version is 0.2.1" do
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('Synx 0.2.1')
          expect(@synx.synx_installed?).to be_falsy
        end

        it "reports that synx is installed if version is 0.2.2" do
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('Synx 0.2.2')
          expect(@synx.synx_installed?).to be_truthy
        end

        it "reports that synx is installed if version is 0.3.0" do
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('Synx 0.3.0')
          expect(@synx.synx_installed?).to be_truthy
        end

        it "reports that synx is installed if version is 1.0.0" do
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('Synx 1.0.0')
          expect(@synx.synx_installed?).to be_truthy
        end
      end

      describe :precheck_synx_installation do
        before do
          allow(File).to receive(:exists?).with('Gemfile').and_return(true)
        end

        it "should install synx if needed" do
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('sh: synx not found')
          expect(@synx).to receive(:`).with('gem install synx')
          @synx.precheck_synx_installation?
        end

        it "should report that synx is installed correctly" do
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('Synx 0.3.0')
          expect(@synx.precheck_synx_installation?).to be_truthy
        end
      end

      describe :synx_issues do
        before do
          allow(File).to receive(:exists?).with('Gemfile').and_return(true)
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('Synx 0.3.0')
        end

        it "should return a list of issues found in all projects" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "A.xcodeproj" 2>&1').and_return("warning: Warning.\nwarning: Another warning.\n")
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "B.xcodeproj" 2>&1').and_return("warning: Issue.\n")
          expect(@synx.synx_issues).to match_array([['A.xcodeproj', 'Warning.'], ['A.xcodeproj', 'Another warning.'], ['B.xcodeproj', 'Issue.']])
        end
      end

      describe :ensure_clean_structure do
        before do
          allow(File).to receive(:exists?).with('Gemfile').and_return(true)
          allow(@synx).to receive(:`).with('bundle exec synx --version').and_return('Synx 0.3.0')
        end

        it "should trigger synx for modified project files" do
          allow(@synx.git).to receive(:modified_files).and_return(['Project/Sources/AppDelegate.swift', 'Project/Project.xcodeproj/project.pbxproj'])
          allow(@synx.git).to receive(:added_files).and_return(['Other Project/Other Project.xcodeproj/project.pbxproj', 'Other Project/Resources/image.png/project.xcworkspace'])
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "Project/Project.xcodeproj" 2>&1').and_return('')
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "Other Project/Other Project.xcodeproj" 2>&1').and_return('')
          @synx.ensure_clean_structure
        end

        it "should output a warning with number of issues" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "A.xcodeproj" 2>&1').and_return("warning: Warning.\nwarning: Another warning.\n")
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "B.xcodeproj" 2>&1').and_return("warning: Issue.\n")
          expect(@synx).to receive(:warn).with('Synx detected 3 structural issue(s)')
          @synx.ensure_clean_structure
        end

        it "should not output warning if there are no issues" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "A.xcodeproj" 2>&1').and_return('')
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "B.xcodeproj" 2>&1').and_return('')
          expect(@synx).to_not receive(:warn)
          @synx.ensure_clean_structure
        end

        it "should not output markdown when there are no issues" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "A.xcodeproj" 2>&1').and_return('')
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "B.xcodeproj" 2>&1').and_return('')
          expect(@synx).to_not receive(:markdown)
          @synx.ensure_clean_structure
        end

        it "should output table with issues as markdown" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "A.xcodeproj" 2>&1').and_return("warning: Warning.\nwarning: Another warning.\n")
          expect(@synx).to receive(:`).with('bundle exec synx -w warning "B.xcodeproj" 2>&1').and_return("warning: Issue.\n")

          @synx.ensure_clean_structure
          output = @synx.status_report[:markdowns].first.to_s

          expect(output).to include('Synx structural issues')
          expect(output).to include('A.xcodeproj | Warning.')
          expect(output).to include('A.xcodeproj | Another warning.')
          expect(output).to include('B.xcodeproj | Issue.')
        end
      end

    end
  end
end
