class Api::V1::PhotosController < ApplicationController
  respond_to :json

  before_action :restrict_to_authenticated_clients
  before_action :validate_json_schema, except: []

  def create
  end

  def index
  end

  def show
  end

  def destroy
  end
end
