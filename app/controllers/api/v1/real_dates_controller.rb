class Api::V1::RealDatesController < ApplicationController
  before_action :authenticated?
  before_action :validate_json_schema, except: []
  before_action except: [] do
    authorized?(params[:profile_uuid])
  end
  after_action :is_post_date_feedback, only: [:update]

  def show
    @real_date = RealDate.find(params[:id])

    render 'api/v1/real_dates/show', status: 200
  end

  def update
    @real_date = RealDate.find(params[:id])
    @real_date.update!(real_date_parameters)

    render 'api/v1/real_dates/show', status: 200
  end

  private

  def real_date_parameters
    attributes = RealDate::MASS_UPDATE_ATTRIBUTES
    params.require(:data).permit(*attributes)
  end

  def is_post_date_feedback
    @current_profile.update!(substate: nil, substate_endpoint: nil) if params[:data].try(:[], :post_date_rating).present?
  end
end
