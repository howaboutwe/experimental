module Experimental
  class Railtie < Rails::Railtie
    initializer "experimental.initialize" do
      config_path = "#{Rails.root}/config/experimental.yml"
      if File.exist?(config_path)
        erb = File.read(config_path)
        yaml = ERB.new(erb).result(TOPLEVEL_BINDING)
        full = YAML.load(yaml)
        configuration = full[Rails.env] || {}
        configuration.update(full.slice('experiments'))
        Experimental.configure(configuration)
      end
    end
  end
end
