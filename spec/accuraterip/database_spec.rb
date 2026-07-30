#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/accuraterip/database'

describe AccurateRip::Database do
  let(:mock_binary_data) do
    # Header: count = 5, track_count = 2, freedb_id = 0x12345678, disc_crc = 0x87654321
    # Followed by 2 track v1 CRCs, then 2 track v2 CRCs
    [5, 2].pack('C*') +
      [0x12345678, 0x87654321].pack('V*') +
      [0x11111111, 0x22222222].pack('V*') +
      [0x33333333, 0x44444444].pack('V*')
  end

  it "parses valid AccurateRip binary responses" do
    db = AccurateRip::Database.new(mock_binary_data)

    expect(db.entries.size).to eq(1)
    entry = db.entries.first
    expect(entry[:confidence]).to eq(5)
    expect(entry[:track_count]).to eq(2)
    expect(entry[:freedb_id]).to eq(0x12345678)
    expect(entry[:v1_crcs]).to eq([0x11111111, 0x22222222])
    expect(entry[:v2_crcs]).to eq([0x33333333, 0x44444444])
  end

  it "handles empty or corrupt binary data gracefully" do
    db = AccurateRip::Database.new("")
    expect(db.entries).to be_empty

    db_nil = AccurateRip::Database.new(nil)
    expect(db_nil.entries).to be_empty
  end
end
