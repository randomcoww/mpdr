class DatabaseController < ApplicationController

  # rescue_from Elasticsearch::Persistence::Repository::DocumentNotFound do
  #   render json: {}, status: :not_found
  # end
  rescue_from Exception do |e|
    render json: {
      error: e.message,
      trace: e.backtrace
    }, status: :unprocessable_entity
  end

  def index
    content = MpdClient::Api.client.get_database_path(
      params[:path],
      params[:start],
      params[:end]
    )

    render json: content, status: :ok
  end

  def search
  end
end
