class ExperimentalGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  desc "copy experiments yaml file"
  def copy_experiments_yaml
    copy_file "experimental.yml", "config/experimental.yml"
  end

  desc "copy initializer"
  def copy_experiments_initialize
    copy_file "experimental.rb", "config/initializers/experimental.rb"
  end


  desc "add migrations"
  def self.next_migration_number(path)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

  def copy_migrations
    migration_template 'create_experiments_table.rb',
      'db/migrate/create_experiments_table.rb'
  end
end
