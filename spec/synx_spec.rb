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
  end
end
