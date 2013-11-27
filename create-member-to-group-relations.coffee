require 'coffee-script'
neo4j = require 'neo4j'


db = new neo4j.GraphDatabase 'http://localhost:7474'

db.query """
MATCH (member:User), (group:Group{id:1679721})
CREATE (member)-[:memberOf]->(group)
RETURN member.name, group.name
""", (error, result) ->
	console.log arguments
