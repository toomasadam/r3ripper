#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/cuetools/disc_hash'

describe CUETools::DiscHash do
  let(:disc) { double('Disc') }
  let(:scanner) { double('AdvancedTocScanner') }

  before(:each) do
    allow(disc).to receive(:advancedTocScanner).and_return(scanner)
    allow(scanner).to receive(:firstAudioTrack).and_return(1)
    allow(scanner).to receive(:tracks).and_return(3)
    allow(scanner).to receive(:totalSectors).and_return(45000)
    allow(scanner).to receive(:getStartSector).with(1).and_return(0)
    allow(scanner).to receive(:getStartSector).with(2).and_return(15000)
    allow(scanner).to receive(:getStartSector).with(3).and_return(30000)
  end

  it "calculates accurate TOC string" do
    disc_hash = CUETools::DiscHash.new(disc)

    expect(disc_hash.track_count).to eq(3)
    expect(disc_hash.total_sectors).to eq(45000)
    expect(disc_hash.toc_string).to eq("1:3:0:15000:30000:45000")
  end

  it "generates accurate query URL path and full URL" do
    disc_hash = CUETools::DiscHash.new(disc)

    expect(disc_hash.url_path).to eq("lookup2.php?version=3&ctdb=1&metadata=ext&toc=1:3:0:15000:30000:45000")
    expect(disc_hash.full_url).to eq("http://db.cuetools.net/lookup2.php?version=3&ctdb=1&metadata=ext&toc=1:3:0:15000:30000:45000")
  end
end
