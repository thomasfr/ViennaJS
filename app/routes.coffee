require('coffee-script')

routes = module.exports = (app, controllers, middleware) ->
	app.get "/", controllers.index.get
