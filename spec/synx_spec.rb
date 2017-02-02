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

    end
  end
end
