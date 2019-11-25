require 'date'
class Room < ApplicationRecord
  include ActiveRecord::Sanitization
  belongs_to :house
  belongs_to :room_type
  has_many :room_units
  has_many :units, through: :room_units
  has_many :bookings
end
