#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/accuraterip/checksum'

describe AccurateRip::Checksum do
  let(:pcm_sample_data) { Array.new(1000) { rand(0..65535) }.pack('V*') }

  it "calculates AccurateRip v1 CRC" do
    crc_v1 = AccurateRip::Checksum.calculate_v1(pcm_sample_data, 1, 3)
    expect(crc_v1).to be_a(Integer)
    expect(crc_v1).to be >= 0
    expect(crc_v1).to be <= 0xFFFFFFFF
  end

  it "calculates AccurateRip v2 CRC" do
    crc_v2 = AccurateRip::Checksum.calculate_v2(pcm_sample_data, 1, 3)
    expect(crc_v2).to be_a(Integer)
    expect(crc_v2).to be >= 0
    expect(crc_v2).to be <= 0xFFFFFFFF
  end

  it "formats CRCs as 8-character hex strings" do
    hex = AccurateRip::Checksum.format_crc(0x9A8B7C6D)
    expect(hex).to eq("9A8B7C6D")
  end

  it "handles empty input safely" do
    expect(AccurateRip::Checksum.calculate_v1(nil, 1, 1)).to eq(0)
    expect(AccurateRip::Checksum.calculate_v2("", 1, 1)).to eq(0)
  end
end
