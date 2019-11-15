class House < ApplicationRecord
  has_many :room_types
  has_many :rooms
  has_many :units
end
