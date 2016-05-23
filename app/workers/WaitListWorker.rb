class WaitListWorker
  include Sidekiq::Worker

  def perform(phone, lat, lng, city, country)
    # list maintained at:
    # https://docs.google.com/spreadsheets/d/1VTFL3MaErhYVq2C49yBKp5P-HMte2r6f4Pz0ujOgsWE/
    session = GoogleDrive.saved_session("#{Rails.root}/config/gdrive.json")
    ws = session.spreadsheet_by_key("1VTFL3MaErhYVq2C49yBKp5P-HMte2r6f4Pz0ujOgsWE").worksheets[0]

    row = ws.num_rows + 1
    col = 0
    ws[row, col+=1] = city
    ws[row, col+=1] = country
    ws[row, col+=1] = "'#{phone}"
    ws[row, col+=1] = lat
    ws[row, col+=1] = lng
    ws[row, col+=1] = Date.today
    ws[row, col+=1] = Rails.env
    ws.save

    EKC.logger.info "Added to waiting list; lat: #{lat}, lon: #{lng}, mobile: #{phone}"
  end
end
