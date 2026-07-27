require 'gtk3'
require 'rubyripper/gtk2/gtkPreferences'

describe GtkPreferences do
  let(:prefs) { double('Preferences::Main').as_null_object }
  let(:deps) { double('Dependency').as_null_object }

  before do
    allow(prefs).to receive(:cdrom).and_return('/dev/cdrom')
    allow(prefs).to receive(:offset).and_return(0)
    allow(prefs).to receive(:reqMatchesAll).and_return(2)
    allow(prefs).to receive(:reqMatchesErrors).and_return(1)
    allow(prefs).to receive(:maxTries).and_return(5)
    allow(prefs).to receive(:rippersettings).and_return('')
    allow(prefs).to receive(:site).and_return('http://gnudb.gnudb.org/~cddb/cddb.cgi')
    allow(prefs).to receive(:username).and_return('anonymous')
    allow(prefs).to receive(:hostname).and_return('my_secret.com')
    allow(prefs).to receive(:preferMusicBrainzCountries).and_return('US,UK,XW,XE,JP')
    allow(prefs).to receive(:preferMusicBrainzDate).and_return('earlier')
    allow(prefs).to receive(:useEarliestDate).and_return(true)
    allow(prefs).to receive(:minLengthHiddenTrack).and_return(2.0)
    allow(prefs).to receive(:maxThreads).and_return(2)
    allow(prefs).to receive(:basedir).and_return('~/')
    allow(prefs).to receive(:namingNormal).and_return('%a/%album/%tn - %t')
    allow(prefs).to receive(:namingVarious).and_return('%album/%tn - %a - %t')
    allow(prefs).to receive(:namingImage).and_return('%a - %album')
    allow(prefs).to receive(:codecs).and_return(['flac'])
    allow(prefs).to receive(:allCodecs).and_return(['flac', 'wavpack'])
    allow(prefs).to receive(:settingsFlac).and_return('-5')
  end

  it 'initializes GnuDB Options frame and controls correctly' do
    gtk_prefs = GtkPreferences.new(prefs, deps)
    gtk_prefs.start
    expect(gtk_prefs.instance_variable_get(:@frame91).label).to eq('GnuDB Options')
    expect(gtk_prefs.instance_variable_get(:@freedb_server_label).text).to eq('GnuDB server:')
    expect(gtk_prefs.instance_variable_get(:@firstHit).label).to eq('Always use first GnuDB hit')
  end

  it 'resets GnuDB server entry when Reset to Default button is clicked' do
    gtk_prefs = GtkPreferences.new(prefs, deps)
    gtk_prefs.start
    server_entry = gtk_prefs.instance_variable_get(:@freedbServerEntry)
    reset_button = gtk_prefs.instance_variable_get(:@resetGnudbServerButton)

    server_entry.text = 'http://custom.server.org/cddb'
    reset_button.clicked
    expect(server_entry.text).to eq('http://gnudb.gnudb.org/~cddb/cddb.cgi')
  end

  it 'uses labeled Remove push button and auto-adds codecs on dropdown selection' do
    gtk_prefs = GtkPreferences.new(prefs, deps)
    gtk_prefs.start
    codec_rows = gtk_prefs.instance_variable_get(:@codecRows)
    remove_button = codec_rows['flac'][2]
    expect(remove_button.label).to eq('Remove')

    add_combo = gtk_prefs.instance_variable_get(:@addCodecComboBox)
    expect(gtk_prefs.instance_variable_get(:@addCodecButton)).to be_nil

    expect(prefs).to receive(:wavpack=).with(true)
    add_combo.active = 1 # Select WavPack
    expect(codec_rows.key?('wavpack')).to be true
  end
end
