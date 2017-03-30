class Interest < ActiveRecord::Base
  has_many :profile_interests, dependent: :destroy
  has_many :profiles, through: :profile_interests

  ATTRIBUTES = {
    name: :string,
    description: :string,
    has_community: :boolean,
    community_name: :string
  }

  jsonb_accessor :properties, ATTRIBUTES
end
