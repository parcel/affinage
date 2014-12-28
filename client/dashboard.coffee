class Dashboard
  constructor: ->
    @vm =
      graph: new Graph

  controller: ->

  view: ->
    [
      m 'div.row.container', [
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
        @vm.graph.view()
      ]
    ]

m.module document.body, new Dashboard
