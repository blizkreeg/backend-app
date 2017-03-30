class Post < ActiveRecord::Base
  IMAGE_TYPE = 'image'
  VIDEO_TYPE = 'video'
  ARTICLE_TYPE = 'article'

  ATTRIBUTES = {
    title:              :string,
    excerpt:            :string,
    post_type:          :string,
    link_to_url:        :string,
    image_public_id:    :string,
    video_url:          :string,
    share_text:         :string,
    share_link:         :string,
    posted_on:          :date_time
  }

  scope :ordered_by_recent, -> { order("(properties->>'posted_on')::timestamp DESC") }

  jsonb_accessor :properties, ATTRIBUTES

  validates :title, :post_type, presence: true

  def image?
    self.post_type == IMAGE_TYPE
  end

  def video?
    self.post_type == VIDEO_TYPE
  end

  def article?
    self.post_type == ARTICLE_TYPE
  end

  def default_share_text
    "See this on ekCoffee: #{self.title} at "
  end
end
