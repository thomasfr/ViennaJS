require 'coffee-script'
wait = require 'wait.for'

group = require "#{__dirname}/data/group.json"
venues = require "#{__dirname}/data/venues.json"
events = require "#{__dirname}/data/events.json"
members = require "#{__dirname}/data/members.json"
rsvps = require "#{__dirname}/data/rsvps.json"

neo4j = require 'neo4j'
topics = []
countries = []
cities = []

db = new neo4j.GraphDatabase 'http://localhost:7474'

topics = topics.concat group.topics
countries.push group.country.toLowerCase()
cities.push
	name:    group.city.toLowerCase()
	country: group.country.toLowerCase()

migrate = () ->
	###
	groupNode = wait.for db.query """
	MERGE (group:Group {
		id: {id},
		lat: {lat},
		lon: {lon},
		name: {name},
		established: {created},
		description: {description}
	})
	ON CREATE SET group.created = timestamp()
	RETURN group
	""", group
	console.log "group", groupNode


	venues.forEach (venue) ->
		countries.push venue.country.toLowerCase()
		cities.push
			name:    venue.city.toLowerCase()
			country: venue.country.toLowerCase()
		venueNode = wait.for db.query """
		MERGE (venue:Venue {
				id: {id},
				name: {name},
				address: {address_1},
				lon: {lon},
				lat: {lat},
				ratingCount: {rating_count},
				rating: {rating}
		})
		ON CREATE SET venue.created = timestamp()
		RETURN venue
		""", venue
		console.log "venue", venueNode


	members.forEach (user) ->
		topics = topics.concat user.topics
		city = {
			name:    user.city.toLowerCase()
			country: user.country.toLowerCase()
		}
		cities.push city
		countries.push user.country.toLowerCase()
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
		if user.hometown
			query += ", hometown: {hometown}"
		if user.bio
			query += ", bio: {bio}"
		query += """
		})
		ON CREATE SET user.created = timestamp()
		RETURN user
		"""
		userNode = wait.for db.query query, user
		console.log "user", userNode


	topics.forEach (topic) ->
		topicNode = wait.for db.query """
		MERGE (topic:Topic {
			id: {id},
			name: {name},
			urlkey: {urlkey}
		})
		RETURN topic
		""", topic
		console.log topicNode


	countries.forEach (country) ->
		countryNode = wait.for db.query """
		MERGE (country:Country {
			iso2: {name}
		})
		RETURN country
		""", {name: country}
		console.log countryNode


	cities.forEach (city) ->
		cityNode = wait.for db.query """
		MERGE (city:City {
			name: {name},
			countryIso2: {country}
		})
		RETURN city
		""", city
		console.log cityNode

		result = wait.for db.query """
		MATCH (city:City {name: {name}, countryIso2: {country} }), (country:Country {iso2: {country}})
		MERGE (city)-[:locatedIn]->(country)
		RETURN city, country
		""", city
		console.log result


	members.forEach (user) ->
		result = wait.for db.query """
		MATCH (user:User{id: {id}}), (city:City{name:{city}, countryIso2: {country}})
		MERGE (user)-[:locatedIn]->(city)
		RETURN user, city
		""", user
		console.log result

		if user.topics
			user.topics.forEach (topic) ->
				result = wait.for db.query """
				MATCH (user:User{id:{user}.id}), (topic:Topic{id:{topic}.id})
				MERGE (user)-[:interestedIn]->(topic)
				RETURN user, topic
				""", {topic: topic, user: user}
				console.log result

		result = wait.for db.query """
		MATCH (user:User{id:{id}}), (group:Group{id:#{group.id}})
		MERGE (user)-[:memberOf]->(group)
		RETURN user, group
		""", user
		console.log result


	if group.topics
		group.topics.forEach (topic) ->
			result = wait.for db.query """
			MATCH (group:Group{id:{group}.id}), (topic:Topic{id:{topic}.id})
			MERGE (group)-[:isAbout]->(topic)
			RETURN group, topic
			""", {group: group, topic: topic}
			console.log result

	events.forEach (event) ->
		eventNode = wait.for db.query """
		MERGE (event:Event {
			id: {id},
			meetupEventUrl: {event_url},
			name: {name},
			description: {description},
			status: {status},
			time: {time}
		})
		RETURN event
		""", event
		console.log eventNode

		result = wait.for db.query """
		MATCH (event:Event{id:{id}}), (venue:Venue{id:{venue}.id}), (group:Group{id:{group}.id})
		MERGE (group)<-[:hostedBy]-(event)-[:takesPlaceAt]->(venue)
		RETURN group, event, venue
		""", event
		console.log result


	venues.forEach (venue) ->
		result = wait.for db.query """
		MATCH (venue:Venue{id:{id}}), (city:City{name:{city}})
		MERGE (venue)-[:locatedIn]->(city)
		RETURN venue, city
		""", venue
		console.log result
	###
	rsvps.forEach (rsvpObject) ->
		eventIds = Object.keys rsvpObject
		eventId = eventIds[0]
		eventRsvps = rsvpObject[eventId]
		eventRsvps.forEach (rsvp) ->
			query = """
			MATCH (event:Event{id:"#{eventId}"}), (user:User{id:#{rsvp.member.member_id}})
			"""
			if rsvp.response is "yes"
				query += " MERGE (user)-[r:attending]->(event)"
			else if rsvp.response is "no"
				query += " MERGE (user)-[r:notAttending]->(event)"
			else if rsvp.response is "maybe"
				query += " MERGE (user)-[r:maybeAttending]->(event)"
			else if rsvp.response is "waitlist"
				query += " MERGE (user)-[r:waitlist]->(event)"
			query += " RETURN event, type(r), user"
			result = wait.for db.query query, rsvp
			console.log result


wait.launchFiber migrate
