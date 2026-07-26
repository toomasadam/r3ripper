#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2026 Bouke Woudstra & RubyRipperReborn Contributors
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

require 'gtk3'
require 'shellwords'

class GtkCdparanoiaDialog
  include GetText
  extend GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :dialog, :result_options

  DEFAULT_COLUMN_SPACINGS = 5
  DEFAULT_ROW_SPACINGS = 4
  DEFAULT_BORDER_WIDTH = 7

  def initialize(parent_window = nil, initial_options = '')
    @parent = parent_window
    @initial_options = initial_options.to_s.strip
    @result_options = nil

    create_dialog
    build_ui
    parse_options(@initial_options)
    update_sensitivity
    update_preview
  end

  def run
    @dialog.show_all
    response = @dialog.run
    if response == Gtk::ResponseType::OK
      @result_options = generate_options
    else
      @result_options = nil
    end

    dlg = @dialog
    @dialog = nil
    dlg.destroy if dlg

    @result_options
  end

  # Helper method for parsing option string cleanly
  def self.parse_option_string(options_string)
    parsed = {
      disable_extra: false,    # -Z
      disable_all: false,      # -Y
      disable_scratch: false,  # -X
      limit_speed: false,      # -S
      speed_value: 8,
      custom_overlap: false,   # -o
      overlap_value: 27,
      custom_options: ''
    }

    return parsed if options_string.nil? || options_string.strip.empty?

    begin
      tokens = Shellwords.split(options_string)
    rescue ArgumentError
      tokens = options_string.split(/\s+/)
    end

    custom_tokens = []
    i = 0
    while i < tokens.length
      tok = tokens[i]
      case tok
      when '-Z', '--disable-extra-paranoia'
        parsed[:disable_extra] = true
      when '-Y', '--disable-paranoia'
        parsed[:disable_all] = true
      when '-X', '--disable-scratch-repair'
        parsed[:disable_scratch] = true
      when '-S', '--force-default-speed'
        parsed[:limit_speed] = true
        if i + 1 < tokens.length && tokens[i + 1] =~ /^\d+$/
          parsed[:speed_value] = tokens[i + 1].to_i
          i += 1
        end
      when /^-S(\d+)$/
        parsed[:limit_speed] = true
        parsed[:speed_value] = $1.to_i
      when '-o', '--search-overlap'
        parsed[:custom_overlap] = true
        if i + 1 < tokens.length && tokens[i + 1] =~ /^\d+$/
          parsed[:overlap_value] = tokens[i + 1].to_i
          i += 1
        end
      when /^-o(\d+)$/
        parsed[:custom_overlap] = true
        parsed[:overlap_value] = $1.to_i
      else
        custom_tokens << tok
      end
      i += 1
    end

    parsed[:custom_options] = custom_tokens.join(' ')
    parsed
  end

  # Helper method for formatting options into string
  def self.format_option_string(params)
    tokens = []
    if params[:disable_all]
      tokens << '-Y'
    else
      tokens << '-Z' if params[:disable_extra]
      tokens << '-X' if params[:disable_scratch]
    end

    if params[:limit_speed]
      tokens << "-S #{params[:speed_value]}"
    end

    if params[:custom_overlap]
      tokens << "-o #{params[:overlap_value]}"
    end

    if params[:custom_options] && !params[:custom_options].strip.empty?
      tokens << params[:custom_options].strip
    end

    tokens.join(' ')
  end

  def parse_options(str)
    params = self.class.parse_option_string(str)
    @check_Z.active = params[:disable_extra]
    @check_Y.active = params[:disable_all]
    @check_X.active = params[:disable_scratch]
    @check_S.active = params[:limit_speed]
    @spin_S.value = params[:speed_value].to_f
    @check_o.active = params[:custom_overlap]
    @spin_o.value = params[:overlap_value].to_f
    @entry_custom.text = params[:custom_options]
  end

  def generate_options
    params = {
      disable_extra: @check_Z.active?,
      disable_all: @check_Y.active?,
      disable_scratch: @check_X.active?,
      limit_speed: @check_S.active?,
      speed_value: @spin_S.value.to_i,
      custom_overlap: @check_o.active?,
      overlap_value: @spin_o.value.to_i,
      custom_options: @entry_custom.text
    }
    self.class.format_option_string(params)
  end

  private

  def create_dialog
    @dialog = Gtk::Dialog.new
    @dialog.title = _("Configure cdparanoia Options")
    @dialog.transient_for = @parent if @parent && @parent.is_a?(Gtk::Window)
    @dialog.modal = true
    @dialog.destroy_with_parent = true
    @dialog.add_button(_("Cancel"), Gtk::ResponseType::CANCEL)
    @dialog.add_button(_("Apply"), Gtk::ResponseType::OK)
    @dialog.default_response = Gtk::ResponseType::OK
    @dialog.set_default_size(480, -1)
  end

  def build_ui
    content_area = @dialog.content_area
    content_area.spacing = 10
    content_area.margin = 10

    content_area.add(build_paranoia_frame)
    content_area.add(build_drive_speed_frame)
    content_area.add(build_custom_frame)
    content_area.add(build_preview_frame)
  end

  def build_paranoia_frame
    grid = new_grid
    @check_Z = Gtk::CheckButton.new(_("Disable extra verification (-Z)"))
    @check_Z.tooltip_text = _("Skips extra overlapping boundary checks for faster ripping.")

    @check_Y = Gtk::CheckButton.new(_("Disable all paranoia checks (-Y)"))
    @check_Y.tooltip_text = _("Disables all error correction. Rips quickly but provides no data security.")

    @check_X = Gtk::CheckButton.new(_("Disable scratch repair (-X)"))
    @check_X.tooltip_text = _("Disables heuristic reconstruction of damaged audio sectors.")

    grid.attach(@check_Z, 0, 0, 1, 1)
    grid.attach(@check_Y, 0, 1, 1, 1)
    grid.attach(@check_X, 0, 2, 1, 1)

    @check_Y.signal_connect("toggled") do
      update_sensitivity
      update_preview
    end
    @check_Z.signal_connect("toggled") { update_preview }
    @check_X.signal_connect("toggled") { update_preview }

    new_frame(_("Paranoia & Verification Modes"), grid)
  end

  def build_drive_speed_frame
    grid = new_grid

    @check_S = Gtk::CheckButton.new(_("Limit read speed (-S):"))
    @check_S.tooltip_text = _("Limits CD-ROM read speed to reduce errors on damaged discs.")
    @spin_S = Gtk::SpinButton.new(1.0, 100.0, 1.0)
    @spin_S.value = 8.0

    @check_o = Gtk::CheckButton.new(_("Custom overlap search sectors (-o):"))
    @check_o.tooltip_text = _("Sets sector overlap search size for boundary verification (default is 27).")
    @spin_o = Gtk::SpinButton.new(0.0, 100.0, 1.0)
    @spin_o.value = 27.0

    grid.attach(@check_S, 0, 0, 1, 1)
    grid.attach(@spin_S, 1, 0, 1, 1)
    grid.attach(@check_o, 0, 1, 1, 1)
    grid.attach(@spin_o, 1, 1, 1, 1)

    @check_S.signal_connect("toggled") do
      update_sensitivity
      update_preview
    end
    @spin_S.signal_connect("value-changed") { update_preview }

    @check_o.signal_connect("toggled") do
      update_sensitivity
      update_preview
    end
    @spin_o.signal_connect("value-changed") { update_preview }

    new_frame(_("Drive & Speed Controls"), grid)
  end

  def build_custom_frame
    grid = new_grid
    label = Gtk::Label.new(_("Additional options:"))
    label.halign = :start
    @entry_custom = Gtk::Entry.new
    @entry_custom.tooltip_text = _("Enter any raw cdparanoia flags not listed above (e.g. -c).")

    grid.attach(label, 0, 0, 1, 1)
    grid.attach(@entry_custom, 1, 0, 1, 1)

    @entry_custom.signal_connect("changed") { update_preview }

    new_frame(_("Custom Parameters"), grid)
  end

  def build_preview_frame
    grid = new_grid
    lbl_title = Gtk::Label.new(_("Generated options:"))
    lbl_title.halign = :start
    @preview_label = Gtk::Label.new("")
    @preview_label.halign = :start

    grid.attach(lbl_title, 0, 0, 1, 1)
    grid.attach(@preview_label, 1, 0, 1, 1)

    new_frame(_("Result Preview"), grid)
  end

  def new_grid
    grid = Gtk::Grid.new
    grid.column_spacing = DEFAULT_COLUMN_SPACINGS
    grid.row_spacing = DEFAULT_ROW_SPACINGS
    grid.border_width = DEFAULT_BORDER_WIDTH
    grid
  end

  def new_frame(title, child)
    frame = Gtk::Frame.new(title)
    frame.shadow_type = :etched_in
    frame.border_width = DEFAULT_BORDER_WIDTH
    frame.add(child)
    frame
  end

  def update_sensitivity
    if @check_Y.active?
      @check_Z.sensitive = false
      @check_X.sensitive = false
    else
      @check_Z.sensitive = true
      @check_X.sensitive = true
    end

    @spin_S.sensitive = @check_S.active?
    @spin_o.sensitive = @check_o.active?
  end

  def update_preview
    @preview_label.text = generate_options
  end
end
