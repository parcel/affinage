Highcharts.setOptions
  global:
    timezoneOffset: new Date().getTimezoneOffset()

dashboard =
  vm:
    init: ->
      dashboard.vm.graphData = m.prop {}
      dashboard.loadGraphData dashboard.vm.graphData

  renderGraph: (ele, thing, context) ->
    grey = '#9E9E9E'
    red = '#D86353'
    green = '#89bf0a'
    orange = '#daa055'
    blue = '#68b0ef'

    ###
    # generate the 3 datasets
    ###

    # all customers (trial or not)
    allClients =
      _(dashboard.vm.graphData())
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
            if point.trial_end > Date.now()
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
        point.trial_end? and point.event isnt 'Churned'
      .forEach (point) ->
        if not point.canceled_at
          point.color = blue
          point.event = 'New Trial'
        # graduated trial clients
        if point.trial_end < Date.now()
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
        not point.trial_end? or point.trial_end < Date.now()
      .forEach (point) ->
        if not point.canceled_at? and point.trial_end?
          point.x = point.trial_end
          point.event = 'Converted from Trial'
      .sortBy 'x'
      .forEach (point) ->
        point.y = (count += point.delta)
      .value()

    ###
    # Initialize the actual graph
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

    chart = new Highcharts.Chart
      chart:
        renderTo: ele
        type: 'line'
        zoomType: 'x'
      plotOptions:
        line:
          color: grey
          events:
            click: handlePointClick
          turboThreshold: 0
      title:
        text: 'Customers over time'
      credits:
        enabled: false
      tooltip:
        pointFormat: pointFormat
        xDateFormat: '%l:%M%P, %b %d, %Y'
      yAxis:
        minPadding: 0
        maxPadding: 0
        allowDecimals: false
        alternateGridColor: '#F4F4F4'
        title:
          text: 'Clients'
      xAxis:
        type: 'datetime'
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

  loadGraphData: (data) ->
    m.request
      method: 'GET'
      url: '/api/customers'
    .then (res) ->
      console.log res
      data res

  controller: ->
    dashboard.vm.init()

  view: ->
    m 'div.container', [
      m 'div.row', [
        m 'div.one-half.column', [
          m 'fieldset', [
            m 'input[type="date"]'
            m 'input[type="date"]'
          ]
        ]
        m 'div.one-half.column', [
          m 'button', 'All time'
          m 'button', 'Last 30 days'
          m 'button', 'Last 7 days'
        ]
      ]
      m 'div.row', [
        m 'div', config: dashboard.renderGraph
      ]
    ]

m.module document.body, dashboard

load = (callback) ->
  superagent.get('/api/customers').end (error, res) ->
    if error or res.status isnt 200
      console.error 'Status: ' + res.status, error
      $('#container1').text 'Status: ' + res.status + ' Message: ' + error

    if res.body.length is 0
      callback? true
      return
    else
      callback? false

    ###
    # date picker events
    ###
    graph = $('.js-customer-graph').highcharts()

    minDatePicker = $('.js-min-date').pickadate
      max: Date.now()
      onStart: ->
        this.set 'select', graph.xAxis[0].min, muted: true
      onSet: (val) ->
        if val.select?
          graph.xAxis[0].update
            min: val.select
    .pickadate 'picker'

    maxDatePicker = $('.js-max-date').pickadate
      max: Date.now()
      onStart: ->
        this.set 'select', graph.xAxis[0].max, muted: true
      onSet: (val) ->
        if val.select?
          graph.xAxis[0].update
            max: val.select
    .pickadate 'picker'

    ###
    # Buttons events
    ###
    minDate = graph.xAxis[0].min
    maxDate = graph.xAxis[0].max

    $('.js-time-all').click (e) ->
      minDatePicker.set 'select', minDate
      maxDatePicker.set 'select', maxDate

    $('.js-time-30').click (e) ->
      now = Date.now()
      minDatePicker.set 'select', now - 2592000000
      maxDatePicker.set 'select', now

    $('.js-time-7').click (e) ->
      now = Date.now()
      minDatePicker.set 'select', now - 604800000
      maxDatePicker.set 'select', now

#interval = setInterval ->
  #load (retry) ->
    #unless retry then clearInterval interval
#, 5000

#load (retry) ->
  #unless retry then clearInterval interval
