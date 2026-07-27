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

class GtkCodecDialog
  include GetText
  extend GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :dialog, :result_options, :codec

  def initialize(parent_window = nil, codec = 'flac', initial_options = '')
    @parent = parent_window
    @codec = codec.to_s.downcase
    @initial_options = initial_options.to_s.strip
    @result_options = nil

    create_dialog
    build_ui
    load_parsed_options(self.class.parse_option_string(@codec, @initial_options))
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
  def self.parse_option_string(codec, options_string)
    codec = codec.to_s.downcase
    opts = { custom_options: '' }
    tokens = split_tokens(options_string)

    case codec
    when 'flac'
      opts[:level] = 5
      opts[:verify] = false
      custom = []
      tokens.each do |tok|
        case tok
        when /^-([0-8])$/
          opts[:level] = $1.to_i
        when '--fast'
          opts[:level] = 0
        when '--best'
          opts[:level] = 8
        when '-V', '--verify'
          opts[:verify] = true
        else
          custom << tok
        end
      end
      opts[:custom_options] = custom.join(' ')

    when 'opus'
      opts[:bitrate] = 160
      opts[:vbr_mode] = :vbr
      custom = []
      i = 0
      while i < tokens.length
        case tokens[i]
        when '--bitrate'
          if i + 1 < tokens.length && tokens[i + 1] =~ /^\d+$/
            opts[:bitrate] = tokens[i + 1].to_i
            i += 1
          end
        when '--vbr'
          opts[:vbr_mode] = :vbr
        when '--hard-vbr'
          opts[:vbr_mode] = :hard_vbr
        when '--cvbr'
          opts[:vbr_mode] = :cvbr
        else
          custom << tokens[i]
        end
        i += 1
      end
      opts[:custom_options] = custom.join(' ')

    when 'mp3', 'lame'
      opts[:mode] = :vbr
      opts[:vbr_quality] = 2
      opts[:cbr_bitrate] = 320
      custom = []
      i = 0
      while i < tokens.length
        case tokens[i]
        when '-V'
          opts[:mode] = :vbr
          if i + 1 < tokens.length && tokens[i + 1] =~ /^\d$/
            opts[:vbr_quality] = tokens[i + 1].to_i
            i += 1
          end
        when /^-V([0-9])$/
          opts[:mode] = :vbr
          opts[:vbr_quality] = $1.to_i
        when '-b'
          opts[:mode] = :cbr
          if i + 1 < tokens.length && tokens[i + 1] =~ /^\d+$/
            opts[:cbr_bitrate] = tokens[i + 1].to_i
            i += 1
          end
        when /^-b(\d+)$/
          opts[:mode] = :cbr
          opts[:cbr_bitrate] = $1.to_i
        else
          custom << tokens[i]
        end
        i += 1
      end
      opts[:custom_options] = custom.join(' ')

    when 'ogg', 'vorbis'
      opts[:quality] = 6
      custom = []
      i = 0
      while i < tokens.length
        case tokens[i]
        when '-q', '--quality'
          if i + 1 < tokens.length && tokens[i + 1] =~ /^-?\d+(\.\d+)?$/
            opts[:quality] = tokens[i + 1].to_f.round
            i += 1
          end
        when /^-q(-?\d+(\.\d+)?)$/
          opts[:quality] = $1.to_f.round
        else
          custom << tokens[i]
        end
        i += 1
      end
      opts[:custom_options] = custom.join(' ')

    when 'wavpack'
      opts[:compression] = :normal
      opts[:verify] = false
      custom = []
      tokens.each do |tok|
        case tok
        when '-f', '--fast'
          opts[:compression] = :fast
        when '-h', '--high'
          opts[:compression] = :high
        when '-hh', '--very-high'
          opts[:compression] = :very_high
        when '-v', '--verify'
          opts[:verify] = true
        else
          custom << tok
        end
      end
      opts[:custom_options] = custom.join(' ')

    else
      opts[:custom_options] = options_string.to_s
    end

    opts
  end

  def self.format_option_string(codec, opts)
    codec = codec.to_s.downcase
    parts = []

    case codec
    when 'flac'
      level = opts[:level] || 5
      parts << "-#{level}"
      parts << "-V" if opts[:verify]
    when 'opus'
      bitrate = opts[:bitrate] || 160
      parts << "--bitrate #{bitrate}"
      mode = opts[:vbr_mode] || :vbr
      parts << "--#{mode.to_s.tr('_', '-')}"
    when 'mp3', 'lame'
      if opts[:mode] == :cbr
        bitrate = opts[:cbr_bitrate] || 320
        parts << "-b #{bitrate}"
      else
        quality = opts[:vbr_quality] || 2
        parts << "-V #{quality}"
      end
    when 'ogg', 'vorbis'
      quality = opts[:quality] || 6
      parts << "-q #{quality}"
    when 'wavpack'
      case opts[:compression]
      when :fast then parts << "-f"
      when :high then parts << "-h"
      when :very_high then parts << "-hh"
      end
      parts << "-v" if opts[:verify]
    end

    custom = opts[:custom_options].to_s.strip
    parts << custom unless custom.empty?
    parts.join(' ')
  end

  def generate_options
    opts = { custom_options: @custom_entry.text.strip }

    case @codec
    when 'flac'
      opts[:level] = @flac_level_spin.value.to_i
      opts[:verify] = @flac_verify_check.active?
    when 'opus'
      opts[:bitrate] = @opus_bitrate_spin.value.to_i
      opts[:vbr_mode] = if @opus_hard_vbr_radio.active?
                          :hard_vbr
                        elsif @opus_cvbr_radio.active?
                          :cvbr
                        else
                          :vbr
                        end
    when 'mp3', 'lame'
      opts[:mode] = @mp3_cbr_radio.active? ? :cbr : :vbr
      opts[:vbr_quality] = @mp3_quality_spin.value.to_i
      opts[:cbr_bitrate] = @mp3_cbr_combo.active_text.to_i
    when 'ogg', 'vorbis'
      opts[:quality] = @ogg_quality_spin.value.to_i
    when 'wavpack'
      opts[:compression] = case @wavpack_comp_combo.active
                           when 1 then :fast
                           when 2 then :high
                           when 3 then :very_high
                           else :normal
                           end
      opts[:verify] = @wavpack_verify_check.active?
    end

    self.class.format_option_string(@codec, opts)
  end

  private

  def self.split_tokens(str)
    return [] if str.nil? || str.strip.empty?
    begin
      Shellwords.split(str)
    rescue ArgumentError
      str.split(/\s+/)
    end
  end

  def create_dialog
    title = case @codec
            when 'flac' then _('FLAC Audio Codec Configuration')
            when 'opus' then _('Opus Audio Codec Configuration')
            when 'mp3', 'lame' then _('MP3 Audio Codec Configuration')
            when 'ogg', 'vorbis' then _('Ogg Vorbis Audio Codec Configuration')
            when 'wavpack' then _('WavPack Audio Codec Configuration')
            else _('Audio Codec Configuration')
            end

    @dialog = Gtk::Dialog.new(
      title: title,
      parent: @parent,
      flags: [:modal, :destroy_with_parent],
      buttons: [
        [_('Cancel'), Gtk::ResponseType::CANCEL],
        [_('Apply'), Gtk::ResponseType::OK]
      ]
    )
    @dialog.default_response = Gtk::ResponseType::OK
    @dialog.set_default_size(480, -1)
  end

  def build_ui
    content_area = @dialog.content_area
    content_area.margin = 10
    content_area.spacing = 10

    # 1. Encoder Options Frame
    frame_options = Gtk::Frame.new(_('Encoder Options'))
    grid_options = Gtk::Grid.new
    grid_options.margin = 10
    grid_options.row_spacing = 8
    grid_options.column_spacing = 12

    build_codec_specific_ui(grid_options)
    frame_options.add(grid_options)
    content_area.pack_start(frame_options, expand: false, fill: true, padding: 0)

    # 2. Custom Options Frame
    frame_custom = Gtk::Frame.new(_('Custom Parameters'))
    grid_custom = Gtk::Grid.new
    grid_custom.margin = 10
    grid_custom.column_spacing = 8

    lbl_custom = Gtk::Label.new(_('Additional parameters:'))
    lbl_custom.halign = :start
    @custom_entry = Gtk::Entry.new
    @custom_entry.hexpand = true
    @custom_entry.signal_connect('changed') { update_preview }

    grid_custom.attach(lbl_custom, 0, 0, 1, 1)
    grid_custom.attach(@custom_entry, 1, 0, 1, 1)
    frame_custom.add(grid_custom)
    content_area.pack_start(frame_custom, expand: false, fill: true, padding: 0)

    # 3. Preview Frame
    frame_preview = Gtk::Frame.new(_('Result Preview'))
    box_preview = Gtk::Box.new(:horizontal, 10)
    box_preview.margin = 10

    lbl_preview_title = Gtk::Label.new(_('Option string:'))
    lbl_preview_title.halign = :start
    @preview_label = Gtk::Label.new('')
    @preview_label.halign = :start
    @preview_label.selectable = true

    box_preview.pack_start(lbl_preview_title, expand: false, fill: false, padding: 0)
    box_preview.pack_start(@preview_label, expand: true, fill: true, padding: 0)
    frame_preview.add(box_preview)
    content_area.pack_start(frame_preview, expand: false, fill: true, padding: 0)
  end

  def build_codec_specific_ui(grid)
    case @codec
    when 'flac'
      lbl_level = Gtk::Label.new(_('Compression level (0–8):'))
      lbl_level.halign = :start
      @flac_level_spin = Gtk::SpinButton.new(0, 8, 1)
      @flac_level_spin.signal_connect('value-changed') { update_preview }

      @flac_verify_check = Gtk::CheckButton.new(_('Verify encoding checksum (-V)'))
      @flac_verify_check.signal_connect('toggled') { update_preview }

      grid.attach(lbl_level, 0, 0, 1, 1)
      grid.attach(@flac_level_spin, 1, 0, 1, 1)
      grid.attach(@flac_verify_check, 0, 1, 2, 1)

    when 'opus'
      lbl_bitrate = Gtk::Label.new(_('Target bitrate (kbps):'))
      lbl_bitrate.halign = :start
      @opus_bitrate_spin = Gtk::SpinButton.new(32, 512, 16)
      @opus_bitrate_spin.signal_connect('value-changed') { update_preview }

      lbl_mode = Gtk::Label.new(_('Encoding mode:'))
      lbl_mode.halign = :start
      @opus_vbr_radio = Gtk::RadioButton.new(member: nil, label: _('Variable (VBR)'))
      @opus_cvbr_radio = Gtk::RadioButton.new(member: @opus_vbr_radio, label: _('Constrained VBR'))
      @opus_hard_vbr_radio = Gtk::RadioButton.new(member: @opus_vbr_radio, label: _('Hard VBR'))

      [@opus_vbr_radio, @opus_cvbr_radio, @opus_hard_vbr_radio].each do |r|
        r.signal_connect('toggled') { update_preview }
      end

      grid.attach(lbl_bitrate, 0, 0, 1, 1)
      grid.attach(@opus_bitrate_spin, 1, 0, 1, 1)
      grid.attach(lbl_mode, 0, 1, 1, 1)
      grid.attach(@opus_vbr_radio, 1, 1, 1, 1)
      grid.attach(@opus_cvbr_radio, 1, 2, 1, 1)
      grid.attach(@opus_hard_vbr_radio, 1, 3, 1, 1)

    when 'mp3', 'lame'
      lbl_mode = Gtk::Label.new(_('Bitrate mode:'))
      lbl_mode.halign = :start
      @mp3_vbr_radio = Gtk::RadioButton.new(member: nil, label: _('Variable Bitrate (VBR)'))
      @mp3_cbr_radio = Gtk::RadioButton.new(member: @mp3_vbr_radio, label: _('Constant Bitrate (CBR)'))

      lbl_quality = Gtk::Label.new(_('VBR quality (0 = Best, 9 = Lowest):'))
      lbl_quality.halign = :start
      @mp3_quality_spin = Gtk::SpinButton.new(0, 9, 1)

      lbl_cbr = Gtk::Label.new(_('CBR bitrate (kbps):'))
      lbl_cbr.halign = :start
      @mp3_cbr_combo = Gtk::ComboBoxText.new
      ['320', '256', '192', '160', '128'].each { |b| @mp3_cbr_combo.append_text(b) }
      @mp3_cbr_combo.active = 0

      @mp3_vbr_radio.signal_connect('toggled') { update_mp3_sensitivity; update_preview }
      @mp3_cbr_radio.signal_connect('toggled') { update_mp3_sensitivity; update_preview }
      @mp3_quality_spin.signal_connect('value-changed') { update_preview }
      @mp3_cbr_combo.signal_connect('changed') { update_preview }

      grid.attach(lbl_mode, 0, 0, 1, 1)
      grid.attach(@mp3_vbr_radio, 1, 0, 1, 1)
      grid.attach(@mp3_cbr_radio, 2, 0, 1, 1)
      grid.attach(lbl_quality, 0, 1, 1, 1)
      grid.attach(@mp3_quality_spin, 1, 1, 2, 1)
      grid.attach(lbl_cbr, 0, 2, 1, 1)
      grid.attach(@mp3_cbr_combo, 1, 2, 2, 1)

    when 'ogg', 'vorbis'
      lbl_quality = Gtk::Label.new(_('Quality level (-1 to 10):'))
      lbl_quality.halign = :start
      @ogg_quality_spin = Gtk::SpinButton.new(-1, 10, 1)
      @ogg_quality_spin.signal_connect('value-changed') { update_preview }

      grid.attach(lbl_quality, 0, 0, 1, 1)
      grid.attach(@ogg_quality_spin, 1, 0, 1, 1)

    when 'wavpack'
      lbl_comp = Gtk::Label.new(_('Compression mode:'))
      lbl_comp.halign = :start
      @wavpack_comp_combo = Gtk::ComboBoxText.new
      @wavpack_comp_combo.append_text(_('Normal'))
      @wavpack_comp_combo.append_text(_('Fast (-f)'))
      @wavpack_comp_combo.append_text(_('High (-h)'))
      @wavpack_comp_combo.append_text(_('Very High (-hh)'))
      @wavpack_comp_combo.active = 0
      @wavpack_comp_combo.signal_connect('changed') { update_preview }

      @wavpack_verify_check = Gtk::CheckButton.new(_('Verify bitstream (-v)'))
      @wavpack_verify_check.signal_connect('toggled') { update_preview }

      grid.attach(lbl_comp, 0, 0, 1, 1)
      grid.attach(@wavpack_comp_combo, 1, 0, 1, 1)
      grid.attach(@wavpack_verify_check, 0, 1, 2, 1)

    else
      lbl_generic = Gtk::Label.new(_('Custom parameter configuration:'))
      lbl_generic.halign = :start
      grid.attach(lbl_generic, 0, 0, 2, 1)
    end
  end

  def load_parsed_options(opts)
    @custom_entry.text = opts[:custom_options].to_s

    case @codec
    when 'flac'
      @flac_level_spin.value = opts[:level] || 5
      @flac_verify_check.active = !!opts[:verify]
    when 'opus'
      @opus_bitrate_spin.value = opts[:bitrate] || 160
      case opts[:vbr_mode]
      when :hard_vbr then @opus_hard_vbr_radio.active = true
      when :cvbr then @opus_cvbr_radio.active = true
      else @opus_vbr_radio.active = true
      end
    when 'mp3', 'lame'
      if opts[:mode] == :cbr
        @mp3_cbr_radio.active = true
        target_b = (opts[:cbr_bitrate] || 320).to_s
        idx = 0
        @mp3_cbr_combo.model.each_with_index do |model, path, iter|
          if iter[0] == target_b
            idx = path.indices[0]
            break
          end
        end
        @mp3_cbr_combo.active = idx
      else
        @mp3_vbr_radio.active = true
        @mp3_quality_spin.value = opts[:vbr_quality] || 2
      end
      update_mp3_sensitivity
    when 'ogg', 'vorbis'
      @ogg_quality_spin.value = opts[:quality] || 6
    when 'wavpack'
      idx = case opts[:compression]
            when :fast then 1
            when :high then 2
            when :very_high then 3
            else 0
            end
      @wavpack_comp_combo.active = idx
      @wavpack_verify_check.active = !!opts[:verify]
    end
  end

  def update_mp3_sensitivity
    return unless @codec == 'mp3' || @codec == 'lame'
    is_cbr = @mp3_cbr_radio.active?
    @mp3_quality_spin.sensitive = !is_cbr
    @mp3_cbr_combo.sensitive = is_cbr
  end

  def update_preview
    @preview_label.text = generate_options
  end
end
