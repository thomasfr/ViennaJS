venues = require "#{__dirname}/venues.json"
events = require "#{__dirname}/events.json"

neo4j = require 'neo4j'

db = new neo4j.GraphDatabase 'http://localhost:7474'

###
venues.forEach (venue) ->
	db.query """
	CREATE (n {
			id: {id},
			name: {name},
			address: {address_1},
			long: {lon},
			lat: {lat},
			ratingCount: {rating_count},
			rating: {rating},
			city: {city},
			country: {country}}
	)
	""", venue, (error, results) ->
		console.log results, error
###


db.query """
CREATE (n { props })
RETURN n
""", {props: [
	{name: "Andres", position: "Developer"},
	{name: "Michael", position: "Developer"}
]}, (error, results) ->
	console.log results, error

###
events.forEach (event) ->
	db.query """
	CREATE (event {
			id: {id},
			name: {name},
			description: {description}
			}
	)
	""", event, (error, results) ->
		console.log results, error
###
