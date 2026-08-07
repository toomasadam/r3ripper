#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026 r3ripper developers
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'net/http'
require 'uri'
require 'tmpdir'
require 'r3ripper/preferences/main'
require 'r3ripper/system/fileAndDir'

module Metadata
  class CoverArt
    CAA_BASE_URL = 'https://coverartarchive.org/release/'

    def initialize(prefs=nil, file_and_dir=nil)
      @prefs = prefs ? prefs : Preferences::Main.instance
      @file = file_and_dir ? file_and_dir : (FileAndDir.respond_to?(:instance) ? FileAndDir.instance : FileAndDir.new)
    end

    # Fetch front cover artwork for a given MusicBrainz Release MBID.
    # Returns path to local image file on success, or nil if disabled/failed.
    def fetch(release_mbid, output_dir=nil, filename=nil)
      return nil if release_mbid.nil? || release_mbid.to_s.empty?
      return nil if @prefs.respond_to?(:fetchCoverArt) && !@prefs.fetchCoverArt

      filename ||= (@prefs.respond_to?(:coverArtFilename) ? @prefs.coverArtFilename : 'cover.jpg')
      url = "#{CAA_BASE_URL}#{release_mbid}/front"

      image_data, content_type = download_image(url)
      return nil if image_data.nil? || image_data.empty?

      target_dir = output_dir || Dir.tmpdir
      target_path = File.join(target_dir, filename)

      begin
        File.open(target_path, 'wb') { |f| f.write(image_data) }
        puts "DEBUG: Cover art successfully saved to #{target_path}" if @prefs.respond_to?(:debug) && @prefs.debug
        target_path
      rescue => e
        puts "DEBUG: Failed to write cover art file #{target_path}: #{e.message}" if @prefs.respond_to?(:debug) && @prefs.debug
        nil
      end
    end

    private

    def download_image(url, limit = 5)
      return nil if limit <= 0

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 10
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = "RubyRipperReborn/#{$rr_version || '3.0'} ( https://github.com/toomasadam/r3ripper )"

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        return [response.body, response['content-type']]
      when Net::HTTPRedirection
        location = response['location']
        return nil if location.nil? || location.empty?
        download_image(location, limit - 1)
      else
        nil
      end
    rescue => e
      puts "DEBUG: Exception fetching cover art from #{url}: #{e.message}" if @prefs.respond_to?(:debug) && @prefs.debug
      nil
    end
  end
end
