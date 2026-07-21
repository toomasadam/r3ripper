#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

require 'rubyripper/metadata/filter/filterAll'

# Store all metadata
module Metadata
  class FilterDirs < FilterAll
    def initialize(data, prefs=nil)
      super(data, prefs)
    end
    
    def filter(item)
      # ensure we work on a copy to avoid side effects
      result = item.dup
      while(result[0] == '.'); result = result[1..-1] ; end
      result.gsub!('$', 'S') #no dollars allowed
      result.gsub!(':', '') #no colons allowed in FAT
      result.gsub!('*', '') #no asterix allowed in FAT
      result.gsub!('?', '') #no question mark allowed in FAT
      result.gsub!('<', '') #no smaller than allowed in FAT
      result.gsub!('>', '') #no greater than allowed in FAT
      result.gsub!('|', '') #no pipe allowed in FAT
      result.gsub!('\\', '') #the \\ means a normal \
      result.gsub!('"', '')
      result.gsub!(" ", "_") if @prefs.noSpaces
      result.downcase! if @prefs.noCapitals
      super(result)
    end
  end
end
