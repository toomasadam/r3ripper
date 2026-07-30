#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'net/http'
require 'uri'

module AccurateRip
  class Database
    attr_reader :raw_data, :entries

    def initialize(raw_data = nil)
      @raw_data = raw_data
      @entries = []
      parse(@raw_data) if @raw_data
    end

    def fetch(url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess) && response.body
        @raw_data = response.body
        parse(@raw_data)
        true
      else
        @entries = []
        false
      end
    rescue StandardError => e
      @entries = []
      false
    end

    # Parse binary payload from AccurateRip server
    def parse(binary_data)
      @entries = []
      return if binary_data.nil? || binary_data.bytesize < 12

      bytes = binary_data.bytes
      offset = 0

      while offset + 12 <= bytes.size
        # Each entry block header: count (1 byte), track_count (1 byte), freedb_id (4 bytes), offset_val (4 bytes)
        count = bytes[offset]
        track_count = bytes[offset + 1]
        
        break if track_count.nil? || track_count == 0

        # Unpack 32-bit little endian fields
        freedb_id = binary_data[offset + 2, 4].unpack1('V') rescue 0
        disc_crc = binary_data[offset + 6, 4].unpack1('V') rescue 0
        
        offset += 10
        v1_crcs = []
        v2_crcs = []

        (1..track_count).each do
          break if offset + 4 > bytes.size
          v1_crcs << binary_data[offset, 4].unpack1('V')
          offset += 4
        end

        (1..track_count).each do
          break if offset + 4 > bytes.size
          v2_crcs << binary_data[offset, 4].unpack1('V')
          offset += 4
        end

        @entries << {
          confidence: count,
          track_count: track_count,
          freedb_id: freedb_id,
          disc_crc: disc_crc,
          v1_crcs: v1_crcs,
          v2_crcs: v2_crcs
        }
      end

      @entries
    end
  end
end
