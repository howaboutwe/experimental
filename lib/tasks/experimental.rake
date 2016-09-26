namespace :experimental do
  desc "sync experiments from config/experiment.yml into the database"
  task :sync => :environment do
    logger = Logger.new(STDERR)
    Experimental::Loader.new(logger: logger).sync
  end
end
