class GoogleSheet
  mattr_reader :session
  attr_accessor :gsheet, :id, :worksheet, :cache_key, :cache_key_expires_in

  DOC_VERSION_STRING = "Version"
  DOC_VERSION_ROW = 1
  DOC_VERSION_COL = 2
  PROD_WORKSHEET = 0
  TEST_WORKSHEET = 1
  DEV_WORKSHEET = 2

  def self.set_session
    @@session = GoogleDrive.saved_session("#{Rails.root}/config/gdrive.json")
  end

  def self.session
    @@session
  end

  def self.default_worksheet
    case Rails.env
    when 'production'
      PROD_WORKSHEET
    when 'test'
      TEST_WORKSHEET
    when 'development'
      DEV_WORKSHEET
    else
      DEV_WORKSHEET
    end
  end

  def initialize(key, worksheet_num=nil, options={})
    @id = key
    @worksheet = worksheet_num || GoogleSheet.default_worksheet
    @cache_key_expires_in = options[:cache_key_expires_in] || 7.days
    @gsheet = GoogleSheet.session.spreadsheet_by_key(@id).worksheets[@worksheet]
    version = @gsheet[DOC_VERSION_ROW, 1] == "Version" ? @gsheet[DOC_VERSION_ROW, DOC_VERSION_COL] : 0
    @cache_key = [@id, (options[:cache_key] || ''), "v#{version}"].join('_')
  end

  def rows(skip_rows=nil)
    skip_rows ||= 0

    Rails.cache.fetch(@cache_key, expires_in: @cache_key_expires_in) do
      @gsheet.rows[skip_rows..-1]
    end
  end

  def next_row
    (@gsheet.num_rows || 0) + 1
  end

  def insert_row(values)
    row = self.next_row
    values.to_enum.with_index(1).each do |value, idx|
      @gsheet[row, idx] = value
    end
    self.save
  end

  def save
    @gsheet.save
    @gsheet.reload
  end

  set_session
end
