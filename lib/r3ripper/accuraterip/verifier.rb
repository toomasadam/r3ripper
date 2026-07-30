#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/accuraterip/checksum'

module AccurateRip
  class Verifier
    attr_reader :db_entries, :results

    def initialize(db_entries = [])
      @db_entries = db_entries || []
      @results = {}
    end

    # Verify track checksums against database entries
    # track_checksums: Hash with key = track_number, value = { v1: int_crc, v2: int_crc }
    def verify(track_checksums)
      @results = {}

      if @db_entries.nil? || @db_entries.empty?
        track_checksums.each_key do |track_num|
          @results[track_num] = {
            status: :not_in_db,
            confidence: 0,
            version: nil,
            v1_crc: track_checksums[track_num][:v1],
            v2_crc: track_checksums[track_num][:v2]
          }
        end
        return @results
      end

      track_checksums.each do |track_num, crcs|
        v1_calc = crcs[:v1]
        v2_calc = crcs[:v2]
        track_idx = track_num - 1

        best_match = nil
        highest_confidence = 0

        @db_entries.each do |entry|
          confidence = entry[:confidence] || 1
          v1_expected = entry[:v1_crcs][track_idx] rescue nil
          v2_expected = entry[:v2_crcs][track_idx] rescue nil

          if v2_calc && v2_expected && v2_calc == v2_expected
            if confidence > highest_confidence || best_match.nil?
              best_match = { status: :accurate, version: :v2, confidence: confidence }
              highest_confidence = confidence
            end
          elsif v1_calc && v1_expected && v1_calc == v1_expected
            if confidence > highest_confidence || (best_match.nil? || best_match[:version] != :v2)
              best_match = { status: :accurate, version: :v1, confidence: confidence }
              highest_confidence = confidence
            end
          end
        end

        if best_match
          @results[track_num] = {
            status: :accurate,
            confidence: best_match[:confidence],
            version: best_match[:version],
            v1_crc: v1_calc,
            v2_crc: v2_calc
          }
        else
          @results[track_num] = {
            status: :not_accurate,
            confidence: 0,
            version: nil,
            v1_crc: v1_calc,
            v2_crc: v2_calc
          }
        end
      end

      @results
    end

    def accurate_tracks_count
      @results.values.count { |res| res[:status] == :accurate }
    end

    def total_tracks_count
      @results.size
    end

    def overall_status
      return :not_in_db if @db_entries.empty?
      return :accurate if accurate_tracks_count == total_tracks_count && total_tracks_count > 0
      :partially_accurate
    end
  end
end
