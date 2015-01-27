module Explainable
  extend ActiveSupport::Concern

  included do
    def explain(claim_id)
      cm = claim_metrics.where(claim_id: claim_id).first
      scores = feature_scores
      cr = claim_results.where(claim_id: claim_id).first
      claim = DatasetRow.find(claim_id)

      header = {
        0 => claim_id,
        1 => "#{claim.object_key}.#{claim.property_key}#{claim.timestamp.present? ? '@'+claim.timestamp : ''}",
        2 => cr.confidence,
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
        "is #{metrics[0]} and it has been chosen as #{metrics[12] ? 'True' : 'False'} according to "+
        "the algorithm #{header[4]} because: "]

      #return final_explanation << "There is no conflicting value for this data item" if metrics[6] == 1
      # let the front end display this message if final_explanaation length is only 1
      return final_explanation if metrics[6] == 1

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
      scores_with_index = scores.map.with_index{|s, i| {i: i, s: s}}.sort{|a, b| b[:s] <=> a[:s]}
      # iterate through scores, pick specific ones and emit corresponding explanations
      score_index_exp_map = {
        2 => 4,
        3 => 2,
        4 => 0,
        5 => 0,
        11 => 1
      }
      # compact to remove nils (not having score_index_exp map), uniq to remove latest duplicates (e.g. 4 & 5)
      (final_explanation << explanation_text[3]) + scores_with_index.map{|si| 
        explanation_text[score_index_exp_map[si[:i]]] rescue nil
      }.compact.uniq

      # emit final explanation by decorating the strings by labels and joining by new lines
      #final_explanation.map.with_index{|e, i| "Top Explanation #{i+1}: #{e}"}.join("\n")
      # emit raw lines, front end will decorate using html lists
    end

    def feature_scores
      read_attribute(:feature_scores).strip.split(/\s+/).map(&:to_f) rescue []
    end

  end
end