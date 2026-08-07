#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2011  Ian Jacobi (pipian@pipian.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'r3ripper/preferences/main'
require 'r3ripper/system/dependency'
require 'r3ripper/metadata/musicbrainz/musicbrainzReleaseParser'
require 'r3ripper/metadata/musicbrainz/getMusicBrainzRelease'
# Eeeeh, this didn't need porting from freedb...  Can this be generalized?
require 'r3ripper/metadata/data'

# This class is responsible for getting all metadata of the disc and tracks
class MusicBrainz
attr_reader :status

  # setting up all necessary objects
  def initialize(disc, md=nil, parser=nil, getMusicBrainz=nil, prefs=nil, deps=nil)
    @disc = disc
    @prefs = prefs ? prefs : Preferences::Main.instance
    @deps = deps ? deps : Dependency.instance()
    @md = md ? md : Metadata::Data.new()
    @parser = parser ? parser : MusicBrainzReleaseParser.new(@md)
    @getMusicBrainz = getMusicBrainz ? getMusicBrainz : GetMusicBrainzRelease.new()
  end

  # get the metadata for the disc
  def get()
    @getMusicBrainz.queryDisc(@disc.musicbrainzLookupPath)
    puts "DEBUG: MusicBrainz status after the disc query: #{@getMusicBrainz.status}" if @prefs.debug 
    
    if @getMusicBrainz.status == 'ok'
      @parser.parse(@getMusicBrainz.musicbrainzRelease, @disc.musicbrainzDiscid, @disc.freedbDiscid)
      @status = @parser.status
      if @status == 'ok' && @md.releaseMbid
        fetch_cover_art()
      end
    elsif @getMusicBrainz.status == 'multipleReleases'
      #multiple records
      # This will require showing USEFUL info (more info than a
      # multiple-record freedb result) to disambiguate (status,
      # packaging, country, barcode, date...)
      @status = 'multipleReleases'
    else  # status == 'noMatches'
      @status = 'noMatches'
    end
  end

  # MusicBrainz doesn't require dumb various artist detection.
  def undoVarArtist ; end
  def redoVarArtist ; end

  private

  def fetch_cover_art
    require 'r3ripper/metadata/cover_art'
    cover_art = Metadata::CoverArt.new(@prefs)
    @md.coverArtPath = cover_art.fetch(@md.releaseMbid)
  end

  private

  # if the method is not found try to look it up in the data object
  def method_missing(name, *args)
    @md.send(name, *args)
  end
end