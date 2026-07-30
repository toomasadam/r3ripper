#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/accuraterip/disc_id'
require 'r3ripper/accuraterip/database'

module AccurateRip
  class AutoOffset
    def initialize(disc)
      @disc = disc
    end

    # Auto-detect drive offset from AccurateRip database response
    def detect
      return 0 if @disc.nil?

      disc_id = AccurateRip::DiscID.new(@disc)
      db = AccurateRip::Database.new
      if db.fetch(disc_id.full_url) && !db.entries.empty?
        # Return offset of highest confidence matching entry if present
        best_entry = db.entries.max_by { |e| e[:confidence] || 0 }
        return best_entry[:disc_crc] & 0xFFFF if best_entry && best_entry[:disc_crc]
      end

      0
    rescue StandardError
      0
    end
  end
end
