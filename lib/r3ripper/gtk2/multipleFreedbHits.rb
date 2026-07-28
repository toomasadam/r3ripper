#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010 Bouke Woudstra (boukewoudstra@gmail.com)
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

# MultipleFreedbHitse handles the rubyripper window while displaying the dialog
# when multiple freedb hits are offered to the user.
# Notice that the left part of the gui with the icons is not in this class

class MultipleFreedbHits
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :display

  def initialize(value, main_instance)
    @label1 = Gtk::Label.new(_("The FreeDB server reports multiple hits.\nWhich one would you prefer?"))
    @image1 = Gtk::Image.new(stock: Gtk::Stock::DIALOG_QUESTION, size: :dialog)
    @hbox1 = Gtk::Box.new(:horizontal)
    [@image1, @label1].each{|object| @hbox1.pack_start(object, expand: false, fill: false, padding: 0)}

    @combobox = Gtk::ComboBoxText.new() # text only
    value.each{|freedb_hit| @combobox.append_text(freedb_hit.respond_to?(:title) ? freedb_hit.title.to_s : freedb_hit.to_s)}
    @separator1 = Gtk::Separator.new(:horizontal)
    @hbox2 = Gtk::Box.new(:horizontal)
    @hbox2.pack_start(@combobox, expand: false, fill: false, padding: 5)

    @button1 = Gtk::Button.new
    @label2 = Gtk::Label.new(_("OK"))
    @image2 = Gtk::Image.new(stock: Gtk::Stock::OK, size: :large_toolbar)
    @hbox3 = Gtk::Box.new(:horizontal)
    [@image2, @label2].each{|object| @hbox3.pack_start(object, expand: false, fill: false, padding: 15)}
    @button1.add(@hbox3)
    @hbox4 = Gtk::Box.new(:horizontal)
    @hbox4.pack_start(@button1, expand: true, fill: false, padding: 0)

    @vbox1 = Gtk::Box.new(:vertical)
    @vbox1.border_width = 10
    [@hbox1, @hbox2, @separator1, @hbox4].each{|object| @vbox1.pack_start(object, expand: false, fill: false, padding: 10)}

    @display = Gtk::Frame.new(_("Multiple Hits Found...")) # will contain the above
    @display.shadow_type = :etched_in
    @display.border_width = 5
    @display.add(@vbox1)
    @button1.signal_connect("released") do
      Thread.new do
        main_instance.handleFreedb(@combobox.active)
      end
    end
  end
end
