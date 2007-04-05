class ChessGame < ActiveRecord::Base
	has_one :white, :classname => 'account', :foreign_key => 'id'
	has_one :black, :classname => 'account', :foreign_key => 'id'

	# Returns the winner
	def winner
		if result == 'white'
			return white
		elsif result == 'black'
			return black
		end
		nil
	end
end
