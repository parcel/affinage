express = require 'express'
compression = require 'compression'
auth = require 'basic-auth'

app = express()

module.exports = server = (port = 8082) ->
  app.use compression()

  router = express.Router()

  # basic auth
  router.all '*', (req, res, next) ->
    creds = auth req
    if creds?.name is '10sheet' and creds?.pass is 'benchco'
      next()
    else
      res.set 'WWW-Authenticate', 'Basic'
      res.send 401, 'no.'

  router.use '/api/customers', require './customers'
  app.use router

  app.use express.static 'client/'

  app.listen port
  console.info "Affinage listening on #{port}"
