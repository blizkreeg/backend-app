class BrewsController < ApplicationController
  layout 'brews'

  def homepage
  end

  def index
  end

  def new
    @brew ||= Brew.new
  end

  def create
  end

  def show
  end
end
