OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE unless Rails.env.production?

class EventsController < ApplicationController
  skip_before_action :authenticate_token!
  skip_before_action :set_current_profile

  before_action :load_profile, except: [:payment_success]

  layout 'events'

  def index
    @events = Event.happening_on_after(Date.today-1)
  end

  def rsvp_stb
    @events = [Event.first]# Event.current_or_future_events
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

  def announce_interests
    render 'announce-interests'
  end

  def register_interests
    gsheet = GoogleSheet.new('1QTtUWo3gWZLDDo6UIYVVMs71p3MIsItM-o2TH6zzX9I')
    gsheet.insert_row([
      @profile.uuid,
      @profile.gender,
      @profile.location_city,
      @profile.age,
      @profile.firstname,
      @profile.lastname,
      @profile.desirability_score,
      params[:activity].first.select { |key, value| value == "1" }.keys.join(', '),
      params[:will_host],
      params[:will_attend]
    ])

    render 'thankyou-interests'
  end

  def show_brew
    @events = @profile.upcoming_brews
    # rsvped_for_event = @events.select { |event| event.rsvp_for(@profile).present? }.first
    # if rsvped_for_event.present?
    #   redirect_to action: :registered, params: { event_id: rsvped_for_event.id, uuid: @profile.uuid }
    #   return
    # end
  end

  private

  def load_profile
    @profile = Profile.find(params[:uuid])
  rescue ActiveRecord::RecordNotFound
  end
end
