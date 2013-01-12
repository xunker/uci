require 'spec_helper'
require 'uci'

describe Uci do
  before(:each) do
    Uci.any_instance.stub(:check_engine)
    Uci.any_instance.stub(:open_engine_connection)
    Uci.any_instance.stub(:get_engine_name)
    Uci.any_instance.stub(:new_game!)
  end

  subject do
    Uci.new(
      :engine_path => '/usr/bin/stockfish',
      :debug => true
    )
  end

  describe "#initialize" do
    let(:valid_options) do
      { :engine_path => 'xxx' }
    end
    it "should be an instance of Uci" do
      subject.should be_a_kind_of Uci
    end
    it "should require :engine_path' in the options hash" do
      lambda { Uci.new({}) }.should raise_exception
      lambda { Uci.new(valid_options) }.should_not raise_exception
    end
    it "should set debug mode" do
      uci = Uci.new(valid_options)
      uci.debug.should be_false

      uci = Uci.new(valid_options.merge( :debug => true ))
      uci.debug.should be_true
    end
  end

  describe "#ready?" do
    before(:each) do
      subject.stub!(:write_to_engine).with('isready')
    end

    context "engine is ready" do
      it "should be true" do
        subject.stub!(:read_from_engine).and_return('readyok')

        subject.ready?.should be_true
      end
    end

    context "engine is not ready" do
      it "should be false" do
        subject.stub!(:read_from_engine).and_return('no')

        subject.ready?.should be_false
      end
    end
  end

  describe "new_game?" do
    context "game is new" do
      it "should be true" do
        subject.stub(:moves).and_return([])
        subject.new_game?.should be_true
      end
    end
    context "game is not new" do
      it "should be false" do
        subject.stub(:moves).and_return(%w[ a2a3 ])
        subject.new_game?.should be_false
      end
    end
  end
end