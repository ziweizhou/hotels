# frozen_string_literal: true

class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room, optional: true
  belongs_to :room_type
  belongs_to :user

  belongs_to :parent, class_name: 'Booking', optional: true
  has_many :children, class_name: 'Booking', foreign_key: :parent_booking_id
end
