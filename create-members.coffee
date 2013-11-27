require 'coffee-script'
neo4j = require 'neo4j'


members = require "#{__dirname}/data/members.json"

db = new neo4j.GraphDatabase 'http://localhost:7474'


members.forEach (user) ->
	query = """
	MERGE (user:User {
		id: {id},
		name: {name},
		joined: {joined},
		language: {lang},
		status: {status},
		meetupProfileUrl: {link}
	"""
	if user.lat
		query += ", lat: {lat}"
	if user.lon
		query += ", lon: {lon}"
	if user.photo and user.photo.photo_link
		query += ", photoUrl: {photo}.photo_link"
	if user.bio
		query += ", bio: {bio}"

	query += "}) RETURN user"
	db.query query, user, (error, result) ->
		console.log result
