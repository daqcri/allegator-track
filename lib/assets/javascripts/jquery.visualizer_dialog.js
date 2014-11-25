(function($){
  $.fn.visualizer_dialog = function(options){
    var obj = this
    var _

    var initialized = obj.data("__visualizer_dialog_initialized")

    if (initialized) {
      _ = obj.data("__visualizer_dialog_data")
      $.extend(_.settings, options)
    }
    else {
      obj.data("__visualizer_dialog_initialized", true)

      _ = {
        obj_id: obj.attr("id"),
        chart_id: "chart_" + obj.attr("id"),
        // defaults
        settings: $.extend({
          run_id: 0,
          title: 'Set algorithm here'
        }, options),
        refresh: function()
        {
        },
      }
      obj.data("__visualizer_dialog_data", _)
    }

    // render html
    obj.empty().html("<span class='spinner'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><p id='"+
      _.chart_id+"' class='sankey'></p>")
    
    // make dialog
    obj.dialog({
      width: 400,
      height: 400,
      title: _.settings.title
    })

    // load chart
    $.getJSON("/runs/"+ _.settings.run_id +"/visualize", function(response){
      $('.spinner', obj).hide()
      // $('.chart', obj).empty()
      createChart(response, "#"+_.chart_id) // TODO modify function to accept jquery object not selector
    })

    // chaining
    return obj
  }
}(jQuery))
//<span class="status_indicator">&nbsp;&nbsp;&nbsp;</span>
