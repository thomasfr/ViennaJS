meetup = require 'meetup-api'
async = require 'async'
fs = require 'fs'

apiKey = "7e1571e1172177fda43547dc2a4"
groupId = "1679721"
meetupClient = meetup apiKey


module.exports.getAllMembers = getAllMembers = (callback) ->
	members = []
	offset = 0
	page = 200
	doFetch = (offset, page) ->
		meetupClient.getMembers {group_id: groupId, page: page, offset: offset}, (error, result) ->
			if error
				throw error
			else
				members = members.concat result.results
				if result.meta and result.meta.next
					offset = offset + 1
					setTimeout () ->
						doFetch offset, page
					, 1000
				else
					callback null, members
	doFetch offset, page



module.exports.getVenues = getVenues = (callback) ->
	venues = []
	offset = 0
	page = 200
	doFetch = (offset, page) ->
		meetupClient.getVenues {group_id: groupId, page: page, offset: offset}, (error, result) ->
			if error
				throw error
			else
				venues = venues.concat result.results
				if result.meta and result.meta.next
					offset = offset + 1
					setTimeout () ->
						doFetch offset, page
					, 1000
				else
					callback null, venues
	doFetch offset, page



module.exports.getEvents = getEvents = (callback) ->
	events = []
	offset = 0
	page = 200
	doFetch = (offset, page) ->
		meetupClient.getEvents {group_id: groupId, status: "upcoming,past,proposed,suggested,cancelled,draft", page: page, offset: offset}, (error, result) ->
			if error
				console.error "meetupClient.getEvents Error:", error
				throw error
			else
				events = events.concat result.results
				if result.meta and result.meta.next
					offset = offset + 1
					setTimeout () ->
						doFetch offset, page
					, 1000
				else
					callback null, events
	doFetch offset, page


module.exports.getRSVPs = getRSVPs = (eventId, callback) ->
	rsvps = []
	offset = 0
	page = 200
	doFetch = (offset, page) ->
		meetupClient.getRVSPs {event_id: eventId, page: page, offset: offset}, (error, result) ->
			if error
				console.error "meetupClient.getRSVPs Error:", error
				throw error
			else
				rsvps = rsvps.concat result.results
				if result.meta and result.meta.next
					offset = offset + 1
					setTimeout () ->
						doFetch offset, page
					, 1000
				else
					callback null, rsvps
	doFetch offset, page


async.series
	members: (callback) ->
		getAllMembers (error, members) ->
			if error
				console.error "error getting all members:", error
				callback error, null
			else
				console.log "Retrieved #{members.length} members."
				callback null, members

	venues: (callback) ->
		getVenues (error, venues) ->
			if error
				console.error "getVenues Error:", error
				callback error, null
			else
				console.log "Retrieved #{venues.length} venues."
				callback null, venues

	events: (callback) ->
		getEvents (error, events) ->
			if error
				console.error "getEvents Error:", error
				callback error, null
			else
				console.log "Retrieved #{events.length} events."
				callback null, events
, (error, results) ->
	if error
		console.error "Error getting data: ", error
		throw error
	else
		fs.writeFileSync("#{__dirname}/data/members.json", JSON.stringify(results.members), 'utf-8')
		fs.writeFileSync("#{__dirname}/data/venues.json", JSON.stringify(results.venues), 'utf-8')
		fs.writeFileSync("#{__dirname}/data/events.json", JSON.stringify(results.events), 'utf-8')
		rsvpsCount = 0
		currentEventRun = 1
		async.mapSeries results.events, (event, callback) ->
			getRSVPs event.id, (error, rsvps) ->
				if error
					console.error "Error retrieving RSVPs for #{event.id}:", error
					callback error, null
				else
					console.log "Retrieved #{rsvps.length} RSVPs for Event #{event.id} (#{currentEventRun} / #{results.events.length})"
					result = {}
					result[event.id] = rsvps
					rsvpsCount = rsvpsCount + rsvps.length
					setTimeout () ->
						currentEventRun = currentEventRun + 1
						callback(null, result)
					, 2000

		, (error, results) ->
			if error
				console.error "Error retrieving RSVPs", error
				throw error
			else
				console.log "Retrieved #{rsvpsCount} RSVPs."
				fs.writeFileSync("#{__dirname}/data/rsvps.json", JSON.stringify(results), 'utf-8')
