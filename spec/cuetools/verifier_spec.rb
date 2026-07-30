#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/cuetools/verifier'

describe CUETools::Verifier do
  let(:db_entries) do
    [
      {
        confidence: 10,
        crc32: "a1b2c3d4",
        track_crcs: [0x11111111, 0x22222222]
      }
    ]
  end

  it "verifies matching track CRCs accurately" do
    verifier = CUETools::Verifier.new(db_entries)
    checksums = {
      1 => 0x11111111,
      2 => 0x22222222
    }

    res = verifier.verify(checksums)
    expect(res[1][:status]).to eq(:accurate)
    expect(res[1][:confidence]).to eq(10)
    expect(res[2][:status]).to eq(:accurate)
    expect(verifier.accurate_tracks_count).to eq(2)
    expect(verifier.overall_status).to eq(:accurate)
  end

  it "handles non-matching track CRCs" do
    verifier = CUETools::Verifier.new(db_entries)
    checksums = { 1 => 0x99999999 }

    res = verifier.verify(checksums)
    expect(res[1][:status]).to eq(:not_accurate)
    expect(res[1][:confidence]).to eq(0)
  end

  it "handles empty database entries" do
    verifier = CUETools::Verifier.new([])
    checksums = { 1 => 0x11111111 }

    res = verifier.verify(checksums)
    expect(res[1][:status]).to eq(:not_in_db)
  end
end
