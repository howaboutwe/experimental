namespace :experiments do
  desc "sync experiments from config/experiment.yml into the database"
  task :sync => :environment do
    Experimental::Experiment::Loader.new.sync
  end
end
