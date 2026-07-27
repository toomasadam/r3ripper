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

class GtkNamingDialog
  include GetText
  extend GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :dialog, :result_scheme, :scheme_type

  PRESETS = [
    { label: N_('Artist/Album/Track - Title'), pattern: '%a/%b/%n - %t' },
    { label: N_('Artist (Year) Album/Track - Title'), pattern: '%a (%y) %b/%n - %t' },
    { label: N_('Genre/Artist/Album/Track - Title'), pattern: '%g/%a/%b/%n - %t' },
    { label: N_('Artist - Album/Track. Title'), pattern: '%a - %b/%n. %t' }
  ].freeze

  TAG_BUTTONS = [
    { tag: '%a', label: N_('+ Artist') },
    { tag: '%b', label: N_('+ Album') },
    { tag: '%y', label: N_('+ Year') },
    { tag: '%n', label: N_('+ Track #') },
    { tag: '%t', label: N_('+ Title') },
    { tag: '%g', label: N_('+ Genre') },
    { tag: '%f', label: N_('+ Codec') },
    { tag: '%va', label: N_('+ Various') }
  ].freeze

  def initialize(parent_window = nil, scheme_type = 'standard', initial_scheme = '')
    @parent = parent_window
    @scheme_type = scheme_type.to_s
    @initial_scheme = initial_scheme.to_s.strip
    @result_scheme = nil

    create_dialog
    build_ui
    load_initial_scheme
    update_preview
  end

  def run
    @dialog.show_all
    response = @dialog.run
    if response == Gtk::ResponseType::OK
      @result_scheme = @entry_scheme.text.strip
    else
      @result_scheme = nil
    end

    dlg = @dialog
    @dialog = nil
    dlg.destroy if dlg

    @result_scheme
  end

  # Class helper to render sample path output
  def self.render_sample_path(scheme, scheme_type = 'standard', base_dir = '~/Music')
    return '' if scheme.nil? || scheme.strip.empty?

    sample = scheme.dup
    sample.gsub!('%va', 'Various Artists')
    sample.gsub!('%a', scheme_type == 'various' ? 'Various Artists' : 'Pink Floyd')
    sample.gsub!('%b', 'The Dark Side of the Moon')
    sample.gsub!('%y', '1973')
    sample.gsub!('%g', 'Progressive Rock')
    sample.gsub!('%n', '01')
    sample.gsub!('%t', 'Speak to Me')
    sample.gsub!('%f', 'flac')

    ext = scheme_type == 'image' ? '' : '.flac'
    base = base_dir.to_s.empty? ? '~/Music' : base_dir.to_s
    File.join(base, "#{sample}#{ext}")
  end

  private

  def create_dialog
    title_str = case @scheme_type
                when 'various' then _('Various Artists Naming Scheme')
                when 'image' then _('Single File Image Naming Scheme')
                else _('Standard File Naming Scheme')
                end

    @dialog = Gtk::Dialog.new(
      title: title_str,
      parent: @parent,
      flags: [:modal, :destroy_with_parent],
      buttons: [
        [_('Cancel'), Gtk::ResponseType::CANCEL],
        [_('Apply'), Gtk::ResponseType::OK]
      ]
    )
    @dialog.default_response = Gtk::ResponseType::OK
    @dialog.set_default_size(520, -1)
  end

  def build_ui
    content_area = @dialog.content_area
    content_area.margin = 10
    content_area.spacing = 10

    # 1. Presets Frame
    frame_presets = Gtk::Frame.new(_('Preset Templates'))
    box_presets = Gtk::Box.new(:horizontal, 10)
    box_presets.margin = 10

    lbl_preset = Gtk::Label.new(_('Select template:'))
    lbl_preset.halign = :start
    @preset_combo = Gtk::ComboBoxText.new
    @preset_combo.append_text(_('Custom scheme'))
    PRESETS.each { |p| @preset_combo.append_text(_(p[:label])) }
    @preset_combo.active = 0
    @preset_combo.signal_connect('changed') { on_preset_changed }

    box_presets.pack_start(lbl_preset, expand: false, fill: false, padding: 0)
    box_presets.pack_start(@preset_combo, expand: true, fill: true, padding: 0)
    frame_presets.add(box_presets)
    content_area.pack_start(frame_presets, expand: false, fill: true, padding: 0)

    # 2. Pattern Editor Frame
    frame_editor = Gtk::Frame.new(_('Naming Pattern Editor'))
    box_editor = Gtk::Box.new(:vertical, 8)
    box_editor.margin = 10

    lbl_entry = Gtk::Label.new(_('Format string (use slashes for directories):'))
    lbl_entry.halign = :start
    @entry_scheme = Gtk::Entry.new
    @entry_scheme.signal_connect('changed') { update_preview }

    # Quick Tag Insert Buttons
    box_tags = Gtk::FlowBox.new
    box_tags.max_children_per_line = 4
    box_tags.selection_mode = :none
    box_tags.homogeneous = true

    TAG_BUTTONS.each do |tb|
      btn = Gtk::Button.new(label: _(tb[:label]))
      tag = tb[:tag]
      btn.signal_connect('clicked') { insert_tag(tag) }
      box_tags.add(btn)
    end

    box_editor.pack_start(lbl_entry, expand: false, fill: false, padding: 0)
    box_editor.pack_start(@entry_scheme, expand: false, fill: true, padding: 0)
    box_editor.pack_start(box_tags, expand: false, fill: true, padding: 0)
    frame_editor.add(box_editor)
    content_area.pack_start(frame_editor, expand: false, fill: true, padding: 0)

    # 3. Live Preview Frame
    frame_preview = Gtk::Frame.new(_('Live Path Preview'))
    box_preview = Gtk::Box.new(:vertical, 6)
    box_preview.margin = 10

    @preview_label = Gtk::Label.new('')
    @preview_label.halign = :start
    @preview_label.selectable = true
    @preview_label.wrap = true

    box_preview.pack_start(@preview_label, expand: true, fill: true, padding: 0)
    frame_preview.add(box_preview)
    content_area.pack_start(frame_preview, expand: false, fill: true, padding: 0)
  end

  def load_initial_scheme
    @entry_scheme.text = @initial_scheme

    # Check if initial matches a preset
    PRESETS.each_with_index do |p, idx|
      if p[:pattern] == @initial_scheme
        @preset_combo.active = idx + 1
        break
      end
    end
  end

  def on_preset_changed
    idx = @preset_combo.active
    if idx > 0 && PRESETS[idx - 1]
      @entry_scheme.text = PRESETS[idx - 1][:pattern]
    end
  end

  def insert_tag(tag)
    pos = @entry_scheme.position
    txt = @entry_scheme.text.to_s
    new_txt = txt.insert(pos, tag)
    @entry_scheme.text = new_txt
    @entry_scheme.position = pos + tag.length
    @entry_scheme.grab_focus
  end

  def update_preview
    @preview_label.text = self.class.render_sample_path(@entry_scheme.text, @scheme_type)
  end
end
