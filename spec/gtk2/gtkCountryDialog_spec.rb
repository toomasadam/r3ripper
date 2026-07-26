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

    it 'adds selected country from available view when calling add_selected_country' do
      dialog_obj = GtkCountryDialog.new(nil, 'US')
      view = dialog_obj.instance_variable_get(:@available_view)
      avail_store = dialog_obj.instance_variable_get(:@available_store)

      first_iter = avail_store.iter_first
      view.selection.select_iter(first_iter)

      dialog_obj.send(:add_selected_country)

      expect(dialog_obj.generate_country_string).to eq('US,XW')
    end

    it 'removes selected country from preferred view when calling remove_selected_country' do
      dialog_obj = GtkCountryDialog.new(nil, 'US, GB, JP')
      preferred_view = dialog_obj.instance_variable_get(:@preferred_view)
      preferred_store = dialog_obj.instance_variable_get(:@preferred_store)

      first_iter = preferred_store.iter_first
      preferred_view.selection.select_iter(first_iter)

      dialog_obj.send(:remove_selected_country)

      expect(dialog_obj.generate_country_string).to eq('GB,JP')
    end

    it 'reorders countries up and down in preferred view' do
      dialog_obj = GtkCountryDialog.new(nil, 'US, GB, JP')
      preferred_view = dialog_obj.instance_variable_get(:@preferred_view)
      preferred_store = dialog_obj.instance_variable_get(:@preferred_store)

      second_path = Gtk::TreePath.new("1")
      second_iter = preferred_store.get_iter(second_path)
      preferred_view.selection.select_iter(second_iter)

      dialog_obj.send(:move_selected_up)
      expect(dialog_obj.generate_country_string).to eq('GB,US,JP')

      dialog_obj.send(:move_selected_down)
      expect(dialog_obj.generate_country_string).to eq('US,GB,JP')
    end

    it 'updates rank numbers correctly using safe iteration' do
      dialog_obj = GtkCountryDialog.new(nil, 'US, GB, JP, DE')
      preferred_store = dialog_obj.instance_variable_get(:@preferred_store)

      ranks = []
      preferred_store.each { |_m, _p, iter| ranks << iter[0] }
      expect(ranks).to eq(['1', '2', '3', '4'])
    end
  end
end
