require('coffee-script')

express = require("express")
http = require("http")
path = require("path")

fileloader = require("loadfiles")
loadFilesFor = fileloader __dirname, 'coffee'
routes = require("./routes")
app = module.exports = express()


# all environments
app.set "views", __dirname + "/views"
app.set "view engine", "jade"
app.use express.favicon()

app.use(express.logger('dev'))
app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(__dirname, "../public"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")


# An Array with all Mongoose Model Objects
models = loadFilesFor('models')

# Require all available controllers
controllers = loadFilesFor('controllers')

# Require all available middlewares
middlewares = loadFilesFor('middlewares')

routes(app, controllers, middlewares)
