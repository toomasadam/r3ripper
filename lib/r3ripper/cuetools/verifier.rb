#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

module CUETools
  class Verifier
    attr_reader :db_entries, :results

    def initialize(db_entries = [])
      @db_entries = db_entries || []
      @results = {}
    end

    # Verify track checksums against CTDB entries
    # track_checksums: Hash with key = track_number, value = int_crc or { v1: int_crc }
    def verify(track_checksums)
      @results = {}

      if @db_entries.nil? || @db_entries.empty?
        track_checksums.each_key do |track_num|
          crc_val = track_checksums[track_num].is_a?(Hash) ? track_checksums[track_num][:v1] : track_checksums[track_num]
          @results[track_num] = {
            status: :not_in_db,
            confidence: 0,
            crc: crc_val
          }
        end
        return @results
      end

      track_checksums.each do |track_num, crcs|
        calc_crc = crcs.is_a?(Hash) ? crcs[:v1] : crcs
        track_idx = track_num - 1

        best_match = nil
        highest_confidence = 0

        @db_entries.each do |entry|
          confidence = entry[:confidence] || 1
          expected_crc = entry[:track_crcs][track_idx] rescue nil

          if calc_crc && expected_crc && calc_crc == expected_crc
            if confidence > highest_confidence || best_match.nil?
              best_match = { status: :accurate, confidence: confidence }
              highest_confidence = confidence
            end
          end
        end

        if best_match
          @results[track_num] = {
            status: :accurate,
            confidence: best_match[:confidence],
            crc: calc_crc
          }
        else
          @results[track_num] = {
            status: :not_accurate,
            confidence: 0,
            crc: calc_crc
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
