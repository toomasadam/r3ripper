require 'rubyripper/gtk2/gtkCountryDialog'

describe GtkCountryDialog do
  describe '.parse_country_string' do
    it 'handles empty or nil input' do
      expect(GtkCountryDialog.parse_country_string('')).to eq([])
      expect(GtkCountryDialog.parse_country_string(nil)).to eq([])
    end

    it 'parses comma and space separated country codes' do
      res = GtkCountryDialog.parse_country_string('US, UK, XW, XE, JP')
      expect(res).to eq(['US', 'GB', 'XW', 'XE', 'JP'])
    end

    it 'maps UK to GB alias' do
      res = GtkCountryDialog.parse_country_string('UK')
      expect(res).to eq(['GB'])
    end

    it 'removes duplicate codes' do
      res = GtkCountryDialog.parse_country_string('US, US, GB, US')
      expect(res).to eq(['US', 'GB'])
    end
  end

  describe '.format_country_string' do
    it 'formats array of country codes to comma separated string' do
      res = GtkCountryDialog.format_country_string(['US', 'GB', 'XW', 'XE'])
      expect(res).to eq('US,GB,XW,XE')
    end

    it 'handles empty array or nil' do
      expect(GtkCountryDialog.format_country_string([])).to eq('')
      expect(GtkCountryDialog.format_country_string(nil)).to eq('')
    end
  end

  describe '.country_name_for_code' do
    it 'returns mapped country names' do
      expect(GtkCountryDialog.country_name_for_code('US')).to eq('United States')
      expect(GtkCountryDialog.country_name_for_code('XW')).to eq('Worldwide')
      expect(GtkCountryDialog.country_name_for_code('JP')).to eq('Japan')
    end

    it 'provides a fallback label for unknown codes' do
      expect(GtkCountryDialog.country_name_for_code('ZZ')).to include('ZZ')
    end
  end

  context 'with GTK widgets' do
    before(:all) do
      Gtk.init rescue nil
    end

    it 'loads initial country string into preferred store' do
      dialog_obj = GtkCountryDialog.new(nil, 'US, GB, JP')
      expect(dialog_obj.generate_country_string).to eq('US,GB,JP')
    end

    it 'allows re-loading countries string' do
      dialog_obj = GtkCountryDialog.new(nil, '')
      dialog_obj.load_countries('DE, FR, CA')
      expect(dialog_obj.generate_country_string).to eq('DE,FR,CA')
    end
  end
end
