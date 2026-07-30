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

module CUETools
  class Client
    attr_reader :raw_xml, :entries

    def initialize(raw_xml = nil)
      @raw_xml = raw_xml
      @entries = []
      parse(@raw_xml) if @raw_xml
    end

    def fetch(url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess) && response.body
        @raw_xml = response.body
        parse(@raw_xml)
        true
      else
        @entries = []
        false
      end
    rescue StandardError => e
      @entries = []
      false
    end

    # Parse XML response from db.cuetools.net
    def parse(xml_content)
      @entries = []
      return if xml_content.nil? || xml_content.empty?

      # Parse ctdb elements using regex matching (avoids heavy XML gem dependency)
      xml_content.scan(/<ctdb\s+([^>]+)>/i) do |match|
        attrs_str = match[0]
        confidence = parse_attr(attrs_str, 'confidence').to_i
        crc32_hex = parse_attr(attrs_str, 'crc32')
        trackcrcs_str = parse_attr(attrs_str, 'trackcrcs')

        track_crcs = trackcrcs_str.empty? ? [] : trackcrcs_str.split(/\s+/).map { |hex| hex.to_i(16) }

        @entries << {
          confidence: confidence,
          crc32: crc32_hex,
          track_crcs: track_crcs
        }
      end

      @entries
    end

    private

    def parse_attr(str, attr_name)
      if str =~ /#{attr_name}=["']([^"']+)["']/i
        $1
      else
        ""
      end
    end
  end
end
