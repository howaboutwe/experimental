module Experimental
  class Railtie < Rails::Railtie
    initializer "experimental.initialize" do
      config_path = "#{Rails.root}/config/experimental.yml"
      if File.exist?(config_path)
        full = YAML.load_file(config_path)
        configuration = full[Rails.env] || {}
        configuration.update(full.slice('experiments'))
        Experimental.configure(configuration)
      end
    end
  end
end
