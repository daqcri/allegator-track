function TreeVisualizer(xml_url, json_url, selector, callback)
{
  init()

  var metricsMapping = {
    "Cv": "cv",
    "Ts": "ts",
    "minTs": "min_ts",
    "maxTs": "max_ts",
    "NumberSuppSources": "number_supp_sources",
    "NumberOppSources": "number_opp_sources",
    "TotalSources": "total_sources",
    "NumberDistinctValue": "number_distinct_value",
    "CvGlobal": "cv_global",
    "LocalConfidenceComparison": "local_confidence_comparison",
    "TsGlobal": "ts_global",
    "TsLocal": "ts_local"
  }

  var metrics = {}

  function parse(node, matchingPath, isLeft)
  {
    if (!node.nodeName == 'Test' && !node.nodeName == 'DecisionTree')
      return null;
    // get Test/Output children, assuming max of 2 and min of 1 (we stop before reaching the leaf nodes)
    var validCildren = $.grep(node.childNodes, function(child){
      return child.nodeName == 'Test' || child.nodeName == 'Output'
    })
    if (validCildren.length == 2) {
      // split node
      var $node = $(validCildren[0])
      var attribute = $node.attr("attribute")
      var condition = {operator: $node.attr("operator"), value: $node.attr("value")}
      var otherOperator = $(validCildren[1]).attr("operator")
      var ret = {type: "split", label: attribute, condition: condition, otherOperator: otherOperator, isLeft: isLeft}
      
      // test the condition with the current claim
      ret.actualValue = metrics[metricsMapping[attribute]]
      var goLeft = null
      switch(condition.operator) {
        case "<=":
          ret.goLeft = ret.actualValue <= condition.value
        break;
        case "<":
          ret.goLeft = ret.actualValue < condition.value
        break;
        case ">=":
          ret.goLeft = ret.actualValue >= condition.value
        break;
        case ">":
          ret.goLeft = ret.actualValue > condition.value
        break;
        case "==":
          ret.goLeft = ret.actualValue == condition.value
        break;
        case "!=":
          ret.goLeft = ret.actualValue != condition.value
        break;
      }

      ret.children = $.map(validCildren, function(child, childIndex){
        // pass true to either of the 2 children keeping track of the matching path
        if (childIndex == 0)
          return parse(child, ret.goLeft && matchingPath, true)
        else
          return parse(child, !ret.goLeft && matchingPath, false)
      })
      ret.samples = ret.children[0].samples + ret.children[1].samples
      ret.error = ret.children[0].error + ret.children[1].error
      ret.value = [ret.children[0].value[0] + ret.children[1].value[0], ret.children[0].value[1] + ret.children[1].value[1]]

      return ret
    }
    else {
      // leaf node, assume validChildren.length == 1
      var $node = $(validCildren[0]), info = $node.attr("info")
      info = info.substr(1, info.length-2).split("/")
      var samples = parseInt(info[0]), error = 0
      if (info.length > 1)
        error = parseInt(info[1])
      var decision = $node.attr("decision")
      var value = decision == 'TRUE' ? [samples, 0] : [0, samples]
      return {type: "leaf", error: error, samples: samples, value: value,
        label: decision, claimLabel: metrics.label, matchingPath: matchingPath, isLeft: isLeft}
    }
  }

  function createTreeVizChart(json, selector)
  {
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
      if (n_labels === 2)
        color_map = d3.scale.ordinal().domain([0, 1]).range(["#00ff00","#ff0000"]) // green & red
      else
        color_map = d3.scale.category10();
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

    function toggleIf(d) {
      if (d.goLeft === true)
        toggleIf(d._children[0])
      else if (d.goLeft === false)
        toggleIf(d._children[1])
      else
        return; // should not happen, otherwise tree is not well constructed
      toggle(d)
    }

    // Initialize the display to collapse all
    toggleAll(root);

    // // Expand only the semantic path of that claim
    toggleIf(root)

    update(root, vis);
    return true;
  }

  // vendor init
  var m = [20, 120, 20, 120],
      w = 1280 - m[1] - m[3],
      h = 800 - m[0] - m[2],
      i = 0,
      rect_height = 30,
      max_link_width = 20,
      min_link_width = 1.5,
      char_to_pxl = 8,
      node_padding = 4,
      root;

  var tree = d3.layout.tree()
      .size([h, w]);

  var diagonal = d3.svg.diagonal()
      .projection(function(d) { return [d.x, d.y]; });

  // global scale for link width
  var link_stoke_scale = d3.scale.linear();

  var color_map;

  // stroke style of link - either color or function
  var stroke_callback = "#ccc";


  function init()
  {
    $.getJSON(json_url, function(response){
      metrics = response.metrics
      var text = response.text
      $.ajax({
        url: xml_url,
        dataType: 'xml',
        success: function(response){
          var json
          if (!response)
            callback({error: "."}) // empty response
          else if (json = parse(response.documentElement, true, true)){
            // console.log("parsed josn", json)
            if (createTreeVizChart(json, selector))
              callback({text: text})
            else
              callback({error: "invalid json"}) // 4. invalid json
          }
          else
            callback({error: "invalid xml"}) // 3. couldn't parse xml to json
        }
      })
      .fail(function(){
        callback({error: "server failed"})
      })  // 1. server failed
    })
    .fail(function(){
      callback({error: "server failed"})
    })  // 1. server failed

    // // print metrics
    // var html = "<p>Claim "+_.settings.claim_id+" metrics</p><ul>"
    // $.each(metrics, function(key, val){
    //   html += "<li>" + key + ": " + val + "</li>"
    // })
    // html += "</ul>"
    // $(".metrics", obj).html(html)
  }

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
          var label = node_label_text(d);
          var text_len = label.length * char_to_pxl;
          var width = text_len + node_padding * 2
          return -width / 2;
        })
        .attr("width", 1e-6)
        .attr("height", 1e-6)
        .attr("rx", function(d) { return d.type === "split" ? 2 : 0;})
        .attr("ry", function(d) { return d.type === "split" ? 2 : 0;})
        .style("stroke", function(d) { return d.type === "split" ? "steelblue" : "olivedrab";})
        .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });

    nodeEnter.append("svg:text")
        .attr("dy", "18px")
        .attr("text-anchor", "middle")
        .html(node_label_html)
        .style("fill-opacity", 1e-6);

    // Transition nodes to their new position.
    var nodeUpdate = node.transition()
        .duration(duration)
        .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

    nodeUpdate.select("rect")
        .attr("width", function(d) {
          var label = node_label_text(d);
          var text_len = label.length * char_to_pxl;
          var width = text_len + node_padding * 2
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
    var link = vis.selectAll("g.link")
        .data(tree.links(nodes), function(d) { return d.target.id; });

    // Enter any new links at the parent's previous position.
    var linkEnter = link.enter().insert("svg:g", "g")
        .attr("class", "link")

    linkEnter.append("path")
        .attr("d", function(d) {
          var o = {x: source.x0, y: source.y0};
          return diagonal({source: o, target: o});
        })
        .style("stroke-width", function(d) {return link_stoke_scale(d.target.samples);})
        .style("stroke", stroke_callback);

    // Add link labels
    linkEnter.append("text")
        .attr("x", function(d) { x= d.source.x0; return x})
        .attr("y", function(d) { y= d.source.y0; return y})
        .attr("text-anchor", "middle")
        .style("fill-opacity", 1e-6)
        .text(link_label);

    // Transition links to their new position.
    var linkUpdate = link.transition()
          .duration(duration)

    linkUpdate.selectAll("path")
        .attr("d", diagonal)
        .style("stroke-width", function(d) {return link_stoke_scale(d.target.samples);})
        .style("stroke", stroke_callback);

    linkUpdate.selectAll("text")
        .style("fill-opacity", 1)
        .attr("x", function(d) { x= (d.source.x + d.target.x) / 2; return x})
        .attr("y", function(d) { y= (d.source.y + d.target.y) / 2; return y})

    // Transition exiting links to the parent's new position.
    var linkExit = link.exit().transition()
        .duration(duration)
        .remove();

    linkExit.select("path")
        .attr("d", function(d) {
          var o = {x: source.x, y: source.y};
          return diagonal({source: o, target: o});
        })

    linkExit.select("text")
        .attr("x", function(d) { x= d.source.x; return x})
        .attr("y", function(d) { y= d.source.y; return y})
        .style("fill-opacity", 1e-6);

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

  // Node labels (html version with unicde marks)
  function node_label_html(d) {
    return node_label(d, true)
  }

  // Node labels (plain text, no unicode marks)
  function node_label_text(d) {
    return node_label(d, false)
  }

  function node_label(d, isHtml) {
    if (d.type === "leaf") {
      // leaf
      var mark = ""
      var decision = d.label == 'TRUE'
      if (d.matchingPath) {
        if (isHtml)
          mark = '&nbsp;' + (decision == d.claimLabel ? '&#10003;' : '&#10060;')
        else
          mark = 'XX'
      }
      return d.label + " [claims: " + d.samples + (d.error > 0 ? ("/" + d.error) : "") + "]" + mark
    } else {
      // split node
      return d.label + " (" + Math.round(d.actualValue * 10000) / 10000 + ")";
    }
  }

  // Link labels
  function link_label(d) {
    // inherit either left or right operator
    var operator = d.target.isLeft ? d.source.condition.operator : d.source.otherOperator
    return operator + d.source.condition.value
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