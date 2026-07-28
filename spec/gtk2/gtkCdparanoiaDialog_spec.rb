require 'r3ripper/gtk2/gtkCdparanoiaDialog'

describe GtkCdparanoiaDialog do
  describe '.parse_option_string' do
    it 'handles empty or nil input' do
      parsed = GtkCdparanoiaDialog.parse_option_string('')
      expect(parsed[:disable_extra]).to be false
      expect(parsed[:disable_all]).to be false
      expect(parsed[:disable_scratch]).to be false
      expect(parsed[:limit_speed]).to be false
      expect(parsed[:custom_overlap]).to be false
      expect(parsed[:custom_options]).to eq('')

      parsed_nil = GtkCdparanoiaDialog.parse_option_string(nil)
      expect(parsed_nil[:disable_extra]).to be false
    end

    it 'parses paranoia mode flags -Z, -Y, -X' do
      parsed = GtkCdparanoiaDialog.parse_option_string('-Z -X')
      expect(parsed[:disable_extra]).to be true
      expect(parsed[:disable_scratch]).to be true
      expect(parsed[:disable_all]).to be false

      parsed_y = GtkCdparanoiaDialog.parse_option_string('-Y')
      expect(parsed_y[:disable_all]).to be true
    end

    it 'parses speed limit flag -S with separate argument' do
      parsed = GtkCdparanoiaDialog.parse_option_string('-S 8')
      expect(parsed[:limit_speed]).to be true
      expect(parsed[:speed_value]).to eq(8)
    end

    it 'parses speed limit flag attached to flag e.g. -S4' do
      parsed = GtkCdparanoiaDialog.parse_option_string('-S4')
      expect(parsed[:limit_speed]).to be true
      expect(parsed[:speed_value]).to eq(4)
    end

    it 'parses custom overlap search sector flag -o' do
      parsed = GtkCdparanoiaDialog.parse_option_string('-o 15')
      expect(parsed[:custom_overlap]).to be true
      expect(parsed[:overlap_value]).to eq(15)
    end

    it 'collects unknown parameters into custom_options' do
      parsed = GtkCdparanoiaDialog.parse_option_string('-Z -S 8 -c --force-cdrom-little-endian')
      expect(parsed[:disable_extra]).to be true
      expect(parsed[:limit_speed]).to be true
      expect(parsed[:speed_value]).to eq(8)
      expect(parsed[:custom_options]).to eq('-c --force-cdrom-little-endian')
    end
  end

  describe '.format_option_string' do
    it 'formats paranoia flags' do
      res = GtkCdparanoiaDialog.format_option_string(disable_extra: true, disable_scratch: true)
      expect(res).to eq('-Z -X')
    end

    it 'prioritizes -Y over -Z and -X when disable_all is set' do
      res = GtkCdparanoiaDialog.format_option_string(disable_all: true, disable_extra: true, disable_scratch: true)
      expect(res).to eq('-Y')
    end

    it 'formats speed and overlap controls' do
      res = GtkCdparanoiaDialog.format_option_string(limit_speed: true, speed_value: 4, custom_overlap: true, overlap_value: 20)
      expect(res).to eq('-S 4 -o 20')
    end

    it 'appends custom parameters' do
      res = GtkCdparanoiaDialog.format_option_string(disable_extra: true, custom_options: '-c')
      expect(res).to eq('-Z -c')
    end
  end

  context 'with GTK widgets' do
    before(:all) do
      Gtk.init rescue nil
    end

    it 'populates dialog widgets from initial options string' do
      dialog_obj = GtkCdparanoiaDialog.new(nil, '-Z -S 12 -c')
      expect(dialog_obj.generate_options).to eq('-Z -S 12 -c')
    end

    it 'updates option string when setting options' do
      dialog_obj = GtkCdparanoiaDialog.new(nil, '')
      dialog_obj.parse_options('-Y -o 10')
      expect(dialog_obj.generate_options).to eq('-Y -o 10')
    end
  end
end
