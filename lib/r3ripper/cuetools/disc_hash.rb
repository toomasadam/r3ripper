#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

module CUETools
  class DiscHash
    attr_reader :first_track, :track_count, :total_sectors, :start_sectors

    def initialize(disc)
      @disc = disc
      calculate_toc
    end

    def calculate_toc
      scan = @disc.respond_to?(:advancedTocScanner) ? @disc.advancedTocScanner : nil

      if scan && scan.respond_to?(:tracks) && scan.tracks > 0
        @first_track = scan.respond_to?(:firstAudioTrack) ? scan.firstAudioTrack : 1
        @track_count = scan.tracks
        @total_sectors = scan.totalSectors
        @start_sectors = (1..@track_count).map { |t| scan.getStartSector(t) }
      else
        @first_track = 1
        @track_count = 0
        @total_sectors = 0
        @start_sectors = []
      end
    end

    def toc_string
      return "" if @track_count == 0
      sectors_part = @start_sectors.join(':')
      "#{@first_track}:#{@track_count}:#{sectors_part}:#{@total_sectors}"
    end

    def url_path
      "lookup2.php?version=3&ctdb=1&metadata=ext&toc=#{toc_string}"
    end

    def full_url
      "http://db.cuetools.net/#{url_path}"
    end
  end
end
