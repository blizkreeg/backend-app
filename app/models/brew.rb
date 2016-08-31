class Brew < ActiveRecord::Base
  has_many :brewings
  has_many :profiles, through: :brewings
end
