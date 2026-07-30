#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/accuraterip/disc_id'

describe AccurateRip::DiscID do
  let(:disc) { double('Disc') }
  let(:scanner) { double('AdvancedTocScanner') }

  before(:each) do
    allow(disc).to receive(:advancedTocScanner).and_return(scanner)
    allow(scanner).to receive(:tracks).and_return(3)
    allow(scanner).to receive(:totalSectors).and_return(45000)
    allow(scanner).to receive(:getStartSector).with(1).and_return(0)
    allow(scanner).to receive(:getStartSector).with(2).and_return(15000)
    allow(scanner).to receive(:getStartSector).with(3).and_return(30000)
  end

  it "calculates accurate disc IDs" do
    disc_id = AccurateRip::DiscID.new(disc)

    expect(disc_id.track_count).to eq(3)
    expect(disc_id.total_sectors).to eq(45000)
    expect(disc_id.disc_id_1).to be_a(Integer)
    expect(disc_id.disc_id_2).to be_a(Integer)
    expect(disc_id.cddb_disc_id).to be_a(Integer)
  end

  it "generates accurate ID string and query URL path" do
    disc_id = AccurateRip::DiscID.new(disc)

    expect(disc_id.id_string).to match(/\A[0-9a-f]{8}-[0-9a-f]{8}-[0-9a-f]{8}\z/)
    expect(disc_id.url_path).to match(%r{\Aaccuraterip/[0-9a-f]/[0-9a-f]/[0-9a-f]/dsv-[0-9a-f]{8}-[0-9a-f]{8}-[0-9a-f]{8}\.bin\z})
    expect(disc_id.full_url).to start_with("http://www.accuraterip.com/accuraterip/")
  end
end
