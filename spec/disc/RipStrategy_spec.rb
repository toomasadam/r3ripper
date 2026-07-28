require 'r3ripper/disc/ripStrategy'
require 'r3ripper/datamodel/disc'

describe RipStrategy do

  let(:prefs) {double('Preferences')}

  context 'When no special attributes are there' do
    it 'should be able to create a new instance' do
      disc = Datamodel::Disc.new()
      strategy = RipStrategy.new(disc, prefs)
      expect(strategy.class).to eq(RipStrategy)
    end

    it 'should be able to show the cdparanoia parameters for a normal 1-track disc' do
      disc = Datamodel::Disc.new()
      disc.addTrack(1, 0, 1000)
      strategy = RipStrategy.new(disc, prefs)
      expect(strategy.getTrack(1).startSector).to eq(0)
      expect(strategy.getTrack(1).lengthSector).to eq(1000)
    end
  end

  context 'When hidden track info is available' do
    it 'should be able to detect a hidden track when bigger than minimum length preference' do
      data = Datamodel::Disc.new()
      data.addTrack(1, 750, 1000)
      allow(prefs).to receive(:ripHiddenAudio).and_return true
      allow(prefs).to receive(:minLengthHiddenTrack).and_return(0)
      strategy = RipStrategy.new(data, prefs)
      expect(strategy.isHiddenTrackAvailable).to eq(true)
      track = strategy.getHiddenTrack()
      expect(track.startSector).to eq(0)
      expect(track.lengthSector).to eq(750)
    end

    # 10 seconds * 75 = 750 frames
    it 'should be able to detect a hidden track when equal to minimum length preference' do
      data = Datamodel::Disc.new()
      data.addTrack(1, 750, 1000)
      allow(prefs).to receive(:ripHiddenAudio).and_return true
      allow(prefs).to receive(:minLengthHiddenTrack).and_return(10)
      strategy = RipStrategy.new(data, prefs)
      expect(strategy.isHiddenTrackAvailable).to eq(true)
      track = strategy.getHiddenTrack()
      expect(track.startSector).to eq(0)
      expect(track.lengthSector).to eq(750)
    end

    it 'should not detect a hidden track when smaller than minimum length preference' do
      data = Datamodel::Disc.new()
      data.addTrack(1, 750, 1000)
      allow(prefs).to receive(:ripHiddenAudio).and_return true
      allow(prefs).to receive(:minLengthHiddenTrack).and_return(11)
      strategy = RipStrategy.new(data, prefs)
      expect(strategy.isHiddenTrackAvailable).to eq(false)
      expect {strategy.getHiddenTrack}.to raise_error(RuntimeError)
    end

    it 'should ignore hidden track if ripHiddenAudio is disabled in preferences' do
      data = Datamodel::Disc.new()
      data.addTrack(1, 750, 1000)
      allow(prefs).to receive(:ripHiddenAudio).and_return false
      allow(prefs).to receive(:minLengthHiddenTrack).and_return(0)
      strategy = RipStrategy.new(data, prefs)
      expect(strategy.isHiddenTrackAvailable).to eq(false)
      expect {strategy.getHiddenTrack}.to raise_error(RuntimeError)
    end
  end
end