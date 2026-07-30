#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

require 'r3ripper/accuraterip/auto_offset'

describe AccurateRip::AutoOffset do
  let(:disc) { double('Disc') }

  it "returns zero offset when disc is nil or lookup fails" do
    auto_offset = AccurateRip::AutoOffset.new(nil)
    expect(auto_offset.detect).to eq(0)
  end
end
