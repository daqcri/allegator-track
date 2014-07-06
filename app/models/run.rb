class Run < ActiveRecord::Base
  belongs_to :runset
  has_many :source_results, dependent: :destroy, autosave: true
  has_many :claim_results, dependent: :destroy, autosave: true
  has_many :datasets, :through => :runset

  @@JAR_PATH = Rails.root.join("vendor/DAFNA-EA-1.0-jar-with-dependencies.jar")

  def start
    # export datasets to csv files
    datasets_claims_dir, datasets_grounds_dir, output_dir = Dir.mktmpdir, Dir.mktmpdir, Dir.mktmpdir
    datasets.each do |dataset|
      dataset.export("#{dataset.kind == 'ground' ? datasets_grounds_dir : datasets_claims_dir}/#{dataset.id}.csv")
    end
    # call the jar
    system("java -jar #{@@JAR_PATH} #{self.algorithm} #{datasets_claims_dir} #{datasets_grounds_dir} #{output_dir} #{self.general_config} #{self.config}")

    # import results
    import_results output_dir
    logger.info "Run #{self.id} finished, check these dirs: #{datasets_claims_dir}, #{datasets_grounds_dir}, #{output_dir}"

    # clean: not necessary on heroku
    # FileUtils.rm_rf(datasets_claims_dir, datasets_grounds_dir, output_dir)
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
    Pusher.trigger_async("user_#{runset.user.id}", 'run_change', self)
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
      :only => [:id, :algorithm, :created_at, :runset_id],
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

private

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
    self.normalize(source_results, "trustworthiness")

    # parse claim results
    CSV.parse(File.read(Pathname(output_dir).join("Confidences.csv")), csv_opts) do |row|
      ClaimResult.initialize_from_row(row, self)
    end
    # commit to database
    self.updated_at = Time.now
    self.save!
    self.normalize(claim_results, "confidence")
  end

  def normalize(associtation, attribute)
    # get min/max
    min = associtation.minimum(attribute)
    max = associtation.maximum(attribute)
    # calculate/update normalized
    associtation.update_all("normalized = (#{attribute} - #{min}) / (#{max} - #{min})") if min && max
  end
end
