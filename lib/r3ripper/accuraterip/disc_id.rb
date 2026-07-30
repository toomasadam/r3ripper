#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

module AccurateRip
  class DiscID
    attr_reader :disc_id_1, :disc_id_2, :cddb_disc_id, :track_count, :total_sectors

    def initialize(disc)
      @disc = disc
      calculate_ids
    end

    def calculate_ids
      scan = @disc.respond_to?(:advancedTocScanner) ? @disc.advancedTocScanner : nil
      
      if scan && scan.respond_to?(:tracks) && scan.tracks > 0
        @track_count = scan.tracks
        @total_sectors = scan.totalSectors
        start_sectors = (1..@track_count).map { |t| scan.getStartSector(t) }
      else
        @track_count = 0
        @total_sectors = 0
        start_sectors = []
      end

      # AccurateRip Disc ID Calculations
      sum_1 = 0
      sum_2 = 0
      
      start_sectors.each_with_index do |sector, idx|
        track_num = idx + 1
        sum_1 += sector
        sum_2 += sector * track_num
      end

      # Add leadout sector
      sum_1 += @total_sectors
      sum_2 += @total_sectors * (@track_count + 1)

      @disc_id_1 = sum_1 & 0xFFFFFFFF
      @disc_id_2 = sum_2 & 0xFFFFFFFF

      # CDDB / FreeDB disc ID calculation
      cddb_checksum = 0
      start_sectors.each do |sector|
        seconds = (sector + 150) / 75
        seconds.to_s.each_char { |c| cddb_checksum += c.to_i }
      end
      total_seconds = (@total_sectors + 150) / 75
      @cddb_disc_id = (((cddb_checksum % 0xFF) << 24) | (total_seconds << 8) | @track_count) & 0xFFFFFFFF
    end

    def id_string
      "%08x-%08x-%08x" % [@disc_id_1, @disc_id_2, @cddb_disc_id]
    end

    def url_path
      id_str = id_string
      cddb_hex = "%08x" % @cddb_disc_id
      x = cddb_hex[-1]
      y = cddb_hex[-2]
      z = cddb_hex[-3]
      "accuraterip/#{x}/#{y}/#{z}/dsv-#{id_str}.bin"
    end

    def full_url
      "http://www.accuraterip.com/#{url_path}"
    end
  end
end
