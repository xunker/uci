# Ruby UCI - A Universal Chess Interface for Ruby

The UCI gem allows for a much more ruby-like way of communicating with chess
engines that support the UCI protocol.

## Installation

Standard installation applies.  Either:

    gem install uci

..or, in a bundled project, add this line to your application's Gemfile:

    gem 'uci'

And then execute:

    $ bundle

## Usage

### NOTE: No Chess engines are included. You must install an appropriate UCI-compatible engine first.

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

## Supported Engines

In theory it can support any UCI-compatible (except for conditions outlined in the 'caveats' section).  It has been tested with:

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

## Contributing

Ruby UCI needs support for more features and to be tested with more chess
engines.  To contribute to this project please fork the project and add/change
any new code inside of a new branch:

    git checkout -b my-new-feature

Before committing and pushing code, please make sure all existing tests pass
and that all new code has tests. Once that is verified, please push the changes
and create a new pull request.
