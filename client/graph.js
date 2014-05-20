// Generated by CoffeeScript 1.7.1
(function() {
  var blue, green, grey, orange, red;

  grey = '#9E9E9E';

  red = '#D86353';

  green = '#89bf0a';

  orange = '#daa055';

  blue = '#68b0ef';

  superagent.get('/api/customers').end(function(error, res) {
    var allClients, count, graduatedClients, graph, handlePointClick, maxDate, maxDatePicker, minDate, minDatePicker, paidClients, pointFormat, trialClients;
    if (error || res.status !== 200) {
      console.error('Status: ' + res.status, error);
      $('#container1').text('Status: ' + res.status + ' Message: ' + error);
    }

    /*
     * generate the 3 datasets
     */
    allClients = _(res.body).map(function(point) {
      var colour;
      colour = point.delta < 0 ? point.trial_end > point.canceled_at ? (point.event = 'Lost Trial', orange) : (point.event = 'Churned', red) : point.trial_end > Date.now() ? (point.event = 'Trial', blue) : (point.event = 'Client', green);
      point.color = colour;
      return point;
    }).value();
    count = 0;
    graduatedClients = [];
    trialClients = _(_.cloneDeep(allClients)).filter(function(point) {
      return (point.trial_end != null) && point.event !== 'Churned';
    }).forEach(function(point) {
      var graduatedPoint;
      if (!point.canceled_at) {
        point.color = blue;
        point.event = 'New Trial';
      }
      if (point.trial_end < Date.now()) {
        graduatedPoint = _.defaults({
          x: point.trial_end,
          delta: -1,
          event: 'Converted from Trial',
          color: green
        }, point);
        return graduatedClients.push(graduatedPoint);
      }
    }).concat(graduatedClients).sortBy(function(point) {
      return point.x;
    }).forEach(function(point) {
      return point.y = (count += point.delta);
    }).value();
    count = 0;
    paidClients = _(_.cloneDeep(allClients)).filter(function(point) {
      return (point.trial_end == null) || point.trial_end < Date.now();
    }).forEach(function(point) {
      if ((point.canceled_at == null) && (point.trial_end != null)) {
        point.x = point.trial_end;
        return point.event = 'Converted from Trial';
      }
    }).sortBy('x').forEach(function(point) {
      return point.y = (count += point.delta);
    }).value();

    /*
     * Initialize the actual graph
     */
    handlePointClick = function(e) {
      var url;
      url = "https://manage.stripe.com/customers/" + e.point.id;
      return window.open(url, '_blank');
    };
    pointFormat = '{series.name}: <b>{point.y}</b><br /> {point.description}<br /> <b>{point.event}</b>';
    $('.js-customer-graph').highcharts({
      chart: {
        type: 'line'
      },
      plotOptions: {
        line: {
          color: grey,
          events: {
            click: handlePointClick
          }
        }
      },
      title: {
        text: 'Customers over time'
      },
      credits: {
        enabled: false
      },
      tooltip: {
        pointFormat: pointFormat
      },
      yAxis: {
        minPadding: 0,
        maxPadding: 0,
        allowDecimals: false,
        alternateGridColor: '#F4F4F4',
        title: {
          text: 'Clients'
        }
      },
      xAxis: {
        type: 'datetime'
      },
      series: [
        {
          name: 'Signups and Churns',
          data: allClients
        }, {
          name: 'Trial Clients',
          data: trialClients
        }, {
          name: 'Paying Clients',
          data: paidClients
        }
      ]
    });

    /*
     * date picker events
     */
    graph = $('.js-customer-graph').highcharts();
    minDatePicker = $('.js-min-date').pickadate({
      max: Date.now(),
      onStart: function() {
        return this.set('select', graph.xAxis[0].min, {
          muted: true
        });
      },
      onSet: function(val) {
        if (val.select != null) {
          return graph.xAxis[0].update({
            min: val.select
          });
        }
      }
    }).pickadate('picker');
    maxDatePicker = $('.js-max-date').pickadate({
      max: Date.now(),
      onStart: function() {
        return this.set('select', graph.xAxis[0].max, {
          muted: true
        });
      },
      onSet: function(val) {
        if (val.select != null) {
          return graph.xAxis[0].update({
            max: val.select
          });
        }
      }
    }).pickadate('picker');

    /*
     * Buttons events
     */
    minDate = graph.xAxis[0].min;
    maxDate = graph.xAxis[0].max;
    $('.js-time-all').click(function(e) {
      minDatePicker.set('select', minDate);
      return maxDatePicker.set('select', maxDate);
    });
    $('.js-time-30').click(function(e) {
      var now;
      now = Date.now();
      minDatePicker.set('select', now - 2592000000);
      return maxDatePicker.set('select', now);
    });
    return $('.js-time-7').click(function(e) {
      var now;
      now = Date.now();
      minDatePicker.set('select', now - 604800000);
      return maxDatePicker.set('select', now);
    });
  });

}).call(this);
