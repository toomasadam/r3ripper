#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/accuraterip/verifier'

describe AccurateRip::Verifier do
  let(:db_entries) do
    [
      {
        confidence: 12,
        track_count: 2,
        v1_crcs: [0x11111111, 0x22222222],
        v2_crcs: [0x33333333, 0x44444444]
      }
    ]
  end

  it "verifies matching v2 CRCs accurately" do
    verifier = AccurateRip::Verifier.new(db_entries)
    checksums = {
      1 => { v1: 0x11111111, v2: 0x33333333 },
      2 => { v1: 0x22222222, v2: 0x44444444 }
    }

    res = verifier.verify(checksums)
    expect(res[1][:status]).to eq(:accurate)
    expect(res[1][:version]).to eq(:v2)
    expect(res[1][:confidence]).to eq(12)
    expect(res[2][:status]).to eq(:accurate)
    expect(verifier.accurate_tracks_count).to eq(2)
    expect(verifier.overall_status).to eq(:accurate)
  end

  it "handles non-matching CRCs" do
    verifier = AccurateRip::Verifier.new(db_entries)
    checksums = {
      1 => { v1: 0x99999999, v2: 0x99999999 }
    }

    res = verifier.verify(checksums)
    expect(res[1][:status]).to eq(:not_accurate)
    expect(res[1][:confidence]).to eq(0)
    expect(verifier.accurate_tracks_count).to eq(0)
  end

  it "handles empty database entries" do
    verifier = AccurateRip::Verifier.new([])
    checksums = { 1 => { v1: 0x11111111, v2: 0x33333333 } }

    res = verifier.verify(checksums)
    expect(res[1][:status]).to eq(:not_in_db)
    expect(verifier.overall_status).to eq(:not_in_db)
  end
end
