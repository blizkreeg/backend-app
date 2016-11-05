class Api::V1::PostsController < ApplicationController
  respond_to :json

  before_action :authenticated?
  before_action :validate_json_schema

  def index
    page = (params[:page] || 0).to_i
    limit = (params[:limit] || 10).to_i
    offset = page * limit

    @posts = Post.ordered_by_recent.offset(offset).limit(limit)
    @next_page = @posts.present? ? page + 1 : nil

    render 'api/v1/posts/index', status: 200
  end
end
