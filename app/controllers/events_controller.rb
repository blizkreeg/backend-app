OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE unless Rails.env.production?

class EventsController < ApplicationController
  skip_before_action :authenticate_token!
  skip_before_action :set_current_profile

  before_action :load_profile, except: [:payment_success]

  layout 'events'

  def rsvp_stb
    @events = Event.current_or_future_events
    rsvped_for_event = @events.select { |event| event.rsvp_for(@profile).present? }.first
    if rsvped_for_event.present?
      redirect_to action: :registered, params: { event_id: rsvped_for_event.id, uuid: @profile.uuid }
      return
    end
  end

  def register_stb
    @event_rsvp = EventRsvp.create!(attending_status: params[:attending_status], event_id: params[:event_id], profile_uuid: params[:uuid])
    @profile.reload

    redirect_to action: :registered, params: { event_id: params[:event_id], uuid: params[:uuid] }
  end

  def registered
    @event = Event.find(params[:event_id])
    @profile = Profile.find(params[:uuid])
  end

  def payment_success
    @event = Event.find(params[:event_id].to_i)
  end

  def cancel_stb
    EventRsvp.where(event_id: params[:event_id], profile_uuid: params[:uuid]).take.try(:destroy)

    redirect_to action: :rsvp_stb, params: { uuid: params[:uuid] }
  end

  def experiences
  end

  def experiences_interested

  end

  private

  def load_profile
    @profile = Profile.find(params[:uuid])
  end
end
