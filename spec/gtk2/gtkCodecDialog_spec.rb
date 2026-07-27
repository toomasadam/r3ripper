require 'gtk3'
require 'rubyripper/gtk2/gtkCodecDialog'

describe GtkCodecDialog do
  describe '.parse_option_string' do
    it 'parses FLAC flags correctly' do
      parsed = GtkCodecDialog.parse_option_string('flac', '-8 -V')
      expect(parsed[:level]).to eq(8)
      expect(parsed[:verify]).to be true

      parsed_default = GtkCodecDialog.parse_option_string('flac', '')
      expect(parsed_default[:level]).to eq(5)
      expect(parsed_default[:verify]).to be false
    end

    it 'parses Opus flags correctly' do
      parsed = GtkCodecDialog.parse_option_string('opus', '--bitrate 256 --cvbr')
      expect(parsed[:bitrate]).to eq(256)
      expect(parsed[:vbr_mode]).to eq(:cvbr)
    end

    it 'parses MP3 flags correctly' do
      parsed_vbr = GtkCodecDialog.parse_option_string('mp3', '-V 0')
      expect(parsed_vbr[:mode]).to eq(:vbr)
      expect(parsed_vbr[:vbr_quality]).to eq(0)

      parsed_cbr = GtkCodecDialog.parse_option_string('mp3', '-b 320')
      expect(parsed_cbr[:mode]).to eq(:cbr)
      expect(parsed_cbr[:cbr_bitrate]).to eq(320)
    end

    it 'parses Ogg Vorbis quality flags' do
      parsed = GtkCodecDialog.parse_option_string('ogg', '-q 8')
      expect(parsed[:quality]).to eq(8)
    end

    it 'parses WavPack flags correctly' do
      parsed = GtkCodecDialog.parse_option_string('wavpack', '-h -v')
      expect(parsed[:compression]).to eq(:high)
      expect(parsed[:verify]).to be true
    end
  end

  describe '.format_option_string' do
    it 'formats FLAC option string' do
      formatted = GtkCodecDialog.format_option_string('flac', level: 8, verify: true, custom_options: '')
      expect(formatted).to eq('-8 -V')
    end

    it 'formats Opus option string' do
      formatted = GtkCodecDialog.format_option_string('opus', bitrate: 192, vbr_mode: :vbr, custom_options: '')
      expect(formatted).to eq('--bitrate 192 --vbr')
    end

    it 'formats MP3 VBR and CBR option strings' do
      vbr = GtkCodecDialog.format_option_string('mp3', mode: :vbr, vbr_quality: 0, custom_options: '')
      expect(vbr).to eq('-V 0')

      cbr = GtkCodecDialog.format_option_string('mp3', mode: :cbr, cbr_bitrate: 320, custom_options: '')
      expect(cbr).to eq('-b 320')
    end

    it 'formats WavPack option string' do
      wp = GtkCodecDialog.format_option_string('wavpack', compression: :very_high, verify: true, custom_options: '')
      expect(wp).to eq('-hh -v')
    end
  end

  describe 'dialog UI' do
    it 'initializes FLAC dialog with correct options' do
      dlg = GtkCodecDialog.new(nil, 'flac', '-7 -V')
      expect(dlg.codec).to eq('flac')
      expect(dlg.generate_options).to eq('-7 -V')
    end

    it 'initializes Opus dialog with correct options' do
      dlg = GtkCodecDialog.new(nil, 'opus', '--bitrate 128 --hard-vbr')
      expect(dlg.codec).to eq('opus')
      expect(dlg.generate_options).to eq('--bitrate 128 --hard-vbr')
    end
  end
end
