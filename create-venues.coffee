require 'coffee-script'
neo4j = require 'neo4j'


venues = require "#{__dirname}/data/venues.json"

db = new neo4j.GraphDatabase 'http://localhost:7474'


venues.forEach (venue) ->
	db.query """
	CREATE (venue:Venue {
			id: {id},
			name: {name},
			address: {address_1},
			lon: {lon},
			lat: {lat},
			ratingCount: {rating_count},
			rating: {rating}
	})
	RETURN venue.name, venue.address
	""", venue, (error, result) ->
		console.log result
