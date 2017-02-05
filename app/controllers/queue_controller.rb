class QueueController < ApplicationController

  rescue_from Exception do |e|
    render json: {
      error: e.message,
      trace: e.backtrace
    }, status: :unprocessable_entity
  end

  def index
    content = MpdClient::Api.client.get_queue(
      params[:start],
      params[:end]
    )
    render json: content, status: :ok
  end

  def play
    content = MpdClient::Api.client.play(
      params[:playlist_id]
    )
    render nothing: true, status: 204
  end

  def stop
    content = MpdClient::Api.client.stop
    render nothing: true, status: 204
  end

  def pause
    content = MpdClient::Api.client.pause
    render nothing: true, status: 204
  end

  def unpause
    content = MpdClient::Api.client.unpause
    render nothing: true, status: 204
  end

  def move
    content = MpdClient::Api.client.move(
      params[:start],
      params[:end],
      params[:to]
    )
    render nothing: true, status: 204
  end

  def remove
    content = MpdClient::Api.client.remove(
      params[:start],
      params[:end]
    )
    render nothing: true, status: 204
  end

  def go_next
    content = MpdClient::Api.client.go_next
    render nothing: true, status: 204
  end

  def go_previous
    content = MpdClient::Api.client.go_previous
    render nothing: true, status: 204
  end

  def add_file
    content = MpdClient::Api.client.add_file(
      params[:path],
      params[:position]
    )
    render nothing: true, status: 204
  end

  def add_path
    content = MpdClient::Api.client.add_path(
      params[:path],
      params[:position]
    )
    render nothing: true, status: 204
  end
end
