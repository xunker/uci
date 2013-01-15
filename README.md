# Ruby UCI - A Universal Chess Interface for Ruby

The UCI gem allows for a much more ruby-like way of communicating with chess
engines that support the UCI protocol.

## Installation

NOTE: No Chess engines are included. You must install an appropriate UCI-compatible engine first.

Standard installation applies.  Either:

    gem install uci

..or, in a bundled project, add this line to your application's Gemfile:

    gem 'uci'

And then execute:

    $ bundle

## Example

```ruby
 require 'uci'

  uci = Uci.new( :engine_path => '/usr/local/bin/stockfish' )

  while !uci.ready? do
    puts "Engine isn't ready yet, sleeping..."
    sleep(1)
  end

  # this loop will make the engine play against itself.
  loop do
    puts "Move ##{uci.moves.size+1}."
    puts uci.board # print ascii layout of current board.
    uci.go!
  end
 ```

## Docs

### ::new(options = {})

make a new connection to a UCI engine

<pre>
  Uci.new(
    :engine_path => '/path/to/executable',
    :debug => false, # true or false, default false
    :name => "Name of engine", # optional
    :movetime => 100, # max amount of time engine can "think" in ms - default 100
    :options => { "Navalov Cache" => true } # optional configuration for engine
  )
</pre>

### #bestmove()

Ask the chess engine what the “best move” is given the current state of the
internal chess board. This does not actiually execute a move, it simply queries
for and returns what the engine would consider to be the best option available.

### #board(empty_square_char = '.')

ASCII-art representation of the current internal board.

<pre>
  > puts board
    ABCDEFGH
  8 r.bqkbnr
  7 pppppppp
  6 n.......
  5 ........
  4 .P......
  3 ........
  2 P.PPPPPP
  1 RNBQKBNR
</pre>

### clear_position(position)

Clear a position on the board, regardless of occupied state

### engine_name()

Return the current engine name

### fenstring()

Return the state of the interal board in a FEN (Forsyth–Edwards Notation)
string, SHORT format (no castling info, move, etc).

### get_piece(position)

Get the details of a piece at the current position raises
NoPieceAtPositionError if position is unoccupied.
Returns array of [:piece, :player].

<pre>
  > get_piece(“a2”)
  > [:pawn, :white]
</pre>

### go!()

Tell the engine what the current board layout it, get its best move AND
execute that move on the current board.

### move_piece(move_string)

Move a piece on the current interal board. Will raise NoPieceAtPositionError
if source position is unoccupied. If destination is occipied, the occupying
piece will be removed from the game.

move_string is algebraic standard notation of the chess move. Shorthand is
not allowed.

<pre>
  move_piece("a2a3") # Simple movement
  move_piece("e1g1") # Castling (king’s rook white)
  move_piece("a7a8q" # Pawn promomition (to Queen)
</pre>

Note that there is minimal rule checking here, illegal moves will be executed.

### new_game!()

Send “ucinewgame” to engine, reset interal board to standard starting layout.

### new_game?()
True if no moves have been recorded yet.

### piece_at?(position)

returns a boolean if a position is occupied

<pre>
  > piece_at?(“a2”)
  > true
  > piece_at?(“a3”)
  > false
</pre>

### piece_name(p)

Returns the piece name OR the piece icon, depending on that was passes.

<pre>
  > piece_name(:n)
  > :knight
  > piece_name(:queen)
  > “q”
</pre>

### place_piece(player, piece, position)

Place a piece on the board, regardless of occupied state.

* player - symbol: :black or :white
* piece - symbol: :pawn, :rook, etc
* position - a2, etc

<pre>
  place_piece(:black, :rook, "h1")
</pre>

### ready?()

True if engine is ready, false if not yet ready.

### send_position_to_engine()

Write board position information to the UCI engine, either the starting
position and move log or the current FEN string, depending on how the
board was set up.

This does not tell the engine to execute a move.

### set_board(fen)

Set the board using Forsyth–Edwards Notation (FEN), LONG format including
current player, castling, etc.


* fen - rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1 (Please
see en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation)

## Supported Engines

In theory it can support any UCI-compatible engine (except for conditions outlined in the 'caveats' section).  It has been tested with:

* Stockfish (Jan 11 2013 Github source)
* Fruit 2.3.1 (Mac)

## Caveats

#### No move checking

This gem assumes the engine knows what it's doing. If the gem wishes to place a illegal move it will be accepted.

#### Unix-style Line endings are assumed.

Current version assumes unix-style ("\n") line endings. That means running this under MS-DOS or Windows may barf.

#### Very limited command set.

Very few commands of the total UCI command set are currently supported. they are:

* Starting a new game
* Setting positions
* Getting best move
* Setting options

It DOES NOT _yet_ support:

* 'uci' command
* ponder mode / infinite mode
* ponderhit
* registrations

## Known Issues

When connecting to more than one engine from the same code, there is a problem where their input streams get crosses. This is an issue with Open3, but for some reason turning "debug" on seems to mitigate it.

Open3 is supposed to work under in Ruby 1.9.x in Windows, but this is currently untested.

## Contributing

Ruby UCI needs support for more features and to be tested with more chess
engines.  To contribute to this project please fork the project and add/change
any new code inside of a new branch:

    git checkout -b my-new-feature

Before committing and pushing code, please make sure all existing tests pass
and that all new code has tests. Once that is verified, please push the changes
and create a new pull request.
