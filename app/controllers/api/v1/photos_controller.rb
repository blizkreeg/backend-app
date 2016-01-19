class Api::V1::PhotosController < ApplicationController
  respond_to :json

  before_action :restrict_to_authenticated_clients

  def create
  end

  def index
  end

  def show
  end

  def destroy
  end
end
