#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2011 Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: 
#    you can redistribute it and/or modify it under the terms of
#    the GNU General Public License as published by
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

require 'r3ripper/disc/disc'

# The GtkDisc class shows the disc info
# This is placed in the frame of the main window
# Beside the vertical buttonbox
class GtkDisc
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display, :error, :selection, :disc
 
  def initalize
    @discInfoTable = nil
    @trackInfoTable = nil
    @display = nil
  end
  
  def start
    refresh(firsttime = true)   
  end

  def refresh(firsttime=false)
    @selection = []
    @error = nil
    @disc = Disc.new()
    @disc.scan()

    if @disc.status == 'ok'
      @md = @disc.metadata
      buildDiscInfo unless @discInfoTable
      buildTrackInfo()
      buildLayout() unless @display
      updateDisc(firsttime)
      updateTracks()
    else
      @error = @disc.error
    end
  end
  
  # store any updates the user has made and save the selected tracks
  def save
    @md.artist = @artistEntry.text
    @md.album = @albumEntry.text
    @md.genre = @genreEntry.text
    @md.year = @yearEntry.text if @yearEntry.text.to_i != 0
    @md.discNumber = @discNumberSpin.value.to_i if @freezeCheckbox.active?

    @selection = Array.new #reset the array
    (1..@disc.audiotracks).each do |track|
      @md.setTrackname(track, @trackEntryArray[track-1].text)
      @md.setVarArtist(track, @varArtistEntryArray[track-1].text) if @md.various?
      @selection << track if @checkTrackArray[track-1].active?
    end
  end
  
  private
  
  #create all necessary objects for displaying the discinfo
  def buildDiscInfo
    setDiscValues()
    configDiscValues()
    setDiscSignals()
    packDiscObjects()
  end

  #create all necessary objects for displaying the trackselection
  def buildTrackInfo
    setTrackInfoTable()
    setTrackValues()
    configTrackValues()
    setTrackSignals()
    packTrackObjects()
  end
  
  #pack them together so we can show this beauty to the world :)
  def buildLayout
    setDisplayValues()
    configDisplayValues()
    packDisplayObjects()
  end

  def setDiscValues()
    @discInfoTable = Gtk::Grid.new()

    @artistLabel = Gtk::Label.new(_('Artist:'))
    @albumLabel = Gtk::Label.new(_('Album:'))
    @genreLabel = Gtk::Label.new(_('Genre:'))
    @yearLabel = Gtk::Label.new(_('Year:'))
    @varCheckbox = Gtk::CheckButton.new(_('Mark disc as various artists'))

    @freezeCheckbox = Gtk::CheckButton.new(_('Freeze disc info'))
    @discNumberLabel = Gtk::Label.new(_('Disc:'))
    @discNumberSpin = Gtk::SpinButton.new(1.0, 99.0, 1.0)

    @artistEntry = Gtk::Entry.new()
    @albumEntry = Gtk::Entry.new()
    @genreEntry = Gtk::Entry.new()
    @yearEntry = Gtk::Entry.new()
  end

  def configDiscValues()
    @discInfoTable.column_spacing = 5
    @discInfoTable.row_spacing = 4
    @discInfoTable.border_width = 7

    @artistLabel.halign = :start
    @albumLabel.halign = :start
    @genreLabel.halign = :start
    @yearLabel.halign = :start

    @genreEntry.width_request = 100
    @yearEntry.width_request = 100

    @freezeCheckbox.tooltip_text = _("Use this option to keep the disc info\nfor albums that span multiple discs")
    @discNumberLabel.halign = :start
    @discNumberLabel.sensitive = false
    @discNumberSpin.value = 1.0
    @discNumberSpin.sensitive = false
  end

  def setDiscSignals()
    @varCheckbox.signal_connect("toggled") do
      @varCheckbox.active? ? setVarArtist() : unsetVarArtist()
    end

    @freezeCheckbox.signal_connect("toggled") do
      @discNumberLabel.sensitive = @freezeCheckbox.active?
      @discNumberSpin.sensitive = @freezeCheckbox.active?
    end
  end

  def packDiscObjects()
    # grid.attach(child, left, top, width, height)
    @discInfoTable.attach(@artistLabel, 0, 0, 1, 1) #1st column
    @discInfoTable.attach(@albumLabel, 0, 1, 1, 1)
    @discInfoTable.attach(@artistEntry, 1, 0, 1, 1) #2nd column
    @discInfoTable.attach(@albumEntry, 1, 1, 1, 1)
    @artistEntry.hexpand = true
    @albumEntry.hexpand = true

    @discInfoTable.attach(@genreLabel, 2, 0, 1, 1) #3rd column
    @discInfoTable.attach(@yearLabel, 2, 1, 1, 1)
    @discInfoTable.attach(@genreEntry, 3, 0, 1, 1) #4th column
    @discInfoTable.attach(@yearEntry, 3, 1, 1, 1)

    @discInfoTable.attach(@varCheckbox, 0, 3, 4, 1)
    @discInfoTable.attach(@freezeCheckbox, 0, 2, 2, 1)
    @discInfoTable.attach(@discNumberLabel, 2, 2, 1, 1)
    @discInfoTable.attach(@discNumberSpin, 3, 2, 1, 1)
  end

  def setTrackInfoTable()
    if not @trackInfoTable
      @trackInfoTable = Gtk::Grid.new()
    else
      @trackInfoTable.children.each{|child| @trackInfoTable.remove(child)}
    end
  end
  
  def setTrackValues
    @allTracksButton = Gtk::CheckButton.new(_('All'))
    @varArtistLabel = Gtk::Label.new(_('Artist'))
    @tracknameLabel = Gtk::Label.new(_("Track names \(%s track(s)\)") % [@disc.audiotracks])
    @lengthLabel = Gtk::Label.new(_("Length \(%s\)") % [@disc.playtime])

    @checkTrackArray = Array.new ; @varArtistEntryArray = Array.new ; @trackEntryArray = Array.new ; @lengthLabelArray = Array.new
    (1..@disc.audiotracks).each do |track|
      @checkTrackArray << Gtk::CheckButton.new(track.to_s)
      @varArtistEntryArray << Gtk::Entry.new()
      @trackEntryArray << Gtk::Entry.new()
      @lengthLabelArray << Gtk::Label.new(@disc.getLengthText(track))
    end
  end

  def configTrackValues
    @trackInfoTable.column_spacing = 5
    @trackInfoTable.row_spacing = 4
    @trackInfoTable.border_width = 7

    @allTracksButton.active = true
    @checkTrackArray.each{|checkbox| checkbox.active = true}
  end

  def setTrackSignals()
    @allTracksButton.signal_connect("toggled") do
      @allTracksButton.active? ? @checkTrackArray.each{|box| box.active = true} : @checkTrackArray.each{|box| box.active = false} #signal to toggle on/off all tracks
    end
  end

  # pack with or without support for various artists
  def packTrackObjects
    @trackInfoTable.attach(@allTracksButton, 0, 0, 1, 1) #1st column, 1st row
    @trackInfoTable.attach(@lengthLabel, 3, 0, 1, 1) #4th column, 1st row

    if @md && @md.various?
      @trackInfoTable.attach(@varArtistLabel, 1, 0, 1, 1) #2nd column, 1st row
      @trackInfoTable.attach(@tracknameLabel, 2, 0, 1, 1) #3rd column, 1st row
    else
      @trackInfoTable.attach(@tracknameLabel, 1, 0, 2, 1)
      @tracknameLabel.hexpand = true
    end

    @disc.audiotracks.times do |index|
      row = index + 1
      @trackInfoTable.attach(@checkTrackArray[index], 0, row, 1, 1)
      @trackInfoTable.attach(@lengthLabelArray[index], 3, row, 1, 1)

      if @md && @md.various?
        @trackInfoTable.attach(@varArtistEntryArray[index], 1, row, 1, 1)
        @trackInfoTable.attach(@trackEntryArray[index], 2, row, 1, 1)
      else
        @trackInfoTable.attach(@trackEntryArray[index], 1, row, 2, 1)
        @trackEntryArray[index].hexpand = true
      end
    end
  end

  def setDisplayValues()
    @label10 = Gtk::Label.new()
    @frame10 = Gtk::Frame.new()

    @scrolledWindow = Gtk::ScrolledWindow.new()

    @label20 = Gtk::Label.new()
    @frame20 = Gtk::Frame.new()

    @display = Gtk::Box.new(:vertical) #One Box to rule them all
  end

  def configDisplayValues()
    @label10.set_markup(_("<b>Disc Info</b>"))
    @frame10.shadow_type = :etched_in
    @frame10.label_widget = @label10
    @frame10.border_width = 5

    @scrolledWindow.set_policy(:automatic, :automatic)
    @scrolledWindow.border_width = 5

    @label20.set_markup(_("<b>Track Selection</b>"))
    @frame20.shadow_type = :etched_in
    @frame20.label_widget = @label20
    @frame20.border_width = 5
  end

  def packDisplayObjects()
    @frame10.add(@discInfoTable)

    @scrolledWindow.add(@trackInfoTable)
    @frame20.add(@scrolledWindow)

    @display.pack_start(@frame10, expand: false, fill: false, padding: 0)
    @display.pack_start(@frame20, expand: true, fill: true, padding: 0)
  end

  def updateDisc(firsttime=false)
    if @freezeCheckbox.active? == false
      @artistEntry.text = @md.artist.to_s
      @albumEntry.text = @md.album.to_s
      @genreEntry.text = @md.genre.to_s
      @yearEntry.text = @md.year.to_s
    else
      @discNumberSpin.value += 1.0 unless firsttime
    end
    
    @varCheckbox.active = true if @md.various?
  end

  def updateTracks
    (1..@disc.audiotracks).each do |track|
      @trackEntryArray[track - 1].text = @md.trackname(track).to_s
    end
    setVarArtist() if @md.various?
    @trackInfoTable.show_all()
  end
  
  # update the view for various artists
  def setVarArtist()
    return true if @md.various?
    @md.markVarArtist()
    @disc.audiotracks.times{|index| @varArtistEntryArray[index].text = @md.getVarArtist(index + 1).to_s}
    @disc.audiotracks.times{|index| @trackEntryArray[index].text = @md.trackname(index + 1).to_s}
    updateTracksView()
  end

  # update the view for normal artists
  def unsetVarArtist()
    return true unless @md.various?
    @md.unmarkVarArtist()
    @disc.audiotracks.times{|index| @trackEntryArray[index].text = @md.trackname(index + 1).to_s}
    updateTracksView()
  end
  
  # remove current objects and repackage the view
  def updateTracksView
    @trackInfoTable.each{|child| @trackInfoTable.remove(child)}
    packTrackObjects()
    @trackInfoTable.show_all()
  end
end
