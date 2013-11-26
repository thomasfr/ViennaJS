require('coffee-script')

index = module.exports = {}
index.get = (request, response, next) ->
	response.render "index", {}
