require 'coffee-script'
neo4j = require 'neo4j'


group = require "#{__dirname}/data/group.json"

db = new neo4j.GraphDatabase 'http://localhost:7474'


db.query """
CREATE (group:Group {
	id: {id},
	lat: {lat},
	lon: {lon},
	name: {name},
	established: {created},
	description: {description}
})
RETURN group.name, group.description
""", group, (error, result) ->
	console.log "group", result
