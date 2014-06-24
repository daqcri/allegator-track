class Run < ActiveRecord::Base
  has_and_belongs_to_many :datasets
  belongs_to :user

  @@JAR_PATH = Rails.root.join("DAFNA-EA/DAFNA-EA.jar")

  def start
    # export datasets to csv files
    datasets_claims_dir, datasets_grounds_dir, output_dir = Dir.mktmpdir, Dir.mktmpdir, Dir.mktmpdir
    datasets.each do |dataset|
      dataset.export("#{dataset.kind == 'ground' ? datasets_grounds_dir : datasets_claims_dir}/#{dataset.id}.csv")
    end
    # call the jar
    system("java -jar #{@@JAR_PATH} #{self.algorithm} #{datasets_claims_dir} #{datasets_grounds_dir} #{output_dir} #{self.general_config} #{self.config}")

    # import results
    puts "Check these dirs: #{datasets_claims_dir}, #{datasets_grounds_dir}, #{output_dir}"

    # File.read(output_dir + "/XXXX")
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
    Pusher.trigger_async("user_#{user.id}", 'run_change', self)
  end
  
  def after
    self.finished_at = Time.now
    self.save
    Pusher.trigger_async("user_#{user.id}", 'run_change', self)
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
      :only => [:id, :created_at],
      :methods => [:display, :status, :duration]
    }.merge(options)
    super(options)
  end

end
