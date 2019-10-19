# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Room, type: :model do
  context '#availability_between_dates' do
    it 'returns available dates' do
      dtstart = Date.iso8601('2019-10-18')
      dtend = Date.iso8601('2019-10-27')
      available_dates = Room.first.availability_between_dates(dtstart, dtend)
      expect(available_dates).to include_json({
        total_rooms: 10,
        start_date: '2019-10-18',
        end_date: '2019-10-27',
        payload: [
          {:allotment=>9, :date=>"2019-10-18"}, 
          {:allotment=>9, :date=>"2019-10-19"},
          {:allotment=>10, :date=>"2019-10-20"}, 
          {:allotment=>10, :date=>"2019-10-21"}, 
          {:allotment=>10, :date=>"2019-10-22"}, 
          {:allotment=>10, :date=>"2019-10-23"}, 
          {:allotment=>10, :date=>"2019-10-24"}, 
          {:allotment=>10, :date=>"2019-10-25"}, 
          {:allotment=>10, :date=>"2019-10-26"}, 
          {:allotment=>10, :date=>"2019-10-27"}]
      })
    end
  end
end
