class MatchesController < ApplicationController

  before_action :restrict_to_authenticated_clients
  before_action :validate_json_schema, except: []

  def index
  end

  def show
  end

  def update
  end
end
