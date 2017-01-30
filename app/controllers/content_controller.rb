class ContentController < ApplicationController

  rescue_from Elasticsearch::Persistence::Repository::DocumentNotFound do
    render file: "public/404.html", status: 404, layout: false
  end

  def index
    path = params[:path]
    content = Content.reindex(path: path, recursive: false)

    if content
      json = {
        path: content.id,
        name: content.name,
        directory: content.directory,
        children: content.children
      }

      render json: json, status: :ok
    else
      render json: {}, status: :not_found
    end
  end

  def search
  end
end
