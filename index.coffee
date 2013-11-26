require('coffee-script')

express = require("express")
app = express()
app.use "/", require("./app")

port = process.env.APP_PORT or 3000
app.listen port, ->
	console.log "Listening on https://localhost:" + port



