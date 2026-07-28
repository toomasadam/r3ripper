require 'gtk3'
require 'r3ripper/gtk2/gtkNamingDialog'

describe GtkNamingDialog do
  describe '.render_sample_path' do
    it 'renders sample path for standard scheme' do
      path = GtkNamingDialog.render_sample_path('%a (%y) %b/%n - %t', 'standard', '~/Music')
      expect(path).to eq('~/Music/Pink Floyd (1973) The Dark Side of the Moon/01 - Speak to Me.flac')
    end

    it 'renders sample path for various artists scheme' do
      path = GtkNamingDialog.render_sample_path('%b/%n - %a - %t', 'various', '/home/user/Music')
      expect(path).to eq('/home/user/Music/Pulp Fiction (Music from the Motion Picture)/01 - Dick Dale & His Del-Tones - Misirlou.flac')
    end

    it 'renders sample path for single file image scheme' do
      path = GtkNamingDialog.render_sample_path('%a - %b', 'image', '~/Music')
      expect(path).to eq('~/Music/Pink Floyd - The Dark Side of the Moon')
    end
  end

  describe 'dialog UI' do
    it 'initializes dialog with initial scheme pattern' do
      dlg = GtkNamingDialog.new(nil, 'standard', '%a/%b/%n - %t')
      expect(dlg.scheme_type).to eq('standard')
      expect(dlg.instance_variable_get(:@entry_scheme).text).to eq('%a/%b/%n - %t')
    end

    it 'allows inserting tag variable at cursor position' do
      dlg = GtkNamingDialog.new(nil, 'standard', '%a/%b/')
      dlg.instance_variable_get(:@entry_scheme).position = 6
      dlg.send(:insert_tag, '%n')
      expect(dlg.instance_variable_get(:@entry_scheme).text).to eq('%a/%b/%n')
    end
  end
end
