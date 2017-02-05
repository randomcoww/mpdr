class IncrementalIndexer

  @queue = :mpd_incremental_indexer

  def self.perform
    indexer_client = MpdClient::Indexer.client
    indexer_client.index_incremental
  rescue => e
    Rails.logger.error("Incremental indexer failed with: #{e.message}, #{e.backtrace}")
  ensure
    indexer_client.disconnect if !indexer_client.nil?
  end
end
