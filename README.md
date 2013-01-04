# Ruby UCI - A Universal Chess Interface for Ruby

The UCI gem allows for a much more ruby-like why of communicating with chess
engines that support the UCI protocol.

## Installation

Standard installation applies.  Either:

    gem install uci

..or, in a bundled project, add this line to your application's Gemfile:

    gem 'uci'

And then execute:

    $ bundle

## Usage

### NOTE: No Chess engines are included. You must install an appropriate
UCI-compatible engine first.

```ruby
 require 'rubygems'
 require 'uci'

  uci = Uci.new(
    :engine => :stockfish,
    :engine_path => '/Users/mnielsen/tmp/Stockfish/src/stockfish',
  )

  while !uci.ready? do
    puts "Engine isn't ready yet, sleeping..."
    sleep(1)
  end


  uci.new_game!

  loop do
    puts "Move ##{uci.moves.size+1}."
    puts uci.fenstring # print fenstring of current board.
    puts uci.board     # print ascii layout of current board.
    uci.go!
    sleep(0.25)
  end
 ```

## Contributing

Ruby UCI needs support for more features and to be tested with more chess
engines.  To contribute to this project please fork the project and add/change
any new code inside of a new branch:

    git checkout -b my-new-feature

Before committing and pushing code, please make sure all existing tests pass
and that all new code has tests. Once that is verified, please push the changes
and create a new pull request.
