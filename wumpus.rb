#!/usr/bin/env ruby
#
#	Hunt the Wumpus
#	Metaprogramming Edition
#
#	By RC Howe
#	http://www.rchowe.com
#

# The method that starts the game
def let_the_hunt_begin
	
	# The two functions we're going to use
	# Dynamically defines a method on Object
	def defn symbol, &block
		self.class.send :define_method, symbol, &block
	end
	
	# Dynamically undefines a method on Object
	def undefn symbol
		self.class.send :remove_method, symbol
	end
	
	def undefn_each arr
		arr.each do |j|
			begin
				undefn j
			rescue
			end
		end
	end
	
	# Generates a random symbol
	def generate_symbol
		sym = (0...4).map{65.+(rand(25)).chr}.join.downcase.to_sym
		if Object.methods.include? sym
			generate_symbol
		else
			sym
		end
	end
	
	# Check if a game's already running
	if $game_running
		print 'Would you like to quit? [y/n] '
		exit if gets.chomp.downcase == 'y'
		return
	end
	
	# The game is now running
	$game_running = true
	
	# Each 'cavern' is a node, represented by an array
	nodes = []
	nodes = (1..20).map { generate_symbol }.uniq while nodes.length < 20
	
	# Put hazards and descriptions into nodes
	descriptions = [:wumpus, :pit, :smelly, :clean, :grimy, :mucky, :muddy,
	                :large, :small, :wide, :wet, :stuffy, :overgrown, :warm,
	                :cold, :red, :green, :blue, :yellow, :purple ]
	nodes = nodes.zip descriptions.shuffle
	
	# The first node is the one the player will climb down into.
	# Therefore, we shuffle until there is nothing dangerous there
	# and replace whatever is there with the ladder
	nodes.shuffle! while [:wumpus, :pit].include? nodes[0][1]
	
	# Game over
	defn :game_over do |str|
		puts <<-EOF

   \033[1m#{str}\033[0m.

   If you would like to play again, call \033[1mlet_the_hunt_begin\033[0m.
   
EOF
		$game_running = false
		undefn_each nodes.map { |node| node[0] }
		undefn :shoot
	end
	
	# Let the user shoot
	defn :shoot do |node|
		
		# Check if it's a valid node
		ns = nodes.reject { |x| x[0] != node }
		
		# If it's not valid
		if ns.nil? or ns.empty?
			game_over "You shot the wall!"
		
		# If you shot the wumpus
		elsif ns.first[1] == :wumpus
			game_over "You \033[32mshot the Wumpus!\033[0m."
		
		# If you didn't shoot the wumpus
		else
			game_over "You wasted your only bullet."
		end
	end
	
	# Explain the situation to the user
	puts <<-EOF

   You are deep in the Caves of Closure, hunting the mysterious Wumpus.
   You have a gun (called with \033[1mshoot(cavern_id)\033[0m) with one bullet. Use it well.
   
   You are in a cavern with a ladder, leading to cavern \033[1m#{nodes[0][0]}\033[0m.
   Call the function (by typing it's name) \033[1m#{nodes[0][0]}\033[0m to climb down the ladder
   and enter the first cavern.
   
    EOF
	
	# The definer, an object which creates and destroys caverns.
	definer = lambda do |index, &block|
		
		# Determine which nodes are adjacent
		adjacent_indicies = [(index + 19) % 20, (index + 1) % 20,
							 (index + 4) % 20, (index + 16) % 20]
		adjacent_nodes = adjacent_indicies.map { |x| nodes[x] }
		adjacents = Hash[ adjacent_indicies.zip adjacent_nodes ]
		
		# Define the given cavern as a function with the node name
		defn nodes[index][0] do
			
			# This node
			node = nodes[index]
			
			# Call the 'teardown' method of the previous node, if given
			block.call unless block.nil?
			
			# Define the new method for each adjacent node
			adjacents.each do |i, n|
				definer.call i do
					undefn_each adjacent_nodes.map { |x| x[0] }
				end 
			end
			
			# Describe the chamber to the user
			if [:wumpus, :pit, :ladder].include? node[1]
				print "\n   You have entered a chamber with a #{node[1]} in it."
			else
				print "\n   You have entered a #{node[1]} chamber."
			end
			
			# If the player entered a bad chamber...
			case node[1]
			when :wumpus
				game_over "\033[31mThe wumpus ate you\033[0m"
				return
			when :pit
				game_over "You have fallen into a pit"
				return
			end
			
			# Look in the adjacent chambers for a wumpus or pit
			if adjacent_nodes.inject(false) { |a, n| (a | (n[1] == :wumpus)) }
				print " There is \033[31;1mblood on the walls\033[0m."
			end
			if adjacent_nodes.inject(false) { |a, n| (a | (n[1] == :pit)) }
				print " You feel a \033[34;1mbreeze\033[0m."
			end
			print "\n"
			
			# Inform the user of the tunnels
			puts "\n   There are tunnels to " +
				adjacent_nodes[0..adjacent_nodes.length-2].map { |x| "\033[1m#{x[0]}\033[0m" }.join(', ') +
				", and " + "\033[1m#{adjacent_nodes[adjacent_nodes.length-1][0]}\033[0m.\n\n"
			
			# Return the tunnel ids
			adjacent_nodes.map { |n| n[0] }[0..adjacent_nodes.length-1]
		end
	end
	
	definer.call 0
	return nodes[0][0]
end

# Inform the user of the game
print <<-EOF

        Hunt the
        _  _  _   _     _   _______    _____    _     _   _________
        |  |  |   |     |   |  |  |   |_____]   |     |   |______
        |__|__|   |_____|   |  |  |   |         |_____|   ______|

                                          Metaprogramming Edition
  
  
   Welcome to Hunt the Wumpus! Call \033[1mlet_the_hunt_begin\033[0m to start.

EOF
