class Api::V1::RealDatesController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end


  def show
    @real_date = RealDate.find(params[:id])

    render 'api/v1/real_dates/show', status: 200
  end

  def update
    @real_date = RealDate.find(params[:id])
    @real_date.update!(real_date_parameters)

    if params[:data].try(:[], :post_date_rating).present?
      @current_profile.update!(substate: nil, substate_endpoint: nil)
    end

    render 'api/v1/real_dates/show', status: 200
  end

  private

  def real_date_parameters
    attributes = RealDate::MASS_UPDATE_ATTRIBUTES
    params.require(:data).permit(*attributes)
  end
end
