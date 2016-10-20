class Post < ActiveRecord::Base
  IMAGE_TYPE = 'image'
  VIDEO_TYPE = 'video'
  ARTICLE_TYPE = 'article'

  ATTRIBUTES = {
    title:              :string,
    excerpt:            :string,
    type:               :string,
    link_to_url:        :string,
    image_public_id:    :string,
    video_url:          :string,
    share_text:         :string,
    posted_on:          :date_time
  }

  scope :ordered_by_recent, -> { order("(properties->>'posted_on')::timestamp DESC") }

  jsonb_accessor :properties, ATTRIBUTES

  validates :title, :type, presence: true

  def image?
    self.type == IMAGE_TYPE
  end

  def video?
    self.type == VIDEO_TYPE
  end

  def article?
    self.type == ARTICLE_TYPE
  end

  def default_share_text
    "See this on ekCoffee: #{self.title} at http://blog.ekcoffee.com/"
  end
end
