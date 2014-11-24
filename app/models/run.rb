class Run < ActiveRecord::Base
  belongs_to :runset
  has_many :source_results, dependent: :destroy, autosave: true
  has_many :claim_results, dependent: :destroy, autosave: true
  has_many :datasets, :through => :runset

  @@JAR_PATH = Rails.root.join("vendor/DAFNA-EA-1.0-jar-with-dependencies.jar")
  MULTI_VALUED_ALGORITHMS = %w(MLE LTM)
  MULTI_BOOLEAN_ALGORITHMES = %w(MLE)
  NORMALIZABLE_ALGORITHMS = %w(Depen Accu AccuSim AccuNoDep 3-Estimates Cosine SimpleLCA GuessLCA)

  def start
    # export datasets to csv files
    datasets_claims_dir, datasets_grounds_dir, output_dir = Dir.mktmpdir, Dir.mktmpdir, Dir.mktmpdir
    datasets.each do |dataset|
      single_valued_algo = !MULTI_VALUED_ALGORITHMS.include?(algorithm)
      value_to_boolean = MULTI_BOOLEAN_ALGORITHMES.include?(algorithm)
      dir = dataset.kind == 'ground' ? datasets_grounds_dir : datasets_claims_dir
      dataset.export("#{dir}/#{dataset.id}.csv", single_valued_algo, value_to_boolean)
    end
    logger.info "Run #{self.id} started, check these dirs: #{datasets_claims_dir}, #{datasets_grounds_dir}, #{output_dir}"
    # call the jar
    java_stdout = `java -jar #{@@JAR_PATH} #{self.algorithm} #{datasets_claims_dir} #{datasets_grounds_dir} #{output_dir} #{self.general_config} #{self.config}`
    if $?.exitstatus == 0
      logger.info "Run #{self.id} finished, check these dirs: #{datasets_claims_dir}, #{datasets_grounds_dir}, #{output_dir}"
      # parse java output
      parse_output java_stdout
      # import results
      import_results output_dir
    else
      raise "Java exception thrown, please check logs"
    end
  ensure
    # clean: not necessary on heroku
    logger.info "Deleting working dirs, disable me if you can :P"
    FileUtils.rm_rf [datasets_claims_dir, datasets_grounds_dir, output_dir]
  end

  def display
    "#{algorithm} (#{general_config.gsub(' ', ',')}; #{config.gsub(' ', ',')})"
  end
  alias_method :to_s, :display

  def before
    self.started_at = Time.now
    self.save
    Pusher.trigger_async("user_#{runset.user.id}", 'run_change', self)
  end
  
  def after
    self.finished_at = Time.now
    self.save
    Pusher.trigger("user_#{runset.user.id}", 'run_change', self)
  end

  def status
    return "finished" unless self.finished_at.nil? 
    return "started" unless self.started_at.nil? 
    return "scheduled"
  end

  def duration
    return ((self.finished_at - self.started_at) * 1000).round unless self.finished_at.nil? 
    return ""
  end

  def as_json(options={})
    options = {
      :only => [:id, :algorithm, :created_at, :runset_id, :precision, :accuracy, :recall, :specificity, :iterations],
      :methods => [:display, :status, :duration]
    }.merge(options)
    super(options)
  end

  def destroy
    # overriding destroy to be more efficient by issuing only 3 SQL deletes
    # rather than 1 + source_results.count + claim_results.count !
    conn = ActiveRecord::Base.connection
    conn.execute("DELETE FROM source_results WHERE run_id = #{self.id}")    
    conn.execute("DELETE FROM claim_results WHERE run_id = #{self.id}")    
    super # continue from super to call all after_destroy callbacks
  end

  def sankey
    conn = ActiveRecord::Base.connection
    sql = "
      SELECT
        array_to_string(array_agg(source_id), ';') sources,
        COUNT(DISTINCT bucket_id) conflicts,
        array_to_string(array_agg(is_true), ';') booleans
      FROM claim_results res
        INNER JOIN dataset_rows cl ON res.claim_id = cl.claim_id 
      WHERE res.run_id = #{self.id}
      GROUP BY object_key || property_key"

    sources, links1, links2, max_conflicts = {}, {}, {}, 0

    # TODO: escape ; in sources or use psql arrays
    conn.select_all(sql).each do |row|
      conflicts = row["conflicts"].to_i
      max_conflicts = [max_conflicts, conflicts].max
      row["sources"].split(";").each do |source_id|
        sources[source_id] = 1
        link_id = "#{conflicts}_#{source_id}"
        links1[link_id] = (links1[link_id] || 0) + 1
      end
      row["booleans"].split(";").each do |bool|
        link_id = "#{conflicts}_#{bool}"
        links2[link_id] = (links2[link_id] || 0) + 1
      end
    end

    source_keys = sources.keys
    nodes = (source_keys + ["True", "False"] + 1.upto(max_conflicts).to_a.map(&:to_s)).map do |node|
      {name: node}
    end

    logger.debug source_keys_order = 0.upto(source_keys.length - 1).to_a
    logger.debug source_keys_hash = Hash[source_keys.zip(source_keys_order)]
    logger.debug true_node_id = source_keys.length
    logger.debug false_node_id = true_node_id + 1
    logger.debug conflict_nodes_base_id = false_node_id

    links = []
    create_sankey_link(links1) do |conflicts, node, val|
      node = source_keys_hash[node]
      conflicts = conflict_nodes_base_id + conflicts
      links << {source: node, target: conflicts, value: val}
    end
    create_sankey_link(links2) do |conflicts, node, val|
      node = node == "t" ? true_node_id : false_node_id
      conflicts = conflict_nodes_base_id + conflicts
      links << {source: conflicts, target: node, value: val}
    end

    {nodes: nodes, links: links}
  end

private

  def create_sankey_link(links)
    links.each do |link_id, val|
      arr = link_id.split("_")
      conflicts = arr.shift.to_i
      node = arr.join("_")
      yield conflicts, node, val
    end
  end

  def lookup_sankey_node(node)
  end

  def import_results(output_dir)
    require 'csv'
    csv_opts = {:headers => true, :return_headers => false, :header_converters => :symbol, :converters => :all}

    # parse source results
    CSV.parse(File.read(Pathname(output_dir).join("Trustworthiness.csv")), csv_opts) do |row|
      SourceResult.initialize_from_row(row, self)
    end
    # commit to database
    self.updated_at = Time.now
    self.save!
    normalize!(source_results, "trustworthiness")

    # parse claim results
    CSV.parse(File.read(Pathname(output_dir).join("Confidences.csv")), csv_opts) do |row|
      ClaimResult.initialize_from_row(row, self)
    end
    # commit to database
    self.updated_at = Time.now
    self.save!
    normalize!(claim_results, "confidence")
  end

  def parse_output(java_stdout)
    java_stdout.split(/\n\r|\r\n|\n|\r/).each do |line|   # split whole output to lines
      key, val = line.split(/\s*:\s*/)  # split line to 'key: val'
      key.try(:downcase!)
      case key
      when 'precision', 'accuracy', 'recall', 'specificity'
        self.send("#{key}=", val.to_f)
      when 'number of iterations'
        self.iterations = val.to_i
      end
    end
    self.save!
  end

  def normalize!(associtation, attribute)
    if NORMALIZABLE_ALGORITHMS.include?(algorithm)
      # get min/max
      min = associtation.minimum(attribute)
      max = associtation.maximum(attribute)
      # calculate/update normalized
      associtation.update_all("normalized = (#{attribute} - #{min}) / (#{max} - #{min})") if min && max && max-min > 1e-10
    else
      associtation.update_all("normalized = #{attribute}")
    end
  end

  # credits: http://stackoverflow.com/a/4459463/441849
  # this capture_std is perfectly valid but the system command doesn't keep stderr in place, it redirects it to stdout
  require "stringio"
  def capture_std
    # The output stream must be an IO-like object. In this case we capture it in
    # an in-memory IO object so we can return the string value. You can assign any
    # IO object here.
    previous_stderr, $stderr, previous_stdout, $stdout = $stderr, StringIO.new, $stdout, StringIO.new
    yield
    logger.debug("captured stderr: #{$stderr.string}, stdout: #{$stdout.string}")
    return $stdout.string, $stderr.string
  ensure
    # Restore the previous value of stderr (typically equal to STDERR).
    $stdout = previous_stdout
    $stderr = previous_stderr
  end
end
