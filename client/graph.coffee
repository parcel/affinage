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
            point.event = 'Lost Trial'
            orange
          else
            point.event = 'Churned'
            red
        else
          if point.trial_end > now
            point.event = 'Trial'
            blue
          else
            point.event = 'Client'
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
    .forEach (point) ->
      if not point.canceled_at
        point.color = blue
        point.event = 'New Trial'
      else
        point.event = 'Lost Trial'
      # graduated clients
      if point.trial_end < now
        graduatedPoint = _.defaults
          x: point.trial_end
          delta: -1
          event: 'Converted from Trial'
          color: green
        , point
        graduatedClients.push graduatedPoint
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
    .forEach (point) ->
      if not point.canceled_at? and point.trial_end?
        point.x = point.trial_end
        point.event = 'Converted from Trial'
    .sortBy 'x'
    .forEach (point) ->
      point.y = (count += point.delta)
    .value()

  ###
  # Initialize the actual graphs
  ###

  handlePointClick = (e) ->
    url = "https://manage.stripe.com/customers/#{e.point.id}"
    window.open url, '_blank'

  pointFormat =
    '
    {series.name}: <b>{point.y}</b><br />
    {point.description}<br />
    <b>{point.event}</b>
    '

  # All time
  $('#container1').highcharts
    chart:
      type: 'line'
    plotOptions:
      line:
        color: grey
        events:
          click: handlePointClick
    title:
      text: 'Customers over time'
    credits:
      enabled: false
    tooltip:
      pointFormat: pointFormat
    yAxis: yAxis
    xAxis: xAxis
    series: [
      name: 'Signups and Churns'
      data: allClients
    ,
      name: 'Trial Clients'
      data: trialClients
    ,
      name: 'Paying Clients'
      data: paidClients
    ]

  # last 30 days graph
  monthAgo = Date.now() - 2592000000
  $('#container2').highcharts
    chart:
      type: 'line'
    plotOptions:
      line:
        color: grey
        events:
          click: handlePointClick
    credits:
      enabled: false
    tooltip:
      pointFormat: pointFormat
    yAxis: yAxis
    xAxis: xAxis
    title:
      text: 'Customers in the last 30 days'
    series: [
      name: 'Sign-ups and Churns'
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
        events:
          click: handlePointClick
    credits:
      enabled: false
    tooltip:
      pointFormat: pointFormat
    yAxis: yAxis
    xAxis: xAxis
    title:
      text: 'Customers in the last 7 days'
    series: [
      name: 'Signups and Churns'
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
