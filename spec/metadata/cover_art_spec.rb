#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026 r3ripper developers
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/metadata/cover_art'

describe Metadata::CoverArt do
  let(:prefs) { double('Preferences', fetchCoverArt: true, coverArtFilename: 'cover.jpg', debug: false) }
  let(:cover_art) { Metadata::CoverArt.new(prefs) }

  context "when fetching cover artwork" do
    it "returns nil if release_mbid is nil or empty" do
      expect(cover_art.fetch(nil)).to be_nil
      expect(cover_art.fetch("")).to be_nil
    end

    it "returns nil if fetchCoverArt preference is false" do
      allow(prefs).to receive(:fetchCoverArt).and_return(false)
      expect(cover_art.fetch("12345678-1234-1234-1234-123456789abc")).to be_nil
    end

    it "downloads image and saves it to specified destination when successful" do
      mbid = "12345678-1234-1234-1234-123456789abc"
      fake_image_bytes = "fake_jpeg_image_data"
      
      http_instance = instance_double(Net::HTTP)
      response = Net::HTTPSuccess.new('1.1', '200', 'OK')
      allow(response).to receive(:body).and_return(fake_image_bytes)
      allow(response).to receive(:[]).with('content-type').and_return('image/jpeg')
      
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:open_timeout=)
      allow(http_instance).to receive(:read_timeout=)
      allow(http_instance).to receive(:request).and_return(response)

      Dir.mktmpdir do |tmpdir|
        result = cover_art.fetch(mbid, tmpdir, 'folder.jpg')
        expect(result).to eq(File.join(tmpdir, 'folder.jpg'))
        expect(File.exist?(result)).to be true
        expect(File.read(result)).to eq(fake_image_bytes)
      end
    end
  end
end
