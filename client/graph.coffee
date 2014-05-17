now = new Date().getTime()

# initial settings
xAxis = type: 'datetime'
yAxis =
  minPadding: 0
  maxPadding: 0
  allowDecimals: false
  alternateGridColor: '#F4F4F4'
  title:
    text: 'Total customers'


superagent.get('/api/customers').end (error, res) ->
  if error or res.status isnt 200
    console.error 'Status: ' + res.status, error
    $('#container1').text 'Status: ' + res.status + ' Message: ' + error

  grey = '#9E9E9E'
  red = '#D86353'
  green = '#89bf0a'
  orange = '#daa055'
  blue = '#68b0ef'

  # dataset for all customers (trial or not)
  allClients =
    _(res.body)
    .map (point) ->
      colour =
        if point.delta < 0
          if point.trial_end > point.canceled_at
            orange
          else
            red
        else
          if point.trial_end > now
            blue
          else
            green

      point.color = colour
      point
    .value()

  # trial client data
  count = 0
  graduatedClients = []
  trialClients =
    _(_.cloneDeep allClients)
    .filter (point) ->
      point.trial_end?
    .map (point) ->
      if not point.canceled_at
        point.color = blue
      # graduated clients
      if point.trial_end < now
        graduatedClients.push
          x: point.trial_end
          delta: -1
          color: green
      point
    .concat graduatedClients
    .sortBy (point) ->
      point.x
    .forEach (point) ->
      point.y = (count += point.delta)
    .value()

  # paid client data
  count = 0
  paidClients =
    _(_.cloneDeep allClients)
    .filter (point) ->
      not point.trial_end? or point.trial_end < now
    .value()

  ###
  # Initialize the actual graphs
  ###

  # All time
  $('#container1').highcharts
    chart:
      type: 'line'
    plotOptions:
      line:
        color: grey
    title:
      text: 'Customers over time'
    yAxis: yAxis
    xAxis: xAxis
    series: [
      name: 'All Clients'
      data: allClients
    ,
      name: 'Trial Clients'
      data: trialClients
    ,
      name: 'Paying Clients'
      data: paidClients
      visible: false
    ]

  # last 30 days graph
  monthAgo = Date.now() - 2592000000
  $('#container2').highcharts
    chart:
      type: 'line'
    plotOptions:
      line:
        color: grey
    title:
      text: 'Customers in the last 30 days'
    yAxis: yAxis
    xAxis: xAxis
    series: [
      name: 'All Clients'
      data: _.filter allClients, (point) ->
        point.x >= monthAgo
    ,
      name: 'Trial Clients'
      data: _.filter trialClients, (point) ->
        point.x >= monthAgo
    ,
      name: 'Paying Clients'
      data: _.filter paidClients, (point) ->
        point.x >= monthAgo
    ]

  # last 6 days
  weekAgo = Date.now() - 604800000
  $('#container3').highcharts
    chart:
      type: 'line'
    plotOptions:
      line:
        color: grey
    title:
      text: 'Customers in the last 7 days'
    yAxis: yAxis
    xAxis: xAxis
    series: [
      name: 'All Clients'
      data: _.filter allClients, (point) ->
        point.x >= weekAgo
    ,
      name: 'Trial Clients'
      data: _.filter trialClients, (point) ->
        point.x >= weekAgo
    ,
      name: 'Paying Clients'
      data: _.filter paidClients, (point) ->
        point.x >= weekAgo
    ]
