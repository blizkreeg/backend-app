OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE unless Rails.env.production?

class EventsController < ApplicationController
  skip_before_action :authenticate_token!
  skip_before_action :set_current_profile

  before_action :load_profile

  layout 'events'

  def rsvp_stb
    session = GoogleDrive.saved_session("#{Rails.root}/config/gdrive.json")
    ws = session.spreadsheet_by_key("1JYr0UwPFgck9QbXV5LQr5I_JD2qHodnxGR1AWLL32aA").worksheets[0]

    # doc version stored at [1,2]
    rows = Rails.cache.fetch("stb_events_v#{ws[1,2]}", expires_in: 30.days) do
      rows = []
      (1..ws.num_rows).select do |row|
        next unless row >= 3
        rows << (1..11).to_a.map { |col| ws[row, col] }
      end
      rows
    end

    @events = []
    rows.each do |row|
      spots_remaining = @profile.male? ? (row[5].to_i - row[7].to_i) : (row[6].to_i - row[8].to_i)
      event_date = Date.parse(row[0])
      next if Date.today > event_date

      event = OpenStruct.new
      event.date = event_date
      event.time_str = row[1]
      event.place = row[2]
      event.addr = row[3]
      event.spots_remaining = spots_remaining
      event.id = row[9]
      event.photo = row[10]
      event.rsvp = EventRsvp.with_ident(event.id).where(profile_uuid: @profile.uuid).take
      event.going = event.rsvp.present? ? true : false
      event.attending = EventRsvp.with_ident(event.id).map(&:profile).flatten

      @events << event
    end
  end

  def register_stb
    if @event_rsvp = EventRsvp.with_ident(params[:event_id]).take
      @event_rsvp.update!(attending_status: params[:attending_status])
    else
      @event_rsvp = EventRsvp.create!(attending_status: params[:attending_status], ident: params[:event_id], profile_uuid: @profile.uuid)
    end

    @profile.reload

    redirect_to :back
  end

  def cancel_stb
    EventRsvp.find(params[:id]).destroy

    redirect_to :back
  end

  private

  def load_profile
    @profile = Profile.find(params[:uuid])
  end
end
