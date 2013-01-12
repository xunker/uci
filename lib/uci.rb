
class UciError < StandardError; end
class MissingRequiredHashKeyError < StandardError; end
class EngineNotFoundError < UciError; end
class EngineNotExecutableError < UciError; end
class EngineNameMismatch < UciError; end
class ReturnStringError < UciError; end
class UnknownNotationExtensionError < UciError; end
class NoMoveError < UciError; end
class EngineResignError < NoMoveError; end
class NoPieceAtPositionError < UciError; end
class UnknownBestmoveSyntax < UciError; end

require 'open3'
require 'io/wait'
class Uci
  attr_reader :moves, :debug
  attr_accessor :movetime
  VERSION = "0.0.1"

  RANKS = {
    'a' => 0, 'b' => 1, 'c' => 2, 'd' => 3,
    'e' => 4, 'f' => 5, 'g' => 6, 'h' => 7
  }
  CASTLING = {
    "white" => false,
    "black" => false
  }

  def initialize(options = {})
    options = default_options.merge(options)
    require_keys!(options, [:engine_path, :movetime])
    @movetime = options[:movetime]

    set_debug(options)
    reset_board!

    check_engine(options)
    open_engine_connection(options[:engine_path])
    new_game!
  end

  def ready?
    write_to_engine('isready')
    read_from_engine == "readyok"
  end

  def new_game!(fenstring = nil)
    raise NotImplementedError, "fenstring for new board not here yet" if fenstring
    write_to_engine('ucinewgame')
    reset_move_record!
  end

  def new_game?
    moves.empty?
  end

  def castled?(player)
    !!CASTLING[player]
  end

  def bestmove
    write_to_engine("go movetime #{@movetime}")
    until (move_string = read_from_engine).to_s.size > 1
      sleep(0.25)
    end
    if move_string =~ /^bestmove/
      if move_string =~ /^bestmove\sa1a1/ # fruit and rybka
        raise EngineResignError, "Engine Resigns. Check Mate? #{move_string}"
      elsif move_string =~ /^bestmove\sNULL/ # robbolita
        raise NoMoveError, "No more moves: #{move_string}"
      elsif move_string =~ /^bestmove\s\(none\)\s/ #stockfish
        raise NoMoveError, "No more moves: #{move_string}"
      elsif bestmove = move_string.match(/^bestmove\s([a-h][1-8][a-h][1-8])([a-z]{1}?)/)
        return bestmove[1..-1].join
      else
        raise UnknownBestmoveSyntax, "Engine returned a 'bestmove' that I don't understand: #{move_string}"
      end
    else
      raise ReturnStringError, "Expected return to begin with 'bestmove', but got '#{move_string}'"
    end
  end

  def go!
    bm = bestmove
    (move, extended) = *bm.match(/^([a-h][1-8][a-h][1-8])([a-z]{1}?)$/)[1..2]
    @moves << move+extended
    move_piece(move)
    if extended.to_s.size > 0
      if extended == 'q'
        place = move.split('')[2..3].join
        p, player = get_piece(place)
        puts "queen promotion: #{p} #{player}" if @debug
        place_piece(player, :queen, place)
      else
        raise UnknownNotationExtensionError, "Unknown notation extension: #{bm}"
      end
    end
    position_str = "position startpos"
    position_str << " moves #{@moves.join(' ')}" unless @moves.empty?
    write_to_engine(position_str)
  end

  def move_piece(position)
    start_pos = position.downcase.split('')[0..1].join
    end_pos = position.downcase.split('')[2..3].join
    (piece, player) = get_piece(start_pos)

    # detect castling
    if piece == :king
      start_rank = start_pos.split('')[1]
      start_file = start_pos.split('')[0].ord
      end_file = end_pos.split('')[0].ord
      if(start_file - end_file).abs > 1
        CASTLING[player] = true
        # assume the engine knows the rook is present
        if start_file < end_file # king's rook
          place_piece(player, :rook, "f#{start_rank}")
          clear_position("h#{start_rank}")
        elsif end_file < start_file # queen's rook
          place_piece(player, :rook, "d#{start_rank}")
          clear_position("a#{start_rank}")
        else
          raise "Unknown castling behviour!"
        end
      end
    end

    place_piece(player, piece, end_pos)
    clear_position(start_pos)
  end

  def moves
    @moves
  end

  def get_piece(position)
    rank = RANKS[position.to_s.downcase.split('').first]
    file = position.downcase.split('').last.to_i-1
    piece = @board[file][rank]
    if piece.nil?
      raise NoPieceAtPositionError, "No piece at #{position}!"
    end
    player = if piece =~ /^[A-Z]$/
      :white
    else
      :black
    end
    [piece_name(piece), player]
  end

  def piece_at?(position)
    rank = RANKS[position.to_s.downcase.split('').first]
    file = position.downcase.split('').last.to_i-1
    !!@board[file][rank]
  end

  def piece_name(p)
    if p.class.to_s == "Symbol"
      p.to_s.split('').first
    else
      {
        'p' => :pawn,
        'r' => :rook,
        'n' => :night,
        'b' => :bishop,
        'k' => :king,
        'q' => :queen
      }[p.downcase]
    end
  end

  def clear_position(position)
    rank = RANKS[position.to_s.downcase.split('').first]
    file = position.downcase.split('').last.to_i-1
    @board[file][rank] = nil
  end

  def place_piece(player, piece, position)
    rank_index = RANKS[position.downcase.split('').first]

    file_index = position.split('').last.to_i-1
    icon = piece.to_s.split('').first
    (player == :black ? icon.downcase! : icon.upcase!)
    @board[file_index][rank_index] = icon
  end

  def fenstring
    fen = []
    (@board.size-1).downto(0).each do |rank_index|
      rank = @board[rank_index]
      if rank.include?(nil)
        if rank.select{|r|r.nil?}.size == 8
          fen << 8
        else
          rank_str = ""
          empties = 0
          rank.each do |r|
            if r.nil?
              empties += 1
            else
              if empties > 0
                rank_str << empties.to_s
                empties = 0
              end
              rank_str << r
            end
          end
          rank_str << empties.to_s if empties > 0
          fen << rank_str
        end
      else
        fen << rank.join('')
      end
    end
    fen.join('/')
  end

  def board(empty_square_char = '.')
    board_str = "  ABCDEFGH\n"
    (@board.size-1).downto(0).each do |rank_index|
      line = "#{rank_index+1} "
      @board[rank_index].each do |cell|
        line << (cell.nil? ? empty_square_char : cell)
      end
      board_str << line+"\n"
    end
    board_str
  end

protected

  def write_to_engine(message, send_cr=true)
    puts "\twrite_to_engine" if @debug
    puts "\t\tME:    \t'#{message}'" if @debug
    if send_cr && message.split('').last != "\n"
      @engine_stdin.puts message
    else
      @engine_stdin.print message
    end
  end

  def read_from_engine(strip_cr=true)
    puts "\tread_from_engine" if @debug
    response = ""
    while @engine_stdout.ready?
      unless (response = @engine_stdout.readline) =~ /^info/
        puts "\t\tENGINE:\t'#{response}'" if @debug
      end
    end
    if strip_cr && response.split('').last == "\n"
      response.chop
    else
      response
    end
  end

private

  def reset_move_record!
    @moves = []
  end

  def reset_board!
    @board = []
    8.times do |x|
      @board[x] ||= []
      8.times do |y|
        @board[x] << nil
      end
    end

    set_startpos!

    reset_move_record!
  end

  def set_startpos!
    %w[a b c d e f g h].each do |f|
      place_piece(:white, :pawn, "#{f}2")
      place_piece(:black, :pawn, "#{f}7")
    end

    place_piece(:white, :rook, "a1")
    place_piece(:white, :rook, "h1")
    place_piece(:white, :night, "b1")
    place_piece(:white, :night, "g1")
    place_piece(:white, :bishop, "c1")
    place_piece(:white, :bishop, "f1")
    place_piece(:white, :king, "e1")
    place_piece(:white, :queen, "d1")

    place_piece(:black, :rook, "a8")
    place_piece(:black, :rook, "h8")
    place_piece(:black, :night, "b8")
    place_piece(:black, :night, "g8")
    place_piece(:black, :bishop, "c8")
    place_piece(:black, :bishop, "f8")
    place_piece(:black, :king, "e8")
    place_piece(:black, :queen, "d8")
  end

  def check_engine(options)
    if !options[:options].nil?
      raise NotImplementedError, "options passing not implemented yet"
    end

    unless File.exist?(options[:engine_path])
      raise EngineNotFoundError, "Engine not found at #{options[:engine_path]}"
    end
    unless File.executable?(options[:engine_path])
      raise EngineNotExecutableError, "Engine at #{options[:engine_path]} is not executable"
    end
  end

  def set_debug(options)
    @debug = !!options[:debug]
  end

  def open_engine_connection(engine_path)
    @engine_stdin, @engine_stdout, @engine_stderr = Open3.popen3(engine_path)
  end

  def require_keys!(hash, *required_keys)
    required_keys.flatten.each do |required_key|
      if !hash.keys.include?(required_key)
        key_string = (required_key.is_a?(Symbol) ? ":#{required_key}" : required_key )
        raise MissingRequiredHashKeyError, "Hash key '#{key_string}' missing"
      end
    end
    true
  end

  def default_options
    { :movetime => 100 }
  end
end
