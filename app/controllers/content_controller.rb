class ContentController < ApplicationController

  # rescue_from Elasticsearch::Persistence::Repository::DocumentNotFound do
  #   render json: {}, status: :not_found
  # end
  rescue_from Exception do
    render json: {}, status: :not_found
  end

  def index
    path = params[:path]
    start_index = (params[:start] || 0).to_i
    end_index = (params[:end] || -1).to_i

    content = MpdClient::Api.client.path_info(path)
    content = [content] unless content.is_a?(Array)
    content = content[start_index..end_index]

    content.each_with_index do |c, i|
      if c.has_key?(:file)
        begin
          index = Song.find(c[:file])
        rescue
          index = Song.update(c)
        end
        content[i] = index if !index.nil?
      end
    end

    render json: content, status: :ok
  end

  def search
  end
end
