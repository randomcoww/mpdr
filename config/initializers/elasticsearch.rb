Elasticsearch::Persistence.client = Elasticsearch::Client.new host: "#{Rails.application.config.elasticsearch[:host]}:#{Rails.application.config.elasticsearch[:port]}"
