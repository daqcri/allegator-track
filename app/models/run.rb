require 'csv'
require 'stringio'
require 'application_exception'

class Run < ActiveRecord::Base
  belongs_to :runset
  has_many :source_results, dependent: :destroy, autosave: true
  has_many :claim_results, dependent: :destroy, autosave: true
  has_many :claim_metrics, dependent: :destroy, autosave: true
  has_many :datasets, :through => :runset
  belongs_to :allegates_run, class_name: Run
  belongs_to :allegates_claim, class_name: DatasetRow
  has_one :allegated_dataset, class_name: Dataset, foreign_key: 'allegated_by_run_id'

  include Explainable

  @@JAR_PATH = Rails.root.join("vendor/DAFNA-EA-1.0-jar-with-dependencies.jar")
  MULTI_VALUED_ALGORITHMS = %w(MLE LTM)
  MULTI_BOOLEAN_ALGORITHMES = %w(MLE)
  NORMALIZABLE_ALGORITHMS = %w(Depen Accu AccuSim AccuNoDep 3-Estimates Cosine SimpleLCA GuessLCA)
  COMBINER_ALGORITHMES = %w(Combiner)

  scope :allegators, -> {where("allegates_claim_id is not null and allegates_run_id is not null")}
  scope :voters, -> {where("allegates_claim_id is null and allegates_run_id is null")}

  def start
    # export datasets to csv files
    has_ground = false
    datasets_claims_dir, datasets_grounds_dir, output_dir = Dir.mktmpdir, Dir.mktmpdir, Dir.mktmpdir
    confidence_dirs = []
    datasets.each do |dataset|
      single_valued_algo = !MULTI_VALUED_ALGORITHMS.include?(algorithm)
      value_to_boolean = MULTI_BOOLEAN_ALGORITHMES.include?(algorithm)
      dir = dataset.ground? ? datasets_grounds_dir : datasets_claims_dir
      dataset.export("#{dir}/#{dataset.id}.csv", single_valued_algo, value_to_boolean)
      has_ground = true if dataset.ground?
    end
    # prepare extra arguments
    extra_params = "#{self.general_config} #{self.config}"
    if combiner?
      non_combiners = runset.non_combiner_runs
      extra_params = "0 0 0 0 #{non_combiners.length}"
      non_combiners.each do |run|
        dir, file = run.generate_file_in_param "export_claim_results"
        confidence_dirs << dir
        extra_params << " #{file}"
      end
    elsif allegator?
      # add 5 params: run_id claim_id conffile trustfile Allegate
      extra_params << " #{self.allegates_run_id} #{self.allegates_claim_id}"
      # generate conf file
      dir, file = allegates_run.generate_file_in_param "export_claim_results"
      confidence_dirs << dir
      extra_params << " #{file}"
      # generate trust file
      dir, file = allegates_run.generate_file_in_param "export_source_results"
      confidence_dirs << dir
      extra_params << " #{file}"
      # append the Allegate param
      extra_params << " Allegate"
    end

    # prepare streams
    java_stdout, java_stderr = Tempfile.new("java_stdout"), Tempfile.new("java_stderr")
    java_stdout.close ; java_stdout = java_stdout.path
    java_stderr.close ; java_stderr = java_stderr.path
    
    # call the jar
    cmd = "java -jar #{@@JAR_PATH} #{self.algorithm} #{datasets_claims_dir} #{datasets_grounds_dir} #{output_dir} #{extra_params}"
    cmd = "#{cmd} 1>#{java_stdout} 2>#{java_stderr}"
    logger.info "Run #{self.id} started, check these dirs: Claims: #{datasets_claims_dir}, Ground: #{datasets_grounds_dir} and Combiner input confidences: #{confidence_dirs.join(', ')}"
    logger.info "Forking child processes: #{cmd}..."

    pid = Process.fork {
      exec(cmd)
    }

    # raise Exception.new "UNKNOWN EXCEPTION HERE"

    logger.info "Child forked with pid: #{pid}"
    Process.wait(pid)

    # child is done, process output
    java_stdout_s, java_stderr_s = File.read(java_stdout), File.read(java_stderr)

    unless java_has_stderr?(java_stderr_s)
      logger.info "Run #{self.id} finished, check this dir: #{output_dir}\nstdout: #{java_stdout_s}\nstderr: #{java_stderr_s}"
      # parse java output
      parse_output java_stdout_s, has_ground
      # import results
      import_results output_dir
    else
      raise ApplicationException, "Internal error: #{java_stderr_s}"
    end
  rescue SignalException => e
    cleanup pid, e, "Processing interrupted"
  rescue Delayed::WorkerTimeout => e
    cleanup pid, e, "Processing reached maximum allowed time"
  rescue ApplicationException => e
    # this is unrecoverable error, don't mark job as failed so that it is not reattempted
    # only set last error, but don't cleanup (eventually rethrowing an exception)
    set_last_error! e.message
  rescue => e
    cleanup pid, e, "Unexpected error"
  ensure
    # clean: not necessary on heroku
    # logger.info "Deleting working dirs, disable me if you can :P"
    # FileUtils.rm_rf [datasets_claims_dir, datasets_grounds_dir, output_dir] rescue ""
    # FileUtils.rm_rf confidence_dirs if confidence_dirs.length > 0 rescue ""
    # FileUtils.rm java_stdout rescue ""
    # FileUtils.rm java_stderr rescue ""
  end

  def fake_start
    puts "Forking child processes..."
    
    pid = Process.fork {
      exec((Rails.root + "lazy_process.sh").to_s + " > /tmp/stdout")
    }

    puts "Child forked with pid: #{pid}"

    raise Exception.new "UNKNOWN EXCEPTION HERE"
    
    puts "Parent will wait for child..."
    Process.wait(pid)

    puts "This is the buffered child stdout: #{File.read('/tmp/stdout')}"

  rescue SignalException => e
    cleanup pid, e, "Processing interrupted"
  rescue Delayed::WorkerTimeout => e
    cleanup pid, e, "Processing reached maximum allowed time"
  rescue ApplicationException => e
    # this is unrecoverable error, don't mark job as failed so that it is not reattempted
    # only set last error, but don't cleanup (eventually rethrowing an exception)
    set_last_error! e.message
  rescue => e
    cleanup pid, e, "Unexpected error"
  ensure
    puts "Parent is exiting"
  end

  def combiner?
    COMBINER_ALGORITHMES.include?(algorithm)
  end

  def allegator?
    !allegates_claim_id.nil? && !allegates_run_id.nil?
  end

  def display
    if combiner?
      algorithm
    else
      "#{algorithm} (#{general_config.try(:gsub, ' ', ',')}; #{config.try(:gsub, ' ', ',')})"
    end
  end

  def before
    self.started_at = Time.now
    self.finished_at = self.last_error = nil
    self.save
    # destroy old results, in case job was restarted
    destroy_associations!
    Pusher.trigger_async("user_#{runset.user.id}", 'run_change', self) rescue nil
  end
  
  def success
  end

  def error(job, e)
    set_last_error! e.message
  end

  def set_last_error!(message)
    logger.debug "Setting last_error to #{message}"
    m = message.try(:match, /<Exception: (.*)>/)
    self.last_error = m ? m[1] : message
    save
  end

  def after
    self.finished_at = Time.now
    self.save
    Pusher.trigger_async("user_#{runset.user.id}", 'run_change', self) rescue nil
  end

  def status
    return "finished" unless self.finished_at.nil? 
    return "started" unless self.started_at.nil? 
    return "scheduled"
  end

  def finished?
    status == "finished"
  end

  def started?
    status == "started"
  end

  def scheduled?
    status == "scheduled"
  end

  def duration
    return ((self.finished_at - self.started_at) * 1000).round unless self.finished_at.nil? 
    return ""
  end

  def claims_allegated
    allegated_dataset.row_count rescue nil
  end

  def dup(allegates_claim)
    other_run = super()
    other_run.started_at = other_run.finished_at = other_run.last_error = nil
    other_run.allegates_run_id = self.id
    other_run.allegates_claim_id = allegates_claim.id
    other_run.allegates_value = ClaimResult.where(run_id: self.id).where(claim_id: allegates_claim.id).first.confidence
    other_run
  end

  def as_json(options={})
    options = {
      :only => [:id, :algorithm, :created_at, :runset_id,
        :precision, :accuracy, :recall, :specificity, :iterations,
        :last_error,
        :allegates_run_id, :allegates_claim_id, :allegates_value],
      :methods => [:display, :status, :duration, :claims_allegated, :combiner?, :allegator?]
    }.merge(options)
    super(options)
  end

  def sankey
    conn = ActiveRecord::Base.connection
    sql = "
      SELECT
        array_to_string(array_agg(source_id), ';') sources,
        COUNT(DISTINCT bucket_id) conflicts,
        array_to_string(array_agg(is_true), ';') booleans
      FROM claim_results res
        INNER JOIN dataset_rows cl ON res.claim_id = cl.id 
      WHERE res.run_id = #{self.id}
      GROUP BY object_key || property_key"

    sources, links_true, links_false, max_conflicts = {}, {}, {}, 0

    # TODO: escape ; in sources or use psql arrays
    conn.select_all(sql).each do |row|
      conflicts = row["conflicts"].to_i
      max_conflicts = [max_conflicts, conflicts].max
      booleans = row["booleans"].split(";")
      row["sources"].split(";").each.with_index do |source_id, index|
        sources[source_id] = 1
        link_id = "#{conflicts}_#{source_id}"
        if booleans[index] == 't'
          links_true[link_id] = (links_true[link_id] || 0) + 1
        else
          links_false[link_id] = (links_false[link_id] || 0) + 1
        end
      end
    end

    source_keys = sources.keys
    nodes = source_keys.map{|node| {name: node}}
    1.upto(max_conflicts).each{|node| nodes << {name: "#{node-1}", conflict: true, bool: false}}
    1.upto(max_conflicts).each{|node| nodes << {name: "#{node-1}", conflict: true, bool: true}}

    logger.debug source_keys_order = 0.upto(source_keys.length - 1).to_a
    logger.debug source_keys_hash = Hash[source_keys.zip(source_keys_order)]
    logger.debug false_nodes_base_id = source_keys.length - 1
    logger.debug true_nodes_base_id = false_nodes_base_id + max_conflicts

    links = []
    create_sankey_link(source_keys_hash, links_true, true_nodes_base_id){|link| links << link}
    create_sankey_link(source_keys_hash, links_false, false_nodes_base_id){|link| links << link}

    {sources: source_keys.length, nodes: nodes, links: links}
  end

  def to_s
    "Run ##{id}: #{display}"
  end

  def destroy
    destroy_associations!
    super
  end

  def self.example_sankey
    {nodes:[
      {name: "Best Bargain Books"},
      {name: "textbookxdotcom"},
      {name: "OPOE-ABE Books"},
      {name: "Player Quest"},
      {name: "Bobs Books"},
      {name: "Mellon's Books"},
      {name: "Blackwell Online"},
      {name: "1", conflict: true},
      {name: "2", conflict: true},
      {name: "3", conflict: true},
      {name: "4", conflict: true},
      {name: "True", bool: true},
      {name: "False", bool: false}
      ],
      links:[
      { source:0, target:7, value:2},
      { source:7, target:11, value:3},
      { source:1, target:10, value:6}, 
      { source:10, target:12, value:5},
      { source:1, target:9, value:5},
      { source:2, target:9, value:3},
      { source:9, target:11, value:1},
      { source:2, target:10, value:8},
      { source:3, target:8, value:4},
      { source:8, target:11, value:6},
      { source:4, target:8, value:15},
      { source:8, target:12, value:4},
      { source:5, target:7, value:10},
      { source:9, target:12, value:4},
      { source:6, target:8, value:4},
      { source:8, target:12, value:6},
      { source:6, target:10, value:9},
      { source:10, target:11, value:1},
      { source:6, target:7, value:9},
      { source:7, target:11, value:1}
    ]}
  end
  
protected

  def generate_file_in_param(exporter_function)
    dir = Dir.mktmpdir
    file = "#{dir}/#{exporter_function}.#{self.id}.csv"
    self.send exporter_function.to_sym, file
    return dir, file
  end

private

  def cleanup(pid, e, message)
    # log exception so we have context about what happened
    backtrace = e.backtrace.join("\n")
    logger.info "Received #{e.class.name}: #{e.message}, backtrace:\n#{backtrace} terminating child process #{pid}..."
    # terminate the child java process, if any
    Process.kill("KILL", pid) rescue ""
    # propagate back a new exception so that job marked as failed
    throw Exception.new message
  end

  def destroy_associations!
    # overriding destroy to be more efficient by issuing only 3 SQL deletes
    # rather than 1 + source_results.count + claim_results.count + claim_metrics.count !
    conn = ActiveRecord::Base.connection
    conn.execute("DELETE FROM source_results WHERE run_id = #{self.id}")    
    conn.execute("DELETE FROM claim_results WHERE run_id = #{self.id}")    
    conn.execute("DELETE FROM claim_metrics WHERE run_id = #{self.id}")    
  end

  def create_sankey_link(source_keys_hash, links, bool_nodes_base_id)
    links.each do |link_id, val|
      arr = link_id.split("_")
      conflicts = arr.shift.to_i
      node = arr.join("_")
      source_node = source_keys_hash[node]
      bool_node = bool_nodes_base_id + conflicts
      yield ({source: source_node, target: bool_node, value: val})
    end
  end

  def read_results_file(dir, name)
    path = Pathname(dir).join(name)
    File.read(path) if File.exists?(path)
  end

  def import_results(output_dir)
    csv_opts = {:headers => true, :return_headers => false, :header_converters => :symbol}

    unless allegator?
      # parse source results
      if f = read_results_file(output_dir, "Trustworthiness.csv")
        CSV.parse(f, csv_opts) do |row|
          SourceResult.initialize_from_row(row, self)
        end
        # commit to database
        self.updated_at = Time.now
        self.save!
        normalize!(source_results, "trustworthiness")
      end

      # parse claim results
      if f = read_results_file(output_dir, "Confidences.csv")
        CSV.parse(f, csv_opts) do |row|
          ClaimResult.initialize_from_row(row, self)
        end
        # commit to database
        self.updated_at = Time.now
        self.save!
        normalize!(claim_results, "confidence")
      end

      # parse claim metrics
      if f = read_results_file(output_dir, "Metrics.csv")
        CSV.parse(f, csv_opts) do |row|
          ClaimMetric.initialize_from_row(row, self)
        end
        # commit to database
        self.updated_at = Time.now
        self.save!
      end

      # parse decision tree
      # store XML in serialized json object
      if f = read_results_file(output_dir, "DecisionTree.xml")
        parse_decision_tree f
        # commit to database
        self.updated_at = Time.now
        self.save!
      end
    else
      allegations_file = Pathname(output_dir).join("AllegationClaims.csv").to_s
      if File.exists?(allegations_file)
        # parse fake claims (for allegators)
        ds = Dataset.new
        ds.kind = 'claims'
        ds.original_filename = "Run#{self.allegates_run_id}.claim#{self.allegates_claim_id}.allegations"
        ds.other_url = allegations_file
        ds.user = runset.user
        ds.allegated_by_run_id = self.id
        ds.status = 'processing'
        ds.save!
        ds.parse_upload
        ds.status = 'done'
        ds.save!
        self.reload # to load allegated_dataset association
      else
        # couldn't find allegations
        raise ApplicationException, "Could not allegate claim #{allegates_claim_id} from " + 
          "run #{allegates_run_id}, try changing run configuration or claim"
      end
    end
  end

  def export_claim_results(output_file)
    export_results output_file, ClaimResult, claim_results
  end

  def export_source_results(output_file)
    export_results output_file, SourceResult, source_results
  end

  def export_results(output_file, results_type, results)
    CSV.open(output_file, "wb") do |csv|
      csv << results_type.export_header
      results.each do |row|
        csv << row.export
      end
    end
  end

  def parse_output(java_stdout, has_ground)
    java_stdout.split(/\n\r|\r\n|\n|\r/).each do |line|   # split whole output to lines
      key, val = line.split(/\s*:\s*/)  # split line to 'key: val'
      key.try(:downcase!)
      case key
      when 'precision', 'accuracy', 'recall', 'specificity'
        self.send("#{key}=", val.to_f) if has_ground
      when 'number of iterations'
        self.iterations = val.to_i
      when 'featurescores'
        self.feature_scores = val
      end
    end
    self.save!
  end

  def java_has_stderr?(java_stderr)
    java_stderr.split(/\n\r|\r\n|\n|\r/).each do |line|
      return true unless line.match(/^Picked up.+JAVA/)
    end
    false
  end

  def normalize!(associtation, attribute)
    if NORMALIZABLE_ALGORITHMS.include?(algorithm)
      # get min/max
      min = associtation.minimum(attribute)
      max = associtation.maximum(attribute)
      # calculate/update normalized
      associtation.update_all("normalized = GREATEST(0, LEAST(1, ((#{attribute} - #{min}) / (#{max} - #{min}))))") if min && max && max-min > 1e-10
    else
      associtation.update_all("normalized = #{attribute}")
    end
  end

  # credits: http://stackoverflow.com/a/4459463/441849
  # this capture_std is perfectly valid but the system command doesn't keep stderr in place, it redirects it to stdout
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
