class QueueController < ApplicationController

  rescue_from Exception do
    render json: {}, status: :unprocessable_entity
  end

  def index
    content = MpdClient::Api.client.get_queue(
      params[:start],
      params[:end]
    )

    render json: content, status: :ok
  end
end
