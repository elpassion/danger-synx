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

      describe :synx_installed? do
        it "reports that synx is not installed in zsh shell" do
          allow(@synx).to receive(:`).with('which synx').and_return('synx not found')
          expect(@synx.synx_installed?).to be_falsy
        end

        it "reports that synx is not installed in sh shell" do
          allow(@synx).to receive(:`).with('which synx').and_return('')
          expect(@synx.synx_installed?).to be_falsy
        end

        it "reports that synx is installed" do
          allow(@synx).to receive(:`).with('which synx').and_return('/bin/synx')
          expect(@synx.synx_installed?).to be_truthy
        end
      end

      describe :synx_required_version? do
        it "reports that 0.2.1 synx version is too old" do
          allow(@synx).to receive(:`).with('synx --version').and_return('Synx 0.2.1')
          expect(@synx.synx_required_version?).to be_falsy
        end

        it "reports that 0.2.2 synx version is good" do
          allow(@synx).to receive(:`).with('synx --version').and_return('Synx 0.2.2')
          expect(@synx.synx_required_version?).to be_truthy
        end

        it "handles malformed output for synx version" do
          allow(@synx).to receive(:`).with('synx --version').and_return('Not even a version')
          expect(@synx.synx_required_version?).to be_falsy
        end
      end

      describe :precheck_synx_installation do
        it "should install synx if needed" do
          allow(@synx).to receive(:`).with('which synx').and_return('synx not found')
          expect(@synx).to receive(:`).with('brew install synx')
          @synx.precheck_synx_installation?
        end

        it "should upgrade synx if needed" do
          allow(@synx).to receive(:`).with('which synx').and_return('/bin/synx')
          allow(@synx).to receive(:`).with('synx --version').and_return('Synx 0.2.1')
          expect(@synx).to receive(:`).with('brew upgrade synx')
          @synx.precheck_synx_installation?
        end

        it "should report whether synx is installed correctly" do
          allow(@synx).to receive(:`).with('which synx').and_return('/bin/synx')
          allow(@synx).to receive(:`).with('synx --version').and_return('Synx 0.2.2')
          expect(@synx.precheck_synx_installation?).to be_truthy
        end
      end

      describe :synx_issues do
        before do
          allow(@synx).to receive(:`).with('which synx').and_return('/bin/synx')
          allow(@synx).to receive(:`).with('synx --version').and_return('Synx 0.2.2')
        end

        it "should return a list of issues found in all projects" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('synx -w warning "A.xcodeproj" 2>&1').and_return("warning: Warning.\nwarning: Another warning.\n")
          expect(@synx).to receive(:`).with('synx -w warning "B.xcodeproj" 2>&1').and_return("warning: Issue.\n")
          expect(@synx.synx_issues).to match_array([['A.xcodeproj', 'Warning.'], ['A.xcodeproj', 'Another warning.'], ['B.xcodeproj', 'Issue.']])
        end
      end

      describe :ensure_clean_structure do
        before do
          allow(@synx).to receive(:`).with('which synx').and_return('/bin/synx')
          allow(@synx).to receive(:`).with('synx --version').and_return('Synx 0.2.2')
        end

        it "should trigger synx for modified project files" do
          allow(@synx.git).to receive(:modified_files).and_return(['Project/Sources/AppDelegate.swift', 'Project/Project.xcodeproj/project.pbxproj'])
          allow(@synx.git).to receive(:added_files).and_return(['Other Project/Other Project.xcodeproj/project.pbxproj', 'Other Project/Resources/image.png/project.xcworkspace'])
          expect(@synx).to receive(:`).with('synx -w warning "Project/Project.xcodeproj" 2>&1').and_return('')
          expect(@synx).to receive(:`).with('synx -w warning "Other Project/Other Project.xcodeproj" 2>&1').and_return('')
          @synx.ensure_clean_structure
        end

        it "should output a warning with number of issues" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('synx -w warning "A.xcodeproj" 2>&1').and_return("warning: Warning.\nwarning: Another warning.\n")
          expect(@synx).to receive(:`).with('synx -w warning "B.xcodeproj" 2>&1').and_return("warning: Issue.\n")
          expect(@synx).to receive(:warn).with('Synx detected 3 structural issue(s)')
          @synx.ensure_clean_structure
        end

        it "should not output warning if there are no issues" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('synx -w warning "A.xcodeproj" 2>&1').and_return('')
          expect(@synx).to receive(:`).with('synx -w warning "B.xcodeproj" 2>&1').and_return('')
          expect(@synx).to_not receive(:warn)
          @synx.ensure_clean_structure
        end

        it "should not output markdown when there are no issues" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('synx -w warning "A.xcodeproj" 2>&1').and_return('')
          expect(@synx).to receive(:`).with('synx -w warning "B.xcodeproj" 2>&1').and_return('')
          expect(@synx).to_not receive(:markdown)
          @synx.ensure_clean_structure
        end

        it "should output table with issues as markdown" do
          allow(@synx.git).to receive(:modified_files).and_return(['A.xcodeproj/project.pbxproj', 'B.xcodeproj/project.xcworkspace'])
          allow(@synx.git).to receive(:added_files).and_return([])
          expect(@synx).to receive(:`).with('synx -w warning "A.xcodeproj" 2>&1').and_return("warning: Warning.\nwarning: Another warning.\n")
          expect(@synx).to receive(:`).with('synx -w warning "B.xcodeproj" 2>&1').and_return("warning: Issue.\n")

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
