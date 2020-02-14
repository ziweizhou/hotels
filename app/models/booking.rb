# frozen_string_literal: true

class Booking < ApplicationRecord
  belongs_to :house
  belongs_to :room, optional: true
  belongs_to :room_unit, optional: true
  # belongs_to :room_type
  belongs_to :user

  belongs_to :parent, class_name: 'Booking', optional: true
  has_many :children, class_name: 'Booking', foreign_key: :parent_booking_id

  scope :in_between, -> start_date, end_date {
    where(
      arel_table[:dtstart].lt(start_date).and(arel_table[:dtend].gteq(end_date)).or(
        arel_table[:dtstart].between(start_date..end_date).or(
          arel_table[:dtend].between((start_date + 1.day)..(end_date + 1.day))
        )
      )
    )
  }

  scope :confirmed, -> { where(status: :confirmed) }
  scope :assigned, -> { where(room_unit_id: nil) }
  scope :unassigned, -> { where.not(room_unit_id: nil) }
end
