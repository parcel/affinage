express = require 'express'
_ = require 'lodash'
nconf = require 'nconf'
kew = require 'kew'
levelup = require 'level'

db = levelup './db'

nconf.argv().env().file
  file: 'config.json'
stripe = (require 'stripe') (nconf.get 'STRIPE_KEY')

class Customers
  customers: []
  graphData: []

  constructor: (@customers) ->

  # fetches all customers from stripe
  # promise with the result
  _fetch = (customers = @customers) ->
    defer = kew.defer()

    options =
      limit: 100

    if customers.length > 0
      options.starting_after = customers[customers.length - 1].id

    stripe.customers.list options, (err, res) =>
      if err
        return defer.reject err

      customers = customers.concat res.data

      # return resolved promise or recurse
      if res.has_more is true
        defer.resolve _fetch customers
      else
        defer.resolve customers

    defer

  # formats customer data into graph data
  _buildGraphData = (customers) ->
    data = []
    now = new Date().getTime()
    # create one data point for customer creation and one for churn
    for cus in customers
      if cus.subscription?
        amount = cus.subscription.plan.amount / 100
        data.push
          x: cus.created * 1000
          description: cus.description
          id: cus.id
          delta: 1
          trial_end: (cus.subscription.trial_end * 1000) or undefined

        if cus.subscription?.canceled_at?
          data.push
            x: cus.subscription.canceled_at * 1000
            description: cus.description
            id: cus.id
            delta: -1
            trial_end: (cus.subscription.trial_end * 1000) or undefined
            canceled_at: (cus.subscription.canceled_at * 1000) or undefined
      null

    # sort data points and add y axis
    count = 0
    _(data).sortBy 'x'
    .map (point) ->
      point.y = (count += point.delta)
      point
    .value()

  # updates the `customers` variable
  update: ->
    _fetch(@customers).fail (err) ->
      console.error 'Error fetching stripe customers', err
    .then (res) =>
      console.log "#{res.length - @customers.length} customers fetched from Stripe."
      @customers = res
      @graphData = _buildGraphData @customers

      db.put 'stripe_customers', JSON.stringify @customers
      res
    .fail (err) ->
      console.error 'Error processing customer data', err

customers = {}
db.get 'stripe_customers', (err, res) =>
  data =
    if res
      JSON.parse res
    else
      []

  console.log "fetched #{data.length} customers from db"

  # initial run and continue grabbing updates once in a while
  customers = new Customers data
  customers.update()
  setInterval ->
    customers.update()
  , 300 * 1000

# routes
router = express.Router()
router.get '/', (req, res) ->
  res.send customers.graphData

module.exports = router
