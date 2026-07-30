#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/cuetools/client'

describe CUETools::Client do
  let(:xml_data) do
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <ctdbresponse>
        <ctdb id="1" confidence="8" crc32="a1b2c3d4" trackcrcs="11111111 22222222 33333333"/>
      </ctdbresponse>
    XML
  end

  it "parses CTDB response XML correctly" do
    client = CUETools::Client.new(xml_data)

    expect(client.entries.size).to eq(1)
    entry = client.entries.first
    expect(entry[:confidence]).to eq(8)
    expect(entry[:crc32]).to eq("a1b2c3d4")
    expect(entry[:track_crcs]).to eq([0x11111111, 0x22222222, 0x33333333])
  end

  it "handles empty XML input safely" do
    client = CUETools::Client.new("")
    expect(client.entries).to be_empty
  end
end
