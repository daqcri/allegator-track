module Explainable
  extend ActiveSupport::Concern

  included do
    def explain(claim_id)
      # textual explanation given claim id
      cm = claim_metrics.where(claim_id: claim_id).first
      cr = claim_results.where(claim_id: claim_id).first
      claim = DatasetRow.find(claim_id)

      header = {
        0 => claim_id,
        1 => "#{claim.object_key}.#{claim.property_key}#{claim.timestamp.present? ? '@'+claim.timestamp : ''}",
        2 => claim.property_value,
        3 => claim.source_id,
        4 => self.display
      }

      metrics = {
        0 => cm.cv.round(4),
        1 => cm.ts.round(4),
        2 => cm.min_ts.round(4),
        3 => cm.max_ts.round(4),
        4 => cm.number_supp_sources.round,
        5 => cm.number_opp_sources.round,
        6 => cm.total_sources.round,
        7 => cm.number_distinct_value.round,
        8 => cm.cv_global.round,
        9 => cm.local_confidence_comparison.round,
        10 => cm.ts_global.round,
        11 => cm.ts_local.round,
        12 => cm.label
      }

      explanation_text = []

      final_explanation = ["The claim \"#{header[0]}\" belongs to the data item \"#{header[1]}\". "+
        "Among #{metrics[7]} distinct value(s) provided by "+
        "#{metrics[6]} source(s) for this data item, "+
        "the confidence of the value \"#{header[2]}\" provided by \"#{header[3]}\" "+
        "is #{metrics[0]} (normalized) and it has been chosen as #{metrics[12] ? 'True' : 'False'} according to "+
        "the algorithm #{header[4]} because: "]

      #return final_explanation << "There is no conflicting value for this data item" if metrics[6] == 1
      # let the front end display this message if final_explanation length is only 1
      return {text: final_explanation, metrics: cm} if metrics[6] == 1

      if metrics[12]
        # Add NbSS vs NbC
        if metrics[4] > 50.0
          explanation_text << "More than half of the sources (#{metrics[4]}%) are supporting this value whereas #{metrics[5]}% of the sources disagree on this value."
        elsif metrics[4] < 50.0
          explanation_text << "#{metrics[4]}% of the sources are supporting this value whereas #{metrics[5]}% of the sources disagree on this value."
        else
          explanation_text << "Half of the sources are supporting this value and half of the sources disagree on this value."
        end
        
        # Add LocalTrust and globalTrust
        explanation_text << "The trustworthiness of the source (#{metrics[1]}) claiming this value is higher than #{metrics[10]}% of all the sources in this dataset and higher than #{metrics[11]}% of all sources providing a value for this data item."
        
        # Add Ts vs maxTrust
        if cm.ts < cm.max_ts
          explanation_text << "Although the trustworthiness of the source (#{metrics[1]}) claiming this value is not the highest (#{metrics[3]}), but this value is also supported by sources with higher trustworthiness."
        else
          explanation_text << "The trustworthiness of the source (#{metrics[1]}) claiming this value is the highest among all sources for this value."
        end
        
        # Add cvGlobal and cvLocal
        explanation_text << "The confidence value of this value is #{metrics[0]}, which is higher than #{metrics[8]}% of all confidence values in this dataset and higher than #{metrics[9]}% of all values for this data item."
        
        # Add minTrust
        explanation_text << "Among the sources providing this value, even the least trustworthy source has #{metrics[2]} as trustworthiness score."
      else
        #  Add NbSS vs NbC
        if metrics[4] < 50.0
          explanation_text << "More than half of the sources (#{metrics[5]}%) disagree on this value whereas #{metrics[4]}% of the sources are supporting this value."
        elsif metrics[4] > 50.0
          explanation_text << "#{metrics[5]}% of the sources disagree on this value whereas #{metrics[4]}% of the sources are supporting this value."
        else
          explanation_text << "Half of the sources disagree on this value and half of the sources are supportingg this value."
        end
              
        # Add LocalTrust and global Trust
        explanation_text << "The trustworthiness of the source (#{metrics[1]}) claiming this value is lower than #{100 - metrics[10]}% of all the sources in this dataset and lower than #{100 - metrics[11]}% of all sources providing a value for this data item."
            
        # Add Ts vs minTrust
        if cm.ts > cm.min_ts
          explanation_text << "Alhough the trustworthiness of the source (#{metrics[1]}) claiming this value is not the minimum (#{metrics[2]}), but this value is also supported by sources with lower trustworthiness."
        else
          explanation_text << "The trustworthiness of the source (#{metrics[1]}) claiming this value is the lowest among all sources for this value."
        end
              
        # Add cvGlobal na cvLocal
        explanation_text << "The confidence value of this value is #{metrics[0]}, which is lower than #{100 - metrics[8]}% of all confidence values in this dataset and lower than #{100 - metrics[9]}% of all values for this data item."
              
        # Add maxTrust
        explanation_text << "Among the sources providing this value, the most trustworthy source has only #{metrics[3]} as trustworthiness score."
      end

      # sort scores descendingly but remember original index
      scores_with_index = feature_scores.map.with_index{|s, i| {i: i, s: s}}.sort{|a, b| b[:s] <=> a[:s]}
      # iterate through scores, pick specific ones and emit corresponding explanations
      score_index_exp_map = {
        2 => 4,
        3 => 2,
        4 => 0,
        5 => 0,
        11 => 1
      }
      # compact to remove nils (not having score_index_exp map), uniq to remove latest duplicates (e.g. 4 & 5)
      final_explanation = (final_explanation << explanation_text[3]) + scores_with_index.map{|si| 
        explanation_text[score_index_exp_map[si[:i]]] rescue nil
      }.compact.uniq

      {text: final_explanation, metrics: cm}

      # emit final explanation by decorating the strings by labels and joining by new lines
      #final_explanation.map.with_index{|e, i| "Top Explanation #{i+1}: #{e}"}.join("\n")
      # emit raw lines, front end will decorate using html lists
    end

    def feature_scores
      read_attribute(:feature_scores).strip.split(/\s+/).map(&:to_f) rescue []
    end

    def parse_decision_tree(xml_string)
      #obj = {"error" => 42716.2954, "samples" => 506, "value" => [22.532806324110698], "label" => "RM <= 6.94", "type" => "split", "children" => [{"error" => 17317.3210, "samples" => 430, "value" => [19.93372093023257], "label" => "LSTAT <= 14.40", "type" => "split", "children" => [{"error" => 6632.2175, "samples" => 255, "value" => [23.349803921568636], "label" => "DIS <= 1.38", "type" => "split", "children" => [{"error" => 390.7280, "samples" => 5, "value" => [45.58], "label" => "CRIM <= 10.59", "type" => "split", "children" => [{"error" => 0.0000, "samples" => 4, "value" => [50.0], "label" => "Leaf - 4", "type" => "leaf"}, {"error" => 0.0000, "samples" => 1, "value" => [27.9], "label" => "Leaf - 5", "type" => "leaf"}]}, {"error" => 3721.1632, "samples" => 250, "value" => [22.90520000000001], "label" => "RM <= 6.54", "type" => "split", "children" => [{"error" => 1636.0675, "samples" => 195, "value" => [21.629743589743576], "label" => "LSTAT <= 7.57", "type" => "split", "children" => [{"error" => 129.6307, "samples" => 43, "value" => [23.969767441860473], "label" => "TAX <= 222.50", "type" => "split", "children" => [{"error" => 0.0000, "samples" => 1, "value" => [28.7], "label" => "Leaf - 9", "type" => "leaf"}, {"error" => 106.7229, "samples" => 42, "value" => [23.85714285714286], "label" => "Leaf - 10", "type" => "leaf"}]}, {"error" => 1204.3720, "samples" => 152, "value" => [20.967763157894723], "label" => "TAX <= 208.00", "type" => "split", "children" => [{"error" => 161.6000, "samples" => 5, "value" => [26.9], "label" => "Leaf - 12", "type" => "leaf"}, {"error" => 860.8299, "samples" => 147, "value" => [20.765986394557814], "label" => "Leaf - 13", "type" => "leaf"}]}]}, {"error" => 643.1691, "samples" => 55, "value" => [27.427272727272726], "label" => "TAX <= 269.00", "type" => "split", "children" => [{"error" => 91.4612, "samples" => 17, "value" => [30.24117647058823], "label" => "PTRATIO <= 17.85", "type" => "split", "children" => [{"error" => 26.9890, "samples" => 10, "value" => [31.71], "label" => "Leaf - 16", "type" => "leaf"}, {"error" => 12.0771, "samples" => 7, "value" => [28.142857142857142], "label" => "Leaf - 17", "type" => "leaf"}]}, {"error" => 356.8821, "samples" => 38, "value" => [26.16842105263158], "label" => "NOX <= 0.53", "type" => "split", "children" => [{"error" => 232.6986, "samples" => 29, "value" => [27.006896551724143], "label" => "Leaf - 19", "type" => "leaf"}, {"error" => 38.1000, "samples" => 9, "value" => [23.466666666666665], "label" => "Leaf - 20", "type" => "leaf"}]}]}]}]}, {"error" => 3373.2512, "samples" => 175, "value" => [14.955999999999996], "label" => "NOX <= 0.61", "type" => "split", "children" => [{"error" => 833.2624, "samples" => 68, "value" => [18.123529411764697], "label" => "CRIM <= 0.55", "type" => "split", "children" => [{"error" => 272.4123, "samples" => 39, "value" => [19.738461538461536], "label" => "AGE <= 60.55", "type" => "split", "children" => [{"error" => 22.5743, "samples" => 7, "value" => [22.071428571428573], "label" => "NOX <= 0.46", "type" => "split", "children" => [{"error" => 0.9800, "samples" => 2, "value" => [19.6], "label" => "Leaf - 25", "type" => "leaf"}, {"error" => 4.4920, "samples" => 5, "value" => [23.060000000000002], "label" => "Leaf - 26", "type" => "leaf"}]}, {"error" => 203.4047, "samples" => 32, "value" => [19.228125], "label" => "LSTAT <= 24.69", "type" => "split", "children" => [{"error" => 150.4386, "samples" => 28, "value" => [19.692857142857147], "label" => "Leaf - 28", "type" => "leaf"}, {"error" => 4.5875, "samples" => 4, "value" => [15.975000000000001], "label" => "Leaf - 29", "type" => "leaf"}]}]}, {"error" => 322.3524, "samples" => 29, "value" => [15.951724137931038], "label" => "RM <= 6.84", "type" => "split", "children" => [{"error" => 184.2268, "samples" => 28, "value" => [15.539285714285716], "label" => "B <= 26.72", "type" => "split", "children" => [{"error" => 1.1250, "samples" => 2, "value" => [10.95], "label" => "Leaf - 32", "type" => "leaf"}, {"error" => 137.7385, "samples" => 26, "value" => [15.892307692307696], "label" => "Leaf - 33", "type" => "leaf"}]}, {"error" => 0.0000, "samples" => 1, "value" => [27.5], "label" => "Leaf - 34", "type" => "leaf"}]}]}, {"error" => 1424.1422, "samples" => 107, "value" => [12.942990654205609], "label" => "LSTAT <= 19.65", "type" => "split", "children" => [{"error" => 316.3804, "samples" => 51, "value" => [15.480392156862749], "label" => "CRIM <= 12.22", "type" => "split", "children" => [{"error" => 232.6349, "samples" => 47, "value" => [15.842553191489367], "label" => "CRIM <= 5.77", "type" => "split", "children" => [{"error" => 132.1443, "samples" => 28, "value" => [16.535714285714285], "label" => "Leaf - 38", "type" => "leaf"}, {"error" => 67.2116, "samples" => 19, "value" => [14.821052631578949], "label" => "Leaf - 39", "type" => "leaf"}]}, {"error" => 5.1475, "samples" => 4, "value" => [11.225], "label" => "CRIM <= 14.17", "type" => "split", "children" => [{"error" => 0.5000, "samples" => 2, "value" => [12.2], "label" => "Leaf - 41", "type" => "leaf"}, {"error" => 0.8450, "samples" => 2, "value" => [10.25], "label" => "Leaf - 42", "type" => "leaf"}]}]}, {"error" => 480.3621, "samples" => 56, "value" => [10.632142857142854], "label" => "TAX <= 551.50", "type" => "split", "children" => [{"error" => 23.5290, "samples" => 10, "value" => [14.41], "label" => "DIS <= 1.38", "type" => "split", "children" => [{"error" => 1.2800, "samples" => 2, "value" => [12.600000000000001], "label" => "Leaf - 45", "type" => "leaf"}, {"error" => 14.0588, "samples" => 8, "value" => [14.8625], "label" => "Leaf - 46", "type" => "leaf"}]}, {"error" => 283.0846, "samples" => 46, "value" => [9.81086956521739], "label" => "DIS <= 1.41", "type" => "split", "children" => [{"error" => 11.0971, "samples" => 7, "value" => [12.857142857142858], "label" => "Leaf - 48", "type" => "leaf"}, {"error" => 195.3697, "samples" => 39, "value" => [9.264102564102567], "label" => "Leaf - 49", "type" => "leaf"}]}]}]}]}]}, {"error" => 6059.4193, "samples" => 76, "value" => [37.23815789473684], "label" => "RM <= 7.44", "type" => "split", "children" => [{"error" => 1899.6122, "samples" => 46, "value" => [32.11304347826087], "label" => "CRIM <= 7.39", "type" => "split", "children" => [{"error" => 864.7674, "samples" => 43, "value" => [33.348837209302324], "label" => "DIS <= 1.89", "type" => "split", "children" => [{"error" => 37.8450, "samples" => 2, "value" => [45.65], "label" => "INDUS <= 18.84", "type" => "split", "children" => [{"error" => 0.0000, "samples" => 1, "value" => [50.0], "label" => "Leaf - 54", "type" => "leaf"}, {"error" => 0.0000, "samples" => 1, "value" => [41.3], "label" => "Leaf - 55", "type" => "leaf"}]}, {"error" => 509.5224, "samples" => 41, "value" => [32.74878048780488], "label" => "NOX <= 0.49", "type" => "split", "children" => [{"error" => 135.3867, "samples" => 27, "value" => [34.15555555555556], "label" => "AGE <= 11.95", "type" => "split", "children" => [{"error" => 0.1800, "samples" => 2, "value" => [29.3], "label" => "Leaf - 58", "type" => "leaf"}, {"error" => 84.2816, "samples" => 25, "value" => [34.544000000000004], "label" => "Leaf - 59", "type" => "leaf"}]}, {"error" => 217.6521, "samples" => 14, "value" => [30.03571428571428], "label" => "RM <= 7.12", "type" => "split", "children" => [{"error" => 49.6286, "samples" => 7, "value" => [26.914285714285715], "label" => "Leaf - 61", "type" => "leaf"}, {"error" => 31.6171, "samples" => 7, "value" => [33.15714285714286], "label" => "Leaf - 62", "type" => "leaf"}]}]}]}, {"error" => 27.9200, "samples" => 3, "value" => [14.4], "label" => "RM <= 7.14", "type" => "split", "children" => [{"error" => 0.0000, "samples" => 1, "value" => [10.4], "label" => "Leaf - 64", "type" => "leaf"}, {"error" => 3.9200, "samples" => 2, "value" => [16.4], "label" => "CRIM <= 13.93", "type" => "split", "children" => [{"error" => 0.0000, "samples" => 1, "value" => [17.8], "label" => "Leaf - 66", "type" => "leaf"}, {"error" => 0.0000, "samples" => 1, "value" => [15.0], "label" => "Leaf - 67", "type" => "leaf"}]}]}]}, {"error" => 1098.8497, "samples" => 30, "value" => [45.09666666666668], "label" => "B <= 361.92", "type" => "split", "children" => [{"error" => 0.0000, "samples" => 1, "value" => [21.9], "label" => "Leaf - 69", "type" => "leaf"}, {"error" => 542.2097, "samples" => 29, "value" => [45.896551724137936], "label" => "PTRATIO <= 14.80", "type" => "split", "children" => [{"error" => 112.3800, "samples" => 14, "value" => [48.300000000000004], "label" => "RM <= 7.71", "type" => "split", "children" => [{"error" => 37.8475, "samples" => 4, "value" => [44.725], "label" => "CRIM <= 1.00", "type" => "split", "children" => [{"error" => 0.7467, "samples" => 3, "value" => [42.96666666666667], "label" => "Leaf - 73", "type" => "leaf"}, {"error" => 0.0000, "samples" => 1, "value" => [50.0], "label" => "Leaf - 74", "type" => "leaf"}]}, {"error" => 2.9610, "samples" => 10, "value" => [49.730000000000004], "label" => "LSTAT <= 3.75", "type" => "split", "children" => [{"error" => 0.0000, "samples" => 6, "value" => [50.0], "label" => "Leaf - 76", "type" => "leaf"}, {"error" => 1.8675, "samples" => 4, "value" => [49.325], "label" => "Leaf - 77", "type" => "leaf"}]}]}, {"error" => 273.4773, "samples" => 15, "value" => [43.653333333333336], "label" => "B <= 385.48", "type" => "split", "children" => [{"error" => 16.4920, "samples" => 5, "value" => [47.160000000000004], "label" => "CRIM <= 0.32", "type" => "split", "children" => [{"error" => 1.8467, "samples" => 3, "value" => [45.833333333333336], "label" => "Leaf - 80", "type" => "leaf"}, {"error" => 1.4450, "samples" => 2, "value" => [49.15], "label" => "Leaf - 81", "type" => "leaf"}]}, {"error" => 164.7600, "samples" => 10, "value" => [41.9], "label" => "CRIM <= 0.06", "type" => "split", "children" => [{"error" => 19.7067, "samples" => 3, "value" => [46.46666666666667], "label" => "Leaf - 83", "type" => "leaf"}, {"error" => 55.6771, "samples" => 7, "value" => [39.94285714285714], "label" => "Leaf - 84", "type" => "leaf"}]}]}]}]}]}]}
      # self.decision_tree = obj.to_json
      self.decision_tree = xml_string
    end

    def explain_tree
      # decision tree explanation
      self.decision_tree || ""
    end

  end
end