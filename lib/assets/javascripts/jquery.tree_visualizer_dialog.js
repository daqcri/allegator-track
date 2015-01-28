(function($){
  $.fn.tree_visualizer_dialog = function(options){
    var obj = this
    var _

    var initialized = obj.data("__tree_visualizer_dialog_initialized")

    if (initialized) {
      _ = obj.data("__tree_visualizer_dialog_data")
      $.extend(_.settings, options)
    }
    else {
      obj.data("__tree_visualizer_dialog_initialized", true)

      _ = {
        obj_id: obj.attr("id"),
        chart_id: "chart_" + obj.attr("id"),
        // defaults
        settings: $.extend({
          run_id: 0,
          claim_id: 0,
          metrics: {},
          title: 'Set algorithm here'
        }, options),
        load: function() {
          $.ajax({
            url: "/runs/"+ _.settings.run_id +"/explain.xml",
            dataType: 'xml',
            success: function(response){
              console.log("response: ", response, response.documentElement)
              $('.spinner', obj).hide()
              var json
              if (json = _.parse(response.documentElement)){
                console.log("parsed josn", json)
                if (!_.createTreeVizChart(json, "#"+_.chart_id))
                  _.showError("invalid json") // 4. invalid json
              }
              else
                _.showError("invalid xml") // 3. couldn't parse xml to json
            }
          })
          .fail(function(){
            _.showError("server failed")
          })  // 1. server failed
        },
        parse: function(node) {
          console.log("parsing node: ", node)
          if (node.nodeName == 'Output') { // leaf
            var $node = $(node), values = $node.attr("info")
            values = values.substr(1, values.length-2).split("/")
            return {type: "leaf", error: $node.attr("decision") == "TRUE" ? 0 : 1, samples: 1, value: values}
          } else if (node.nodeName == 'Test' || node.nodeName == 'DecisionTree') {
            var children = [], $node = $(node)
            var label = node.nodeName == 'DecisionTree' ? "Claim " + _.settings.claim_id : $node.attr("attribute") + $node.attr("operator") + $node.attr("value")
            $.each(node.childNodes, function(id, child){
                var child_json = _.parse(child)
                if (child_json) children.push(child_json)
            })
            return {type: "split", label: label, error: 0.0, samples: 1, value: [1], children: children}
          } else {
            // text/unknown node
            return null;
          }
        },
        showError: function(code) {
          $("#"+_.chart_id).html("Couldn't load decision tree [error code: "+code+"]")
        },
        createTreeVizChart: function(json, selector) {
          var vis = d3.select(selector).append("svg:svg")
              .attr("width", w + m[1] + m[3])
              .attr("height", h + m[0] + m[2] + 1000)
            .append("svg:g")
              .attr("transform", "translate(" + m[3] + "," + m[0] + ")");

          root = json;
          root.x0 = 0;
          root.y0 = 0;

          var n_samples = root.samples;
          if (root.value)
            var n_labels = root.value.length;
          else
            return false

          if (n_labels >= 2) {
            stroke_callback = mix_colors;
          } else if (n_labels === 1) {
            stroke_callback = mean_interpolation(root);
          }

          link_stoke_scale = d3.scale.linear()
                                     .domain([0, n_samples])
                                     .range([min_link_width, max_link_width]);

          function toggleAll(d) {
            if (d && d.children) {
              d.children.forEach(toggleAll);
              toggle(d);
            }
          }

          // Initialize the display to show a few nodes.
          root.children.forEach(toggleAll);

          update(root, vis);
          return true;
        }
      }
      obj.data("__tree_visualizer_dialog_data", _)

      // vendor init
      var m = [20, 120, 20, 120],
          w = 1280 - m[1] - m[3],
          h = 800 - m[0] - m[2],
          i = 0,
          rect_width = 120,
          rect_height = 20,
          max_link_width = 20,
          min_link_width = 1.5,
          char_to_pxl = 6,
          root;

      var tree = d3.layout.tree()
          .size([h, w]);

      var diagonal = d3.svg.diagonal()
          .projection(function(d) { return [d.x, d.y]; });

      // global scale for link width
      var link_stoke_scale = d3.scale.linear();

      var color_map = d3.scale.category10();

      // stroke style of link - either color or function
      var stroke_callback = "#ccc";

      function update(source, vis) {
        var duration = d3.event && d3.event.altKey ? 5000 : 500;

        // Compute the new tree layout.
        var nodes = tree.nodes(root).reverse();

        // Normalize for fixed-depth.
        nodes.forEach(function(d) { d.y = d.depth * 180; });

        // Update the nodes…
        var node = vis.selectAll("g.node")
            .data(nodes, function(d) { return d.id || (d.id = ++i); });

        // Enter any new nodes at the parent's previous position.
        var nodeEnter = node.enter().append("svg:g")
            .attr("class", "node")
            .attr("transform", function(d) { return "translate(" + source.x0 + "," + source.y0 + ")"; })
            .on("click", function(d) { toggle(d); update(d, vis); });

        nodeEnter.append("svg:rect")
            .attr("x", function(d) {
              var label = node_label(d);
              var text_len = label.length * char_to_pxl;
              var width = d3.max([rect_width, text_len])
              return -width / 2;
            })
            .attr("width", 1e-6)
            .attr("height", 1e-6)
            .attr("rx", function(d) { return d.type === "split" ? 2 : 0;})
            .attr("ry", function(d) { return d.type === "split" ? 2 : 0;})
            .style("stroke", function(d) { return d.type === "split" ? "steelblue" : "olivedrab";})
            .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

        nodeEnter.append("svg:text")
            .attr("dy", "12px")
            .attr("text-anchor", "middle")
            .text(node_label)
            .style("fill-opacity", 1e-6);

        // Transition nodes to their new position.
        var nodeUpdate = node.transition()
            .duration(duration)
            .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

        nodeUpdate.select("rect")
            .attr("width", function(d) {
              var label = node_label(d);
              var text_len = label.length * char_to_pxl;
              var width = d3.max([rect_width, text_len])
              return width;
            })
            .attr("height", rect_height)
            .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

        nodeUpdate.select("text")
            .style("fill-opacity", 1);

        // Transition exiting nodes to the parent's new position.
        var nodeExit = node.exit().transition()
            .duration(duration)
            .attr("transform", function(d) { return "translate(" + source.x + "," + source.y + ")"; })
            .remove();

        nodeExit.select("rect")
            .attr("width", 1e-6)
            .attr("height", 1e-6);

        nodeExit.select("text")
            .style("fill-opacity", 1e-6);

        // Update the links
        var link = vis.selectAll("path.link")
            .data(tree.links(nodes), function(d) { return d.target.id; });

        // Enter any new links at the parent's previous position.
        link.enter().insert("svg:path", "g")
            .attr("class", "link")
            .attr("d", function(d) {
              var o = {x: source.x0, y: source.y0};
              return diagonal({source: o, target: o});
            })
            .transition()
            .duration(duration)
            .attr("d", diagonal)
            .style("stroke-width", function(d) {return link_stoke_scale(d.target.samples);})
            .style("stroke", stroke_callback);

        // Transition links to their new position.
        link.transition()
            .duration(duration)
            .attr("d", diagonal)
            .style("stroke-width", function(d) {return link_stoke_scale(d.target.samples);})
            .style("stroke", stroke_callback);

        // Transition exiting nodes to the parent's new position.
        link.exit().transition()
            .duration(duration)
            .attr("d", function(d) {
              var o = {x: source.x, y: source.y};
              return diagonal({source: o, target: o});
            })
            .remove();

        // Stash the old positions for transition.
        nodes.forEach(function(d) {
          d.x0 = d.x;
          d.y0 = d.y;
        });
      }

      // Toggle children.
      function toggle(d) {
        if (d.children) {
          d._children = d.children;
          d.children = null;
        } else {
          d.children = d._children;
          d._children = null;
        }
      }

      // Node labels
      function node_label(d) {
        if (d.type === "leaf") {
          // leaf
          var formatter = d3.format(".2f");
          var vals = [];
          d.value.forEach(function(v) {
              vals.push(formatter(v));
          });
          return "[" + vals.join(", ") + "]";
        } else {
          // split node
          return d.label;
        }
      }

      /**
       * Mixes colors according to the relative frequency of classes.
       */
      function mix_colors(d) {
        var value = d.target.value;
        var sum = d3.sum(value);
        var col = d3.rgb(0, 0, 0);
        value.forEach(function(val, i) {
          var label_color = d3.rgb(color_map(i));
          var mix_coef = val / sum;
          col.r += mix_coef * label_color.r;
          col.g += mix_coef * label_color.g;
          col.b += mix_coef * label_color.b;
        });
        return col;
      }


      /**
       * A linear interpolator for value[0].
       *
       * Useful for link coloring in regression trees.
       */
      function mean_interpolation(root) {

        var max = 1e-9,
            min = 1e9;

        function recurse(node) {
          if (node.value[0] > max) {
            max = node.value[0];
          }

          if (node.value[0] < min) {
            min = node.value[0];
          }

          if (node.children) {
            node.children.forEach(recurse);
          }
        }
        recurse(root);

        var scale = d3.scale.linear().domain([min, max])
                                     .range(["#2166AC","#B2182B"]);

        function interpolator(d) {
          return scale(d.target.value[0]);
        }

        return interpolator;
      }
    }

    // render html
    obj.empty().html("<span class='spinner'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span><p id='"+
      _.chart_id+"' class='tree_viz'></p><div class='metrics'></div>")
    
    // make dialog
    obj.dialog({
      width: 1000,
      height: 1000,
      title: _.settings.title
    })

    // print metrics
    var html = "<p>Claim "+_.settings.claim_id+" metrics</p><ul>"
    $.each(_.settings.metrics, function(key, val){
      html += "<li>" + key + ": " + val + "</li>"
    })
    html += "</ul>"
    $(".metrics", obj).html(html)

    // load chart
    _.load()

    // chaining
    return obj
  }
}(jQuery))
//<span class="status_indicator">&nbsp;&nbsp;&nbsp;</span>
