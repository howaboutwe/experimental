#Load the population classes
#Rails lazy loads and since they are never explicitly referenced, they don't get loaded
#Deleting this file causes failures when running individual specs
Dir[File.join(Rails.root, 'app/models/experiment/population/*.rb')].each do |f|
  require f
end
