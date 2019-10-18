# frozen_string_literal: true

require 'rails_helper'
require 'date'

RSpec.describe Room, type: :model do
  context '#availability_between_dates' do
    it 'returns available dates' do
      dtstart = Date.iso8601('2019-10-01')
      dtend = Date.iso8601('2019-10-30')
      available_dates = Room.first.availability_between_dates(dtstart, dtend)
      expect(available_dates).to eql([{:allotment=>10, :date=>"2019-10-01"}, {:allotment=>10, :date=>"2019-10-02"},
                                      {:allotment=>10, :date=>"2019-10-03"}, {:allotment=>10, :date=>"2019-10-04"},
                                      {:allotment=>10, :date=>"2019-10-05"}, {:allotment=>10, :date=>"2019-10-06"},
                                      {:allotment=>10, :date=>"2019-10-07"}, {:allotment=>10, :date=>"2019-10-08"},
                                      {:allotment=>10, :date=>"2019-10-09"}, {:allotment=>10, :date=>"2019-10-10"},
                                      {:allotment=>9, :date=>"2019-10-11"}, {:allotment=>10, :date=>"2019-10-12"}, {:allotment=>9, :date=>"2019-10-13"},
                                      {:allotment=>10, :date=>"2019-10-14"}, {:allotment=>10, :date=>"2019-10-15"}, {:allotment=>9, :date=>"2019-10-16"},
                                      {:allotment=>9, :date=>"2019-10-17"}, {:allotment=>9, :date=>"2019-10-18"}, {:allotment=>9, :date=>"2019-10-19"},
                                      {:allotment=>10, :date=>"2019-10-20"}, {:allotment=>10, :date=>"2019-10-21"}, {:allotment=>10, :date=>"2019-10-22"}, 
                                      {:allotment=>10, :date=>"2019-10-23"}, {:allotment=>10, :date=>"2019-10-24"}, {:allotment=>10, :date=>"2019-10-25"}, 
                                      {:allotment=>10, :date=>"2019-10-26"}, {:allotment=>10, :date=>"2019-10-27"}, {:allotment=>10, :date=>"2019-10-28"},
                                      {:allotment=>10, :date=>"2019-10-29"}, {:allotment=>10, :date=>"2019-10-30"}],
                                     )
    end
  end
end
