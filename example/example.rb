#!/usr/bin/env ruby

require './lib/uci'

puts "Connecting to engine."
uci = Uci.new(
  :engine => :stockfish,
  :engine_path => '/Users/mnielsen/tmp/Stockfish/src/stockfish',
  :debug => true,
  # :options => {
  #   "Hash" => 32,
  #   "NalimovCache" => 1,
  #   "NalimovPath" => "/Users/mnielsen/tmp"
  # }
)

while !uci.ready? do
  puts "Engine isn't ready yet, sleeping..."
  sleep(1)

end
puts "Engine is ready."

puts "Setting new game."
uci.new_game!
raise "Not a new game? Strange..." unless uci.new_game?


loop do
  puts "Move #{uci.moves.size}."
  puts uci.fenstring # return fenstring of current board.
  puts uci.board     # return ascii layout of current board.
  # puts uci.bestmove
  uci.go!
  sleep(0.25)
end
