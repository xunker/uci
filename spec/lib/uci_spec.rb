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

  describe "#board" do
    it "should return an ascii-art version of the current board" do
      # starting position
      subject.board.should == "  ABCDEFGH
8 rnbqkbnr
7 pppppppp
6 ........
5 ........
4 ........
3 ........
2 PPPPPPPP
1 RNBQKBNR
"

      # moves
      subject.move_piece('b2b4')
      subject.move_piece('b8a6')
      subject.board.should == "  ABCDEFGH
8 r.bqkbnr
7 pppppppp
6 n.......
5 ........
4 .P......
3 ........
2 P.PPPPPP
1 RNBQKBNR
"
    end
  end

  describe "#fenstring" do
    it "should return a short fenstring of the current board" do
      # starting position
      subject.fenstring.should == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"

      # moves
      subject.move_piece('b2b4')
      subject.move_piece('b8a6')
      subject.fenstring.should == "r1bqkbnr/pppppppp/n7/8/1P6/8/P1PPPPPP/RNBQKBNR"
    end
  end

  describe "#set_board" do
    it "should set the board layout from a passed LONG fenstring" do
      # given
      subject.stub!( :send_position_to_engine )
      subject.set_board("r1bqkbnr/pppppppp/n7/8/1P6/8/P1PPPPPP/RNBQKBNR b KQkq - 0 1")
      # expect
      subject.fenstring.should == "r1bqkbnr/pppppppp/n7/8/1P6/8/P1PPPPPP/RNBQKBNR"
    end
    it "should raise an error is the passed fen format is incorret" do
      # try to use a short fen where we neeed a long fen
      lambda { subject.set_board("r1bqkbnr/pppppppp/n7/8/1P6/8/P1PPPPPP/RNBQKBNR") }.should raise_exception FenFormatError
    end
  end

  describe "#place_piece" do
    it "should place a piece on the board" do
      subject.place_piece(:white, :queen, "a3")
      subject.get_piece("a3").should == [:queen, :white]

      subject.place_piece(:black, :knight, "a3")
      subject.get_piece("a3").should == [:knight, :black]
    end
    it "should raise an error if the board was set from a fen string" do
      subject.stub!(:send_position_to_engine)
      subject.set_board("r1bqkbnr/pppppppp/n7/8/1P6/8/P1PPPPPP/RNBQKBNR b KQkq - 0 1")
      lambda { subject.place_piece(:black, :knight, "a3") }.should raise_exception BoardLockedError
    end
  end

  describe "#clear_position" do
    it "should clear a position on the board" do
      # sanity
      subject.get_piece("a1").should == [:rook, :white]
      # given
      subject.clear_position("a1")
      # expect
      subject.piece_at?("a1").should be_false
    end
    it "should raise an error if the board was set from a fen string" do
      subject.stub!(:send_position_to_engine)
      subject.set_board("r1bqkbnr/pppppppp/n7/8/1P6/8/P1PPPPPP/RNBQKBNR b KQkq - 0 1")
      lambda { subject.clear_position("a1") }.should raise_exception BoardLockedError
    end
  end

  describe "#piece_name" do
    context "symbol name passed" do
      it "should return the single letter symbol" do
        subject.piece_name(:queen).should == "q"
        subject.piece_name(:knight).should == "n"
      end
    end
    context "single letter symbol passes" do
      it "should return the symbiol name" do
        subject.piece_name('n').should == :knight
        subject.piece_name('k').should == :king
        subject.piece_name('q').should == :queen
      end
    end
  end

  describe "#piece_at?" do
    it "should be true if there is a piece at the position indicated" do
      # assume startpos
      subject.piece_at?("a1").should be_true
    end
    it "should be false if there is not a piece at the position indicated" do
      # assume startpos
      subject.piece_at?("a3").should be_false
    end
  end

  describe "#get_piece" do
    it "should return the information for a piece at a given position" do
      # assume startpos
      subject.get_piece('a1').should == [:rook, :white]
      subject.get_piece('h8').should == [:rook, :black]
    end
    it "should raise an exception if there is no piece at the given position" do
      lambda { subject.get_piece('a3') }.should raise_exception NoPieceAtPositionError
    end
  end

  describe "#moves" do
    it "should return the interal move list" do
      # startpos
      subject.moves.should == []

      # add some moves
      subject.move_piece('a2a3'); subject.move_piece('a7a5')
      subject.moves.should == ['a2a3', 'a7a5']
    end
  end

  describe "#move_piece" do
    pending
  end

  describe "#new_game!" do
    pending
  end

  describe "#bestmove" do
    pending
  end

  describe "#send_position_to_engine" do
    pending
  end

  describe "#go!" do
    pending
  end
end