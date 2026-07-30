#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2013 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

# The class GtkPreferences allows the user to change his preferences
# This class is responsible for building the frame on the right side

class GtkPreferences
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display

  DEFAULT_COLUMN_SPACINGS = 5
  DEFAULT_ROW_SPACINGS = 4
  DEFAULT_BORDER_WIDTH = 7

  def initialize(prefs=nil, deps=nil)
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance
    @codec_labels = {'flac' => 'FLAC', 'wavpack' => 'WavPack', 'nero' => 'Nero AAC',
                     'fraunhofer' => 'Fraunhofer AAC', 'other' => _('Other')}
  end
  
  def start
    @display = Gtk::Notebook.new # Create a notebook (multiple pages)
    buildSecureRippingTab()
    buildTocAnalysisTab()
    buildCodecsTab()
    buildMetadataTab()
    buildOtherTab()
    loadPreferences()
  end
  
  # save current preferences
  def save
    savePreferences
  end
  
  private
  
  # build first tab
  def buildSecureRippingTab
    buildFrameCdromDevice()
    buildFrameRippingOptions()
    buildFrameRippingRelated()
  end
  
  # build second tab
  def buildTocAnalysisTab
    buildFrameAudioSectorsBeforeTrackOne()
    buildFrameAdvancedTocAnalysis()
    buildFrameHandlingPregapsOtherThanTrackOne()
    buildFrameHandlingTracksWithPreEmphasis()
  end
  
  # build third tab
  def buildCodecsTab
    buildFrameSelectAudioCodecs()
    buildFrameCodecRelated()
    buildFrameNormalizeToStandardVolume()
  end
  
  # build fourth tab
  def buildMetadataTab
    buildFrameChooseMetadataProvider()
    buildFrameFreedbOptions()
    buildFrameMusicbrainzOptions()
    packMetadataFrames()
  end
  
  # build fifth tab
  def buildOtherTab
    buildFrameFilenamingScheme()
    buildFrameProgramsOfChoice()
    buildFrameDebugOptions()
    pack_other_frames()
  end

  # Fill all objects with the right value
  def loadPreferences
#ripping settings
    @cdromEntry.text = @prefs.cdrom.to_s
    @cdromOffsetSpin.value = @prefs.offset.to_f
    @padMissingSamples.active = @prefs.padMissingSamples
    @allChunksSpin.value = @prefs.reqMatchesAll.to_f
    @errChunksSpin.value = @prefs.reqMatchesErrors.to_f
    @maxSpin.value = @prefs.maxTries.to_f
    @ripEntry.text = @prefs.rippersettings.to_s
    @eject.active = @prefs.eject
    @noLog.active = @prefs.noLog
    @accuraterip.active = @prefs.accuraterip
    @cuetools.active = @prefs.cuetools
#toc settings
    @createCue.active = @prefs.createCue
    @image.active = @prefs.image
    @ripHiddenAudio.active = @prefs.ripHiddenAudio
    @minLengthHiddenTrackSpin.value = @prefs.minLengthHiddenTrack.to_f
    @appendPregaps.active = @prefs.preGaps == 'append'
    @prependPregaps.active = @prefs.preGaps == 'prepend'
    @correctPreEmphasis.active = @prefs.preEmphasis == 'sox'
    @doNotCorrectPreEmphasis.active = @prefs.preEmphasis == 'cue'
#codec settings (codecs itself are loaded when the objects are created)
    @playlist.active = @prefs.playlist
    @noSpaces.active = @prefs.noSpaces
    @noCapitals.active = @prefs.noCapitals
    @maxThreads.value = @prefs.maxThreads.to_f
    @normalize.active = loadNormalizer()
    @modus.active = @prefs.gain == 'album' ? 0 : 1
#metadata
    @metadataChoice.active = loadMetadataProvider()
    @firstHit.active = @prefs.firstHit
    @freedbServerEntry.text = @prefs.site.to_s
    @freedbUsernameEntry.text = @prefs.username.to_s
    @freedbHostnameEntry.text = @prefs.hostname.to_s
    @entryPreferredCountry.text = @prefs.preferMusicBrainzCountries.to_s
    @chooseOriginalRelease.active = @prefs.preferMusicBrainzDate == 'earlier'
    @chooseLatestRelease.active = @prefs.preferMusicBrainzDate == 'later'
    @chooseOriginalYear.active = @prefs.useEarliestDate
    @chooseReleaseYear.active = !@prefs.useEarliestDate
#other
    @basedirEntry.text = @prefs.basedir.to_s
    @namingNormalEntry.text = @prefs.namingNormal.to_s
    @namingVariousEntry.text = @prefs.namingVarious.to_s
    @namingImageEntry.text = @prefs.namingImage.to_s
    updateAllFileExamples()
    @verbose.active = @prefs.verbose
    @debug.active = @prefs.debug
    @editorEntry.text = @prefs.editor.to_s
    @filemanagerEntry.text = @prefs.filemanager.to_s
    sync_app_combos()
  end
  
  def loadNormalizer
    case @prefs.normalizer
      when 'replaygain' then 1
      when 'normalize' then 2
      else 0
    end
  end
  
  def loadMetadataProvider
    case @prefs.metadataProvider
      when 'musicbrainz' then 1
      when 'none' then 2
      else 0
    end
  end

  # update the preferences object with latest values
  def savePreferences
#ripping settings
    @prefs.cdrom = @cdromEntry.text
    @prefs.offset = @cdromOffsetSpin.value.to_i
    @prefs.padMissingSamples = @padMissingSamples.active?
    @prefs.reqMatchesAll = @allChunksSpin.value.to_i
    @prefs.reqMatchesErrors = @errChunksSpin.value.to_i
    @prefs.maxTries = @maxSpin.value.to_i
    @prefs.rippersettings = @ripEntry.text
    @prefs.eject = @eject.active?
    @prefs.noLog = @noLog.active?
    @prefs.accuraterip = @accuraterip.active?
    @prefs.cuetools = @cuetools.active?
#toc settings
    @prefs.createCue = @createCue.active?
    @prefs.image = @image.active?
    @prefs.ripHiddenAudio = @ripHiddenAudio.active?
    @prefs.minLengthHiddenTrack = @minLengthHiddenTrackSpin.value.to_i
    @prefs.preGaps = @appendPregaps.active? ? 'append' : 'prepend'
    @prefs.preEmphasis = @correctPreEmphasis.active? ? 'sox' : 'cue'
#codec settings
    @codecRows.each do |label, objects|
      @prefs.send(getCodecForLabel(label) + '=', true)
      @prefs.send('settings' + getCodecForLabel(label).capitalize + '=', objects[1].text)
    end
    @prefs.playlist = @playlist.active?
    @prefs.noSpaces = @noSpaces.active?
    @prefs.noCapitals = @noCapitals.active?
    @prefs.maxThreads = @maxThreads.value.to_i
    preventThreadProblemsOnOlderBindings()
    @prefs.normalizer = saveNormalizer()
    @prefs.gain = @modus.active == 0 ? "album" : "track"
#metadata
    @prefs.metadataProvider = saveMetadataProvider()
    @prefs.firstHit = @firstHit.active?
    @prefs.site = @freedbServerEntry.text
    @prefs.username = @freedbUsernameEntry.text
    @prefs.hostname = @freedbHostnameEntry.text
    @prefs.preferMusicBrainzCountries = @entryPreferredCountry.text
    @prefs.preferMusicBrainzDate = @chooseOriginalRelease.active? ? 'earlier' : 'later'
    @prefs.useEarliestDate = @chooseOriginalYear.active?
#other
    @prefs.basedir = @basedirEntry.text
    @prefs.namingNormal = @namingNormalEntry.text
    @prefs.namingVarious = @namingVariousEntry.text
    @prefs.namingImage = @namingImageEntry.text
    @prefs.verbose = @verbose.active?
    @prefs.debug = @debug.active?
    @prefs.editor = @editorEntry.text
    @prefs.filemanager = @filemanagerEntry.text
    @prefs.save() #also update the config file
  end
  
  def saveNormalizer
    case @normalize.active
      when 1 then 'replaygain'
      when 2 then 'normalize'
      else 'none'
    end
  end
  
  def saveMetadataProvider
    case @metadataChoice.active
      when 1 then 'musicbrainz'
      when 2 then 'none'
      else 'freedb'
    end
  end
  
  # The interface can't handle threads nicely on old versions        
  def preventThreadProblemsOnOlderBindings
    if defined?(Gtk::BINDING_VERSION) && Gtk::BINDING_VERSION[0] < 1 && 
        Gtk::BINDING_VERSION[1] < 18 && @prefs.maxThreads > 0
      @prefs.maxThreads = 0
      puts "WARNING: Threads are not supported on ruby gtk2-bindings"
      puts "that are older than 0.18.0. Setting them to zero."
      puts "Please upgrade your bindings if you want threads."
    end
  end
  
  # helpfunction to create a table
  def newTable(rows, columns, homogeneous=false)
    grid = Gtk::Grid.new()
    grid.column_homogeneous = homogeneous
    grid.row_homogeneous = homogeneous
    grid.column_spacing = DEFAULT_COLUMN_SPACINGS
    grid.row_spacing = DEFAULT_ROW_SPACINGS
    grid.border_width = DEFAULT_BORDER_WIDTH
    grid
  end
  
  # helpfunction to create a frame
  def newFrame(label, child)
    frame = Gtk::Frame.new(label)
    frame.shadow_type = :etched_in
    frame.border_width = DEFAULT_BORDER_WIDTH # was 5
    frame.add(child)
    frame
  end

  # 1st frame on secure ripping tab
  def buildFrameCdromDevice
    @table40 = newTable(rows=4, columns=3)
#creating objects
    @cdrom_label = Gtk::Label.new(_("CD-ROM device:"))
    @cdrom_label.halign = :start
    @cdrom_offset_label = Gtk::Label.new(_("CD-ROM offset:"))
    @cdrom_offset_label.halign = :start
    @cdromCombo = Gtk::ComboBoxText.new(entry: true)
    @cdromCombo.width_request = 160
    drives = @deps.respond_to?(:available_drives) ? @deps.available_drives : [@prefs.cdrom]
    drives.each { |d| @cdromCombo.append_text(d.to_s) }
    @cdromEntry = @cdromCombo.child
    @cdromOffsetSpin = Gtk::SpinButton.new(-1500.0, 1500.0, 1.0)
    @cdromOffsetSpin.value = 0.0
    @autoDetectOffsetButton = Gtk::Button.new(label: _('Auto-detect offset'))
    @offset_button = Gtk::LinkButton.new("http://www.accuraterip.com/driveoffsets.htm", _('List with offsets'))
    @offset_button.tooltip_text = _("A website which lists the offset for most drives.\nYour drive model can be found in each log file.")
#pack objects
    @padMissingSamples = Gtk::CheckButton.new(_('Pad missing samples with zeros'))
    @padMissingSamples.tooltip_text = _("cdparanoia cannot handle offsets \
larger than 580 for \nfirst (negative offset) and last (positive offset) \
track.\nThis option fills the rest with empty samples.\n\
If disabled, the file will not have the correct size.\n\
It is recommended to enable this option.")
    @padMissingSamples.sensitive = false
    @table40.attach(@cdrom_label, 0, 0, 1, 1)
    @table40.attach(@cdrom_offset_label, 0, 1, 1, 1)
    @table40.attach(@cdromCombo, 1, 0, 1, 1)
    @table40.attach(@cdromOffsetSpin, 1, 1, 1, 1)
    @table40.attach(@autoDetectOffsetButton, 2, 1, 1, 1)
    @table40.attach(@offset_button, 2, 2, 1, 1)
#connect signal
    @table40.attach(@padMissingSamples, 0, 2, 2, 1)
    @offset_button.signal_connect("clicked") {Thread.new{`#{@prefs.browser} #{@offset_button.uri}`}}
    @cdromOffsetSpin.signal_connect("value-changed"){enablePaddingOption?}
    @frame40 = newFrame(_('CD-ROM Device'), child=@table40)
  end
  
  # enable the padding option if the offset is >580 || <-580
  def enablePaddingOption?
    value = @cdromOffsetSpin.value.to_i
    if value > 580 || value <-580
      @padMissingSamples.sensitive = true
    else
      @padMissingSamples.sensitive = false
    end
  end

  # 2nd frame on secure ripping tab
  def buildFrameRippingOptions
    @table50 = newTable(rows=3, columns=3)
#create objects
    @all_chunks = Gtk::Label.new(_("Match all chunks:")) ; @all_chunks.halign = :start
    @err_chunks = Gtk::Label.new(_("Match erroneous chunks:")) ; @err_chunks.halign = :start
    @max_label = Gtk::Label.new(_("Maximum trials (0 = unlimited):")) ; @max_label.halign = :start
    @allChunksSpin = Gtk::SpinButton.new(2.0,  100.0, 1.0)
    @errChunksSpin = Gtk::SpinButton.new(2.0, 100.0, 1.0)
    @maxSpin = Gtk::SpinButton.new(0.0, 100.0, 1.0)
    @time1 = Gtk::Label.new(_("times"))
    @time2 = Gtk::Label.new(_("times"))
    @time3 = Gtk::Label.new(_("times"))
#pack objects
    @table50.attach(@all_chunks, 0, 0, 1, 1) #1st column
    @table50.attach(@err_chunks, 0, 1, 1, 1)
    @table50.attach(@max_label, 0, 2, 1, 1)
    @table50.attach(@allChunksSpin, 1, 0, 1, 1) #2nd column
    @table50.attach(@errChunksSpin, 1, 1, 1, 1)
    @table50.attach(@maxSpin, 1, 2, 1, 1)
    @table50.attach(@time1, 2, 0, 1, 1) #3rd column
    @table50.attach(@time2, 2, 1, 1, 1)
    @table50.attach(@time3, 2, 2, 1, 1)
#connect a signal to @all_chunks to make sure @err_chunks get always at least the same amount of rips as @all_chunks
    @allChunksSpin.signal_connect("value_changed") {if @errChunksSpin.value < @allChunksSpin.value ; @errChunksSpin.value = @allChunksSpin.value end ; @errChunksSpin.set_range(@allChunksSpin.value,100.0)} #ensure all_chunks cannot be smaller that err_chunks.
    @frame50= newFrame(_('Ripping Options'), child=@table50)
  end

  def buildFrameRippingRelated
    @table60 = newTable(rows=5, columns=3)
#create objects
    @rip_label = Gtk::Label.new(_("Pass cdparanoia options:")) ; @rip_label.halign = :start
    @eject= Gtk::CheckButton.new(_('Eject CD when finished'))
    @noLog = Gtk::CheckButton.new(_('Only keep log file if correction is needed'))
    @accuraterip = Gtk::CheckButton.new(_('Verify tracks with AccurateRip'))
    @cuetools = Gtk::CheckButton.new(_('Verify tracks with CUETools Database'))
    @ripEntry= Gtk::Entry.new ; @ripEntry.width_request = 120
    @configureCdparanoiaButton = Gtk::Button.new(label: _('Configure...'))
#pack objects
    @table60.attach(@rip_label, 0, 0, 1, 1)
    @table60.attach(@ripEntry, 1, 0, 1, 1)
    @table60.attach(@configureCdparanoiaButton, 2, 0, 1, 1)
    @table60.attach(@eject, 0, 1, 3, 1)
    @table60.attach(@noLog, 0, 2, 3, 1)
    @table60.attach(@accuraterip, 0, 3, 3, 1)
    @table60.attach(@cuetools, 0, 4, 3, 1)
    @configureCdparanoiaButton.signal_connect("clicked") { show_cdparanoia_dialog }
    @frame60 = newFrame(_('Ripping Related'), child=@table60)
#pack all frames into a single page
    @page1 = Gtk::Box.new(:vertical) #One Box to rule them all
    [@frame40, @frame50, @frame60].each{|frame| @page1.pack_start(frame, expand: false, fill: false, padding: 0)}
    @page1_label = Gtk::Label.new(_("Secure Ripping"))
    @display.append_page(@page1, @page1_label)
  end

  def show_cdparanoia_dialog
    require 'r3ripper/gtk2/gtkCdparanoiaDialog'
    parent_window = (@display && @display.toplevel.is_a?(Gtk::Window)) ? @display.toplevel : nil
    dialog = GtkCdparanoiaDialog.new(parent_window, @ripEntry.text)
    result = dialog.run
    @ripEntry.text = result if result
  end

  def buildFrameAudioSectorsBeforeTrackOne
    @tableToc1 = newTable(rows=3, columns=3)
#create objects
    @ripHiddenAudio = Gtk::CheckButton.new(_('Rip hidden audio sectors'))
    @markHiddenTrackLabel1 = Gtk::Label.new(_('Mark as a hidden track when longer than'))
    @markHiddenTrackLabel2 = Gtk::Label.new(_('second(s)'))
    @minLengthHiddenTrackSpin = Gtk::SpinButton.new(0, 30, 1)
    @minLengthHiddenTrackSpin.value = 2.0
    @ripHiddenAudio.tooltip_text = _("Uncheck this if cdparanoia crashes with your ripping drive.")
    text = _("A hidden track will rip to a seperate file if used in track modus.\nIf it's smaller the sectors will be prepended to the first track.")
    @minLengthHiddenTrackSpin.tooltip_text = text
    @markHiddenTrackLabel1.tooltip_text = text
    @markHiddenTrackLabel2.tooltip_text = text
#pack objects
    @tableToc1.attach(@ripHiddenAudio, 0, 0, 1, 1)
    @tableToc1.attach(@markHiddenTrackLabel1, 0, 1, 1, 1)
    @tableToc1.attach(@minLengthHiddenTrackSpin, 1, 1, 1, 1)
    @tableToc1.attach(@markHiddenTrackLabel2, 2, 1, 1, 1)
    @ripHiddenAudio.signal_connect("clicked"){@minLengthHiddenTrackSpin.sensitive = @ripHiddenAudio.active?}
    @frameToc1 = newFrame(_('Audio Sectors Before Track 1'), child=@tableToc1)
  end

  def buildFrameAdvancedTocAnalysis
    @tableToc2 = newTable(rows=3, columns=2)
    #create objects
    @createCue = Gtk::CheckButton.new(_('Create cue sheet'))
    @image = Gtk::CheckButton.new(_('Rip CD to single file'))
#pack objects
    @tableToc2.attach(@createCue, 0, 1, 2, 1)
    @tableToc2.attach(@image, 0, 2, 2, 1)
    @vboxToc = Gtk::Box.new(:vertical)
    @vboxToc.pack_start(@tableToc2, expand: false, fill: false, padding: 0)
    @frameToc2 = newFrame(_('Advanced TOC Analysis'), child=@vboxToc)
# build box for cdrdao
    @cdrdaoHbox = Gtk::Box.new(:horizontal, 5)
    @cdrdao = Gtk::Label.new(_('cdrdao installed?'))
    @cdrdaoImage = Gtk::Image.new(stock: Gtk::Stock::CANCEL, size: :button)
    @cdrdaoHbox.pack_start(@cdrdao, expand: false, fill: false, padding: 5)
    @cdrdaoHbox.pack_start(@cdrdaoImage, expand: false, fill: false, padding: 0)
  end

  def buildFrameHandlingPregapsOtherThanTrackOne
    @tableToc3 = newTable(rows=3, columns=3)
#create objects
    @appendPregaps = Gtk::RadioButton.new(member: nil, label: _('Append pregap to the previous track'))
    @prependPregaps = Gtk::RadioButton.new(member: @appendPregaps, label: _('Prepend pregap to the track'))
#pack objects
    @tableToc3.attach(@appendPregaps, 0, 0, 1, 1)
    @tableToc3.attach(@prependPregaps, 0, 1, 1, 1)
    @frameToc3 = newFrame(_('Handling Pregaps Other Than Track 1'), child=@tableToc3)
    @vboxToc.pack_start(@frameToc3, expand: false, fill: false, padding: 0)
  end

  def buildFrameHandlingTracksWithPreEmphasis
    @tableToc4 = newTable(rows=3, columns=3)
#create objects
    @correctPreEmphasis = Gtk::RadioButton.new(member: nil, label: _('Correct pre-emphasis tracks with SoX'))
    @doNotCorrectPreEmphasis = Gtk::RadioButton.new(member: @correctPreEmphasis, label: _("Save the pre-emphasis tag in the cue sheet"))
#pack objects
    @tableToc4.attach(@correctPreEmphasis, 0, 0, 1, 1)
    @tableToc4.attach(@doNotCorrectPreEmphasis, 0, 1, 1, 1)
    @frameToc4 = newFrame(_('Handling Tracks With Pre-emphasis'), child=@tableToc4)
    @vboxToc.pack_start(@frameToc4, expand: false, fill: false, padding: 0)
#pack all frames into a single page
    setSignalsToc()
    @pageToc = Gtk::Box.new(:vertical) #One Box to rule them all
    [@frameToc1, @cdrdaoHbox, @frameToc2].each{|frame| @pageToc.pack_start(frame, expand: false, fill: false, padding: 0)}
    @pageTocLabel = Gtk::Label.new(_("TOC Analysis"))
    @display.append_page(@pageToc, @pageTocLabel)
  end

  #check if cdrdao is installed
  def cdrdaoInstalled
    if @deps.installed?('cdrdao')
      @cdrdaoImage.stock = Gtk::Stock::APPLY
      @frameToc2.each{|child| child.sensitive = true}
    else
      @cdrdaoImage.stock = Gtk::Stock::CANCEL
      @createCue.active = false
      @frameToc2.each{|child| child.sensitive = false}
    end
  end

  # signal for createCue
  def createCue
    @image.sensitive = @createCue.active?
    @image.active = false if !@createCue.active?
    @tableToc3.each{|child| child.sensitive = @createCue.active?}
    @tableToc4.each{|child| child.sensitive = @createCue.active?}
  end

  # signal for create single file
  def createSingle
    @tableToc3.each{|child| child.sensitive = !@image.active?}
    @correctPreEmphasis.active = true
    @doNotCorrectPreEmphasis.sensitive = !@image.active?
  end

  #set signals for the toc
  def setSignalsToc
    cdrdaoInstalled()
    createSingle()
    createCue()
    @createCue.signal_connect("clicked"){createCue()}
    @createCue.signal_connect("clicked"){`killall cdrdao 2>1` if !@createCue.active?}
    @image.signal_connect("clicked"){createSingle()}
  end

  def buildFrameSelectAudioCodecs # Select audio codecs frame   
    @codecRows = Hash.new    
    @prefs.codecs.each{|codec| createCodecRow(codec)}
    @selectCodecsTable = newTable(@codecRows.size + 1, columns = 4)
    createCodecsTable()
    @frame70 = newFrame(_('Active Audio Codecs'), child=@selectCodecsTable)
  end

  def createCodecRow(codec)
    @codecRows[codec] = [Gtk::Label.new(getLabelForCodec(codec))]
    @codecRows[codec][0].halign = :start
    if codec == 'wav'
      @codecRows[codec] << Gtk::Label.new(_('No settings available'))
      @codecRows[codec][1].halign = :start
    else
      @codecRows[codec] << Gtk::Entry.new()
      @codecRows[codec][1].text = @prefs.send('settings' + codec.capitalize).to_s
    end

    if ['flac', 'opus', 'mp3', 'lame', 'ogg', 'vorbis', 'wavpack'].include?(codec)
      cfg_btn = Gtk::Button.new(label: _('Configure...'))
      entry = @codecRows[codec][1]
      cfg_btn.signal_connect('clicked') { show_codec_dialog(codec, entry) }
      @codecRows[codec] << cfg_btn
    end

    remove_btn = Gtk::Button.new(label: _('Remove'))
    remove_btn.signal_connect("clicked") do
      @codecRows[codec].each{|object| @selectCodecsTable.remove(object)}
      @codecRows.delete(codec)
      @prefs.send(codec + '=', false)
      updateCodecsView()
    end
    @codecRows[codec] << remove_btn

    addTooltipForOtherCodec(@codecRows[codec][1]) if codec == 'other'
  end

  def show_codec_dialog(codec, entry)
    require 'r3ripper/gtk2/gtkCodecDialog'
    parent_window = (@display && @display.toplevel.is_a?(Gtk::Window)) ? @display.toplevel : nil
    dialog = GtkCodecDialog.new(parent_window, codec, entry.text)
    result = dialog.run
    entry.text = result if result
  end

  def getLabelForCodec(codec)
    @codec_labels.key?(codec) ? @codec_labels[codec] : codec.capitalize
  end

  def getCodecForLabel(label)
    @codec_labels.value?(label) ? @codec_labels.key(label) : label.downcase
  end
  
  def updateCodecsView
    @selectCodecsTable.children.each{|child| @selectCodecsTable.remove(child)}
    createCodecsTable()
    @selectCodecsTable.show_all()
  end
  
  def createCodecsTable
    top = 0
    @codecRows.each do |codec, row|
      @selectCodecsTable.attach(row[0], 0, top, 1, 1)
      @selectCodecsTable.attach(row[1], 1, top, 1, 1)
      row[1].hexpand = true
      if row.length > 3
        @selectCodecsTable.attach(row[2], 2, top, 1, 1)
        @selectCodecsTable.attach(row[3], 3, top, 1, 1)
      else
        @selectCodecsTable.attach(row[2], 2, top, 2, 1)
      end
      top += 1
    end
    
    createAddCodecRow()
  end
  
  def addTooltipForOtherCodec(entry)
    entry.tooltip_text = _('%a=artist %g=genre %t=track name %f=codec %b=album 
%y=year %n=track %va=various artist %o=output file %i=input file') 
  end
  
  def createAddCodecRow
    @addCodecComboBox = Gtk::ComboBoxText.new()
    @addCodecComboBox.append_text(_('Add codec...'))
    @prefs.allCodecs.each do |codec|
      @addCodecComboBox.append_text(getLabelForCodec(codec)) unless @codecRows.key?(codec)
    end
    @addCodecComboBox.active = 0

    @addCodecComboBox.signal_connect("changed") do
      label = @addCodecComboBox.active_text
      if label && label != _('Add codec...')
        codec = getCodecForLabel(label)
        createCodecRow(codec)
        @prefs.send(codec + '=', true)
        updateCodecsView()
      end
    end
    
    if @addCodecLabel.nil?
      @addCodecLabel = Gtk::Label.new(_('Codec'))
      @addCodecLabel.halign = :start
    end
    
    # put the row into the grid
    top = @codecRows.size
    @selectCodecsTable.attach(@addCodecLabel, 0, top, 1, 1)
    @selectCodecsTable.attach(@addCodecComboBox, 1, top, 3, 1)
    @addCodecComboBox.hexpand = true
  end

  def buildFrameCodecRelated #Encoding related frame
    @table80 = newTable(rows=4, columns=2)
#creating objects
    @playlist = Gtk::CheckButton.new(_("Create M3U playlist"))
    @noSpaces = Gtk::CheckButton.new(_("Replace spaces with underscores in file names"))
    @noCapitals = Gtk::CheckButton.new(_("Downsize all capital letters in file names"))
    @maxThreads = Gtk::SpinButton.new(0.0, 10.0, 1.0)
    @maxThreadsLabel = Gtk::Label.new(_("Number of extra encoding threads"))
#packing objects
    @table80.attach(@maxThreadsLabel, 0, 0, 1, 1)
    @table80.attach(@maxThreads, 1, 0, 1, 1)
    @table80.attach(@playlist, 0, 1, 2, 1)
    @table80.attach(@noSpaces, 0, 2, 2, 1)
    @table80.attach(@noCapitals, 0, 3, 2, 1)
    @frame80 = newFrame(_('Codec Related'), child=@table80)
  end

  def buildFrameNormalizeToStandardVolume #Normalize audio
    @table85 = newTable(rows=2, columns=1)
#creating objects
    @normalize = Gtk::ComboBoxText.new()
    @normalize.append_text(_("Don't standardize volume"))
    @normalize.append_text(_("Use ReplayGain on audio files"))
    @normalize.append_text(_("Use normalize on WAV files"))
    @normalize.active=0
    @modus = Gtk::ComboBoxText.new()
    @modus.append_text(_("Album / audiophile mode"))
    @modus.append_text(_("Track mode"))
    @modus.active = 0
    @modus.sensitive = false
    @normalize.signal_connect("changed") {if @normalize.active == 0 ; @modus.sensitive = false else @modus.sensitive = true end}
#packing objects
    @table85.attach(@normalize, 0, 0, 1, 1)
    @table85.attach(@modus, 1, 0, 1, 1)
    @frame85 = newFrame(_('Normalize to Standard Volume'), child=@table85)
#pack all frames into a single page
    @page2 = Gtk::Box.new(:vertical) #One Box to rule them all
    [@frame70, @frame80, @frame85].each{|frame| @page2.pack_start(frame, expand: false, fill: false, padding: 0)}
    @page2_label = Gtk::Label.new(_("Codecs"))
    @display.append_page(@page2, @page2_label)
  end
  
  def buildFrameChooseMetadataProvider
    @table90 = newTable(rows=1, columns=2)
    @metadataLabel = Gtk::Label.new(_("Primary metadata provider:"))
    @metadataChoice = Gtk::ComboBoxText.new()
    @metadataChoice.append_text(_("GnuDB"))
    @metadataChoice.append_text(_("MusicBrainz"))
    @metadataChoice.append_text(_("Don't use a metadata provider"))
    @table90.attach(@metadataLabel,0,0,1,1)
    @table90.attach(@metadataChoice,1,0,1,1)
    @frame90 = newFrame(_('Choose Metadata Provider'), child=@table90)
  end
  
  def buildFrameFreedbOptions
    @table91 = newTable(rows=4, columns=3)
#creating objects
    @firstHit= Gtk::CheckButton.new(_("Always use first GnuDB hit"))
    @freedb_server_label= Gtk::Label.new(_("GnuDB server:")) ; @freedb_server_label.halign = :start
    @freedb_username_label= Gtk::Label.new(_("Username:")) ; @freedb_username_label.halign = :start
    @freedb_hostname_label= Gtk::Label.new(_("Hostname:")) ; @freedb_hostname_label.halign = :start
    @freedbServerEntry = Gtk::Entry.new
    @freedbUsernameEntry = Gtk::Entry.new
    @freedbHostnameEntry = Gtk::Entry.new
    @resetGnudbServerButton = Gtk::Button.new(label: _('Reset to Default'))

    @freedbServerEntry.tooltip_text = _("HTTP CGI endpoint for GnuDB disc metadata queries")
    @freedbUsernameEntry.tooltip_text = _("Username sent during the CDDB protocol handshake")
    @freedbHostnameEntry.tooltip_text = _("Hostname sent during the CDDB protocol handshake")

    @resetGnudbServerButton.signal_connect("clicked") do
      @freedbServerEntry.text = 'http://gnudb.gnudb.org/~cddb/cddb.cgi'
    end

#packing objects
    @table91.attach(@firstHit, 0, 0, 3, 1) #all columns, 1st row
    @table91.attach(@freedb_server_label, 0, 1, 1, 1) #1st column, 2nd row
    @table91.attach(@freedbServerEntry, 1, 1, 1, 1) #2nd column, 2nd row
    @table91.attach(@resetGnudbServerButton, 2, 1, 1, 1) #3rd column, 2nd row
    @table91.attach(@freedb_username_label, 0, 2, 1, 1) #1st column, 3rd row
    @table91.attach(@freedbUsernameEntry, 1, 2, 2, 1) #2nd and 3rd column, 3rd row
    @table91.attach(@freedb_hostname_label, 0, 3, 1, 1) #1st column, 4th row
    @table91.attach(@freedbHostnameEntry, 1, 3, 2, 1) #2nd and 3rd column, 4th row
    @frame91 = newFrame(_('GnuDB Options'), child=@table91)
  end
  alias_method :buildFrameGnudbOptions, :buildFrameFreedbOptions
  
  def buildFrameMusicbrainzOptions
    @table92 = newTable(rows=3, columns=3)
    @labelPreferredCountry = Gtk::Label.new(_('Preferred countries:'))
    @labelPreferredCountry.halign = :start
    @labelPreferredRelease = Gtk::Label.new(_('Preferred release date:'))
    @labelPreferredRelease.halign = :start
    @labelPreferredYear = Gtk::Label.new(_('Preferred year (metadata):'))
    @labelPreferredYear.halign = :start
    @entryPreferredCountry = Gtk::Entry.new()
    @configureCountryButton = Gtk::Button.new(label: _('Configure...'))
    @chooseOriginalRelease = Gtk::RadioButton.new(member: nil, label: _('Original'))
    @chooseLatestRelease = Gtk::RadioButton.new(member: @chooseOriginalRelease, label: _('Latest available'))
    @chooseOriginalYear = Gtk::RadioButton.new(member: nil, label: _('Original'))
    @chooseReleaseYear = Gtk::RadioButton.new(member: @chooseOriginalYear, label: _('From release'))
#packing objects
    @table92.attach(@labelPreferredCountry, 0, 0, 1, 1)
    @table92.attach(@entryPreferredCountry, 1, 0, 1, 1)
    @table92.attach(@configureCountryButton, 2, 0, 1, 1)
    @table92.attach(@labelPreferredRelease, 0, 1, 1, 1)
    @table92.attach(@chooseOriginalRelease, 1, 1, 1, 1)
    @table92.attach(@chooseLatestRelease, 2, 1, 1, 1)
    @table92.attach(@labelPreferredYear, 0, 2, 1, 1)
    @table92.attach(@chooseOriginalYear, 1, 2, 1, 1)
    @table92.attach(@chooseReleaseYear, 2, 2, 1, 1)
    @configureCountryButton.signal_connect("clicked") { show_country_dialog }
    @frame92 = newFrame(_('MusicBrainz Options'), @table92)
  end

  def show_country_dialog
    require 'r3ripper/gtk2/gtkCountryDialog'
    parent_window = (@display && @display.toplevel.is_a?(Gtk::Window)) ? @display.toplevel : nil
    dialog = GtkCountryDialog.new(parent_window, @entryPreferredCountry.text)
    result = dialog.run
    @entryPreferredCountry.text = result if result
  end

  # grey out the two frames if no metadata provider is chosen
  def updateMetadataProviderView
    @frame91.children.each{|child| child.sensitive = @metadataChoice.active != 2}
    @frame92.children.each{|child| child.sensitive = @metadataChoice.active != 2}
  end
  
  def packMetadataFrames
    @metadataChoice.signal_connect("changed"){updateMetadataProviderView()}
    @page3 = Gtk::Box.new(:vertical) #One Box to rule them all
    [@frame90, @frame91, @frame92].each{|frame| @page3.pack_start(frame, expand: false, fill: false, padding: 0)}
    @page3_label = Gtk::Label.new(_("Metadata"))
    @display.append_page(@page3, @page3_label)
  end

  def buildFrameFilenamingScheme # Naming scheme frame
    @table100 = newTable(rows=4, columns=3)
#creating objects 1st column
    @basedir_label = Gtk::Label.new(_('Base directory:')) ; @basedir_label.halign = :start ; @basedir_label.valign = :center
    @naming_normal_label = Gtk::Label.new(_('Standard:')) ; @naming_normal_label.halign = :start ; @naming_normal_label.valign = :start
    @naming_various_label = Gtk::Label.new(_('Various artists:')) ; @naming_various_label.halign = :start ; @naming_various_label.valign = :start
    @naming_image_label = Gtk::Label.new(_('Single file image:')) ; @naming_image_label.halign = :start ; @naming_image_label.valign = :start

    @example_normal_label = Gtk::Label.new('') ; @example_normal_label.halign = :start ; @example_normal_label.xalign = 0.0 ; @example_normal_label.justify = :left ; @example_normal_label.wrap = true
    @example_various_label = Gtk::Label.new('') ; @example_various_label.halign = :start ; @example_various_label.xalign = 0.0 ; @example_various_label.justify = :left ; @example_various_label.wrap = true
    @example_image_label = Gtk::Label.new('') ; @example_image_label.halign = :start ; @example_image_label.xalign = 0.0 ; @example_image_label.justify = :left ; @example_image_label.wrap = true

#creating objects 2nd & 3rd column
    @basedirEntry = Gtk::Entry.new
    @namingNormalEntry = Gtk::Entry.new
    @namingVariousEntry = Gtk::Entry.new
    @namingImageEntry = Gtk::Entry.new

    @browseBasedirButton = Gtk::Button.new(label: _('Browse...')) ; @browseBasedirButton.valign = :center
    @configureNormalButton = Gtk::Button.new(label: _('Configure...')) ; @configureNormalButton.valign = :start
    @configureVariousButton = Gtk::Button.new(label: _('Configure...')) ; @configureVariousButton.valign = :start
    @configureImageButton = Gtk::Button.new(label: _('Configure...')) ; @configureImageButton.valign = :start

    @basedirEntry.signal_connect("key_release_event"){updateAllFileExamples() ; false}
    @basedirEntry.signal_connect("button_release_event"){updateAllFileExamples() ; false}
    @namingNormalEntry.signal_connect("key_release_event"){showFileNormal() ; false}
    @namingNormalEntry.signal_connect("button_release_event"){showFileNormal() ; false}
    @namingNormalEntry.signal_connect("focus_out_event"){if not File.dirname(@namingNormalEntry.text) =~ /%a|%b/ ; @namingNormalEntry.text = "%a (%y) %b/" + @namingNormalEntry.text; preventStupidness() end; false}
    @namingVariousEntry.signal_connect("key_release_event"){showFileVarious() ; false}
    @namingVariousEntry.signal_connect("button_release_event"){showFileVarious() ; false}
    @namingVariousEntry.signal_connect("focus_out_event"){if not File.dirname(@namingVariousEntry.text) =~ /%a|%b/ ; @namingVariousEntry.text = "%a (%y) %b/" + @namingVariousEntry.text; preventStupidness() end; false}
    @namingImageEntry.signal_connect("key_release_event"){showFileImage() ; false}
    @namingImageEntry.signal_connect("button_release_event"){showFileImage() ; false}
    @namingImageEntry.signal_connect("focus_out_event"){if not File.dirname(@namingImageEntry.text) =~ /%a|%b/ ; @namingImageEntry.text = "%a (%y) %b/" + @namingImageEntry.text; preventStupidness() end; false}

    @browseBasedirButton.signal_connect("clicked") { show_basedir_dialog }
    @configureNormalButton.signal_connect("clicked") { show_naming_dialog('standard', @namingNormalEntry) }
    @configureVariousButton.signal_connect("clicked") { show_naming_dialog('various', @namingVariousEntry) }
    @configureImageButton.signal_connect("clicked") { show_naming_dialog('image', @namingImageEntry) }

    # Group entry and example label in vertical boxes for exact alignment
    box_normal = Gtk::Box.new(:vertical, 2)
    box_normal.pack_start(@namingNormalEntry, expand: false, fill: true, padding: 0)
    box_normal.pack_start(@example_normal_label, expand: false, fill: true, padding: 0)

    box_various = Gtk::Box.new(:vertical, 2)
    box_various.pack_start(@namingVariousEntry, expand: false, fill: true, padding: 0)
    box_various.pack_start(@example_various_label, expand: false, fill: true, padding: 0)

    box_image = Gtk::Box.new(:vertical, 2)
    box_image.pack_start(@namingImageEntry, expand: false, fill: true, padding: 0)
    box_image.pack_start(@example_image_label, expand: false, fill: true, padding: 0)

#packing table
    @table100.attach(@basedir_label, 0, 0, 1, 1)
    @table100.attach(@basedirEntry, 1, 0, 1, 1)
    @basedirEntry.hexpand = true
    @table100.attach(@browseBasedirButton, 2, 0, 1, 1)

    @table100.attach(@naming_normal_label, 0, 1, 1, 1)
    @table100.attach(box_normal, 1, 1, 1, 1)
    box_normal.hexpand = true
    @table100.attach(@configureNormalButton, 2, 1, 1, 1)

    @table100.attach(@naming_various_label, 0, 2, 1, 1)
    @table100.attach(box_various, 1, 2, 1, 1)
    box_various.hexpand = true
    @table100.attach(@configureVariousButton, 2, 2, 1, 1)

    @table100.attach(@naming_image_label, 0, 3, 1, 1)
    @table100.attach(box_image, 1, 3, 1, 1)
    box_image.hexpand = true
    @table100.attach(@configureImageButton, 2, 3, 1, 1)

    @frame100 = newFrame(_('File Naming Scheme'), child=@table100)
  end

  def show_basedir_dialog
    parent_window = (@display && @display.toplevel.is_a?(Gtk::Window)) ? @display.toplevel : nil
    dialog = Gtk::FileChooserDialog.new(
      title: _("Choose Base Directory"),
      parent: parent_window,
      action: :select_folder,
      buttons: [
        [_("Cancel"), Gtk::ResponseType::CANCEL],
        [_("Select"), Gtk::ResponseType::ACCEPT]
      ]
    )
    dialog.current_folder = File.expand_path(@basedirEntry.text.to_s) rescue nil
    if dialog.run == Gtk::ResponseType::ACCEPT
      @basedirEntry.text = dialog.filename
      updateAllFileExamples()
    end
    dialog.destroy
  end

  def show_naming_dialog(scheme_type, entry)
    require 'r3ripper/gtk2/gtkNamingDialog'
    parent_window = (@display && @display.toplevel.is_a?(Gtk::Window)) ? @display.toplevel : nil
    dialog = GtkNamingDialog.new(parent_window, scheme_type, entry.text)
    result = dialog.run
    if result
      entry.text = result
      case scheme_type
      when 'various' then showFileVarious()
      when 'image' then showFileImage()
      else showFileNormal()
      end
    end
  end
  
  def showFileNormal
    @example_normal_label.text = _("e.g. ") + Preferences.showFilenameNormal(@basedirEntry.text, @namingNormalEntry.text)
  end
  
  def showFileVarious
    @example_various_label.text = _("e.g. ") + Preferences.showFilenameVarious(@basedirEntry.text, @namingVariousEntry.text)
  end
  
  def showFileImage
    @example_image_label.text = _("e.g. ") + Preferences.showFilenameNormal(@basedirEntry.text, @namingImageEntry.text)
  end

  def updateAllFileExamples
    showFileNormal()
    showFileVarious()
    showFileImage()
  end

  # Would you believe this actually prevents bug reports?
  def preventStupidness()
    puts "You need to make a subdirectory with at least the artist or album"
    puts "name in it. Otherwise your directory will be overwritten each time!"
    puts "To protect you from making these unwise choices this is corrected :P"
  end

#Small table needed for setting programs
#log file viewer 	| entry
#file manager 	| entry
  EDITOR_CMDS = ['xdg-open', 'gnome-text-editor', 'gedit', 'kate', 'mousepad', 'xed', 'leafpad', 'code'].freeze
  FILEMANAGER_CMDS = ['xdg-open', 'nautilus', 'dolphin', 'thunar', 'pcmanfm', 'nemo', 'caja'].freeze

  def buildFrameProgramsOfChoice
    @table110 = newTable(rows=2, columns=4)

    @editor_label = Gtk::Label.new(_("Log file viewer:")) ; @editor_label.halign = :start ; @editor_label.valign = :center
    @filemanager_label = Gtk::Label.new(_("File manager:")) ; @filemanager_label.halign = :start ; @filemanager_label.valign = :center

    @editorEntry = Gtk::Entry.new
    @filemanagerEntry = Gtk::Entry.new

    @editorEntry.signal_connect('changed') { sync_editor_combo }
    @filemanagerEntry.signal_connect('changed') { sync_filemanager_combo }

    @editorPresetCombo = Gtk::ComboBoxText.new
    @editorPresetCombo.append_text(_('Custom application...'))
    [
      { label: N_('Default'), cmd: 'xdg-open' },
      { label: N_('GNOME Text Editor'), cmd: 'gnome-text-editor' },
      { label: N_('Gedit'), cmd: 'gedit' },
      { label: N_('Kate'), cmd: 'kate' },
      { label: N_('Mousepad'), cmd: 'mousepad' },
      { label: N_('Xed'), cmd: 'xed' },
      { label: N_('Leafpad'), cmd: 'leafpad' },
      { label: N_('VS Code'), cmd: 'code' }
    ].each do |app|
      @editorPresetCombo.append_text(_(app[:label]) + " (#{app[:cmd]})")
    end
    @editorPresetCombo.active = 0
    @editorPresetCombo.signal_connect('changed') do
      idx = @editorPresetCombo.active
      if idx > 0 && EDITOR_CMDS[idx - 1]
        @editorEntry.text = EDITOR_CMDS[idx - 1]
      end
    end

    @filemanagerPresetCombo = Gtk::ComboBoxText.new
    @filemanagerPresetCombo.append_text(_('Custom application...'))
    [
      { label: N_('Default'), cmd: 'xdg-open' },
      { label: N_('Files (Nautilus)'), cmd: 'nautilus' },
      { label: N_('Dolphin'), cmd: 'dolphin' },
      { label: N_('Thunar'), cmd: 'thunar' },
      { label: N_('PCManFM'), cmd: 'pcmanfm' },
      { label: N_('Nemo'), cmd: 'nemo' },
      { label: N_('Caja'), cmd: 'caja' }
    ].each do |app|
      @filemanagerPresetCombo.append_text(_(app[:label]) + " (#{app[:cmd]})")
    end
    @filemanagerPresetCombo.active = 0
    @filemanagerPresetCombo.signal_connect('changed') do
      idx = @filemanagerPresetCombo.active
      if idx > 0 && FILEMANAGER_CMDS[idx - 1]
        @filemanagerEntry.text = FILEMANAGER_CMDS[idx - 1]
      end
    end

    @browseEditorButton = Gtk::Button.new(label: _('Browse...'))
    @browseFileManagerButton = Gtk::Button.new(label: _('Browse...'))

    @browseEditorButton.signal_connect('clicked') { show_app_chooser_dialog(@editorEntry, _('Choose Log File Viewer Executable')) }
    @browseFileManagerButton.signal_connect('clicked') { show_app_chooser_dialog(@filemanagerEntry, _('Choose File Manager Executable')) }

    # packing
    @table110.attach(@editor_label, 0, 0, 1, 1)
    @table110.attach(@editorEntry, 1, 0, 1, 1)
    @editorEntry.hexpand = true
    @table110.attach(@editorPresetCombo, 2, 0, 1, 1)
    @table110.attach(@browseEditorButton, 3, 0, 1, 1)

    @table110.attach(@filemanager_label, 0, 1, 1, 1)
    @table110.attach(@filemanagerEntry, 1, 1, 1, 1)
    @filemanagerEntry.hexpand = true
    @table110.attach(@filemanagerPresetCombo, 2, 1, 1, 1)
    @table110.attach(@browseFileManagerButton, 3, 1, 1, 1)

    @frame110 = newFrame(_('Programs of Choice'), child=@table110)
  end

  def show_app_chooser_dialog(entry, title_str)
    parent_window = (@display && @display.toplevel.is_a?(Gtk::Window)) ? @display.toplevel : nil
    dialog = Gtk::FileChooserDialog.new(
      title: title_str,
      parent: parent_window,
      action: :open,
      buttons: [
        [_("Cancel"), Gtk::ResponseType::CANCEL],
        [_("Select"), Gtk::ResponseType::ACCEPT]
      ]
    )
    dialog.current_folder = '/usr/bin'
    if dialog.run == Gtk::ResponseType::ACCEPT
      entry.text = dialog.filename
      sync_app_combos
    end
    dialog.destroy
  end

  def sync_editor_combo
    return unless @editorEntry && @editorPresetCombo
    cmd = @editorEntry.text.to_s.strip
    idx = EDITOR_CMDS.index(cmd)
    target_active = idx ? idx + 1 : 0
    @editorPresetCombo.active = target_active if @editorPresetCombo.active != target_active
  end

  def sync_filemanager_combo
    return unless @filemanagerEntry && @filemanagerPresetCombo
    cmd = @filemanagerEntry.text.to_s.strip
    idx = FILEMANAGER_CMDS.index(cmd)
    target_active = idx ? idx + 1 : 0
    @filemanagerPresetCombo.active = target_active if @filemanagerPresetCombo.active != target_active
  end

  def sync_app_combos
    sync_editor_combo
    sync_filemanager_combo
  end

#Small table for debugging
#Verbose mode	| debug mode
  def buildFrameDebugOptions # Debug options frame
    @table120 = newTable(rows=1, columns=2)
#creating objects and packing them
    @verbose = Gtk::CheckButton.new(_('Verbose mode'))
    @debug = Gtk::CheckButton.new(_('Debug mode'))
    @table120.attach(@verbose, 0, 0, 1, 1)
    @verbose.hexpand = true
    @table120.attach(@debug, 1, 0, 1, 1)
    @debug.hexpand = true
    @frame120 = newFrame(_('Debug Options'), child=@table120)
  end

  def pack_other_frames #pack all frames into a single page
    @page4 = Gtk::Box.new(:vertical)
    [@frame100, @frame110, @frame120].each{|frame| @page4.pack_start(frame, expand: false, fill: false, padding: 0)}
    @page4_label = Gtk::Label.new(_("Other"))
    @display.signal_connect("switch_page") do |a, b, page|
      if page == 1
        cdrdaoInstalled()
      elsif page == 4
        showFileNormal()
      end
    end
    @display.append_page(@page4, @page4_label)
  end
end

