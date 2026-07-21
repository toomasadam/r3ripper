require 'rubyripper/waveFile'

describe WaveFile do

  context "with a valid wave file as input" do
    before(:each) do
      # Create a fake wave file for testing
      # 588 samples = 1 sector
      @path = '/tmp/test.wav'
      # 4 sectors of data
      # sector 0: 01 02
      # sector 1: 03 04
      # sector 2: 05 06
      # sector 3: 07 08
      @data = ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2)) +
              ("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2)) +
              ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
              ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2))

      # RIFF header (44 bytes)
      @header = "RIFF" + [(44 + 588 * 4 - 8)].pack('V') + "WAVEfmt " +
                [16].pack('V') + [1].pack('v') + [2].pack('v') +
                [44100].pack('V') + [44100 * 4].pack('V') +
                [4].pack('v') + [16].pack('v') + "data" +
                [588 * 4].pack('V')

      File.open(@path, 'wb') { |f| f.write(@header + @data) }
      @waveFile1 = WaveFile.new(@path)

      # a second one for splicing
      @path2 = '/tmp/test2.wav'
      @data2 = ("\x10\x10\x10\x10\x20\x20\x20\x20" * (588 / 2))
      @header2 = "RIFF" + [(44 + 588 - 8)].pack('V') + "WAVEfmt " +
                 [16].pack('V') + [1].pack('v') + [2].pack('v') +
                 [44100].pack('V') + [44100 * 4].pack('V') +
                 [4].pack('v') + [16].pack('v') + "data" +
                 [588].pack('V')
      File.open(@path2, 'wb') { |f| f.write(@header2 + @data2) }
      @waveFile2 = WaveFile.new(@path2)
    end

    after(:each) do
      File.delete(@path) if @path && File.exist?(@path)
      File.delete(@path2) if @path2 && File.exist?(@path2)
    end

    it "should read individual sectors correctly" do
      expect(@waveFile1.read(0)).to eq("\x01\x01\x01\x01\x02\x02\x02\x02" * (588/2))
      expect(@waveFile1.read(1)).to eq("\x03\x03\x03\x03\x04\x04\x04\x04" * (588/2))
      expect(@waveFile1.read(2)).to eq("\x05\x05\x05\x05\x06\x06\x06\x06" * (588/2))
      expect(@waveFile1.read(3)).to eq("\x07\x07\x07\x07\x08\x08\x08\x08" * (588/2))
    end

    it "should return all of its data with audioData" do
      expect(@waveFile1.audioData).to eq(
        ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2)) +
        ("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2)) +
        ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
        ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2))
      )
    end

    it "should know how many sectors it has" do
      expect(@waveFile1.numSectors).to eq(4)
    end

    context "with a positive offset" do
      before(:each) do
        @waveFile1.offset = 3
      end

      it "should trim samples from the start and pad the end" do
        expect(@waveFile1.audioData).to eq(
          ("\x02\x02\x02\x02" +
           ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2 - 2)) +
           ("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2)) +
           ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
           ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2)) +
           ("\x00\x00\x00\x00" * 3))
        )
      end

      it "should correct the wave file sizes on save! when padMissingSamples false" do
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector minus trimmed offset (3 samples * 4 bytes = 12 bytes), plus 36 for header
        expect(writtenData[4..7].unpack('V')[0]).to eq(2352 * 4 - 12 + 36)
        # 2352 bytes/sector minus 12 bytes
        expect(writtenData[40..43].unpack('V')[0]).to eq(2352 * 4 - 12)
      end

      it "should not correct wave file sizes on save! when padMissingSamples true" do
        @waveFile1.padMissingSamples = true
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header
        expect(writtenData[4..7].unpack('V')[0]).to eq((2352 * 4 + 36))
        # 2352 bytes/sector
        expect(writtenData[40..43].unpack('V')[0]).to eq((2352 * 4))
      end
    end

    context "with a negative offset" do
      before(:each) do
        @waveFile1.offset = -3
      end

      it "should trim samples from the end and pad the start" do
        expect(@waveFile1.audioData).to eq(
          (("\x00\x00\x00\x00" * 3) +
           ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2)) +
           ("\x03\x03\x03\x03\x04\x04\x04\x04" * (588 / 2)) +
           ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
           ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2 - 2) +
            "\x07\x07\x07\x07"))
        )
      end

      it "should correct the wave file sizes on save! when padMissingSamples false" do
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector minus trimmed offset (12 bytes), plus 36 for header
        expect(writtenData[4..7].unpack('V')[0]).to eq(2352 * 4 - 12 + 36)
        # 2352 bytes/sector minus 12 bytes
        expect(writtenData[40..43].unpack('V')[0]).to eq(2352 * 4 - 12)
      end

      it "should not correct wave file sizes on save! when padMissingSamples true" do
        @waveFile1.padMissingSamples = true
        @waveFile1.save!
        writtenData = File.binread(@waveFile1.path)
        # 2352 bytes/sector, plus 36 for header
        expect(writtenData[4..7].unpack('V')[0]).to eq((2352 * 4 + 36))
        # 2352 bytes/sector
        expect(writtenData[40..43].unpack('V')[0]).to eq((2352 * 4))
      end
    end

    context "when splicing" do
      it "should replace with the data of another WaveFile object" do
        @waveFile1.splice(1, @waveFile2.read(0))
        expect(@waveFile1.audioData).to eq(
          ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2)) +
          ("\x10\x10\x10\x10\x20\x20\x20\x20" * (588 / 2)) +
          ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2)) +
          ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2))
        )

        @waveFile1.save!
        expect(File.size(@waveFile1.path)).to eq(2352 * 4 + 44)
      end

      it "should replace the offset sector with the data" do
        @waveFile1.offset = 3
        @waveFile1.splice(1, @waveFile2.read(0))
        expect(@waveFile1.audioData).to eq(
          ("\x02\x02\x02\x02" +
           ("\x01\x01\x01\x01\x02\x02\x02\x02" * (588 / 2 - 2)) +
           ("\x03\x03\x03\x03\x04\x04\x04\x04\x03\x03\x03\x03") +
           ("\x10\x10\x10\x10\x20\x20\x20\x20" * (588 / 2)) +
           "\x06\x06\x06\x06" +
           ("\x05\x05\x05\x05\x06\x06\x06\x06" * (588 / 2 - 2)) +
           ("\x07\x07\x07\x07\x08\x08\x08\x08" * (588 / 2)) +
           ("\x00\x00\x00\x00" * 3))
        )
      end
    end
  end
end
