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

    # clean: not necessary on heroku
    # FileUtils.rm_rf(datasets_claims_dir, datasets_grounds_dir, output_dir)
  end

end
