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

class GtkCountryDialog
  include GetText
  GetText.bindtextdomain("rubyripper")

  attr_reader :dialog, :result_countries

  DEFAULT_COLUMN_SPACINGS = 5
  DEFAULT_ROW_SPACINGS = 4
  DEFAULT_BORDER_WIDTH = 7

  COUNTRY_LIST = [
    { code: 'XW', name: 'Worldwide' },
    { code: 'XE', name: 'Europe' },
    { code: 'US', name: 'United States' },
    { code: 'GB', name: 'United Kingdom' },
    { code: 'JP', name: 'Japan' },
    { code: 'DE', name: 'Germany' },
    { code: 'FR', name: 'France' },
    { code: 'CA', name: 'Canada' },
    { code: 'AU', name: 'Australia' },
    { code: 'NL', name: 'Netherlands' },
    { code: 'SE', name: 'Sweden' },
    { code: 'IT', name: 'Italy' },
    { code: 'ES', name: 'Spain' },
    { code: 'BR', name: 'Brazil' },
    { code: 'AT', name: 'Austria' },
    { code: 'BE', name: 'Belgium' },
    { code: 'CH', name: 'Switzerland' },
    { code: 'CZ', name: 'Czech Republic' },
    { code: 'DK', name: 'Denmark' },
    { code: 'FI', name: 'Finland' },
    { code: 'GR', name: 'Greece' },
    { code: 'HK', name: 'Hong Kong' },
    { code: 'HU', name: 'Hungary' },
    { code: 'IE', name: 'Ireland' },
    { code: 'IL', name: 'Israel' },
    { code: 'IN', name: 'India' },
    { code: 'KR', name: 'South Korea' },
    { code: 'MX', name: 'Mexico' },
    { code: 'NO', name: 'Norway' },
    { code: 'NZ', name: 'New Zealand' },
    { code: 'PL', name: 'Poland' },
    { code: 'PT', name: 'Portugal' },
    { code: 'RU', name: 'Russia' },
    { code: 'TW', name: 'Taiwan' },
    { code: 'XU', name: 'Unknown Country / Region' }
  ].freeze

  def initialize(parent_window = nil, initial_countries = '')
    @parent = parent_window
    @initial_countries = initial_countries.to_s.strip
    @result_countries = nil

    create_dialog
    build_ui
    load_countries(@initial_countries)
    update_buttons_sensitivity
  end

  def run
    @dialog.show_all
    response = @dialog.run
    if response == Gtk::ResponseType::OK
      @result_countries = generate_country_string
    else
      @result_countries = nil
    end
    @dialog.destroy
    @result_countries
  end

  # Utility parsing method
  def self.parse_country_string(country_str)
    return [] if country_str.nil? || country_str.strip.empty?

    raw_codes = country_str.to_s.split(/[\s,]+/).map(&:strip).reject(&:empty?).map(&:upcase)
    # Map common aliases if any (e.g. UK -> GB)
    raw_codes.map do |code|
      code == 'UK' ? 'GB' : code
    end.uniq
  end

  # Utility formatting method
  def self.format_country_string(codes_array)
    return '' if codes_array.nil? || codes_array.empty?
    codes_array.join(',')
  end

  # Find country name by 2-letter code
  def self.country_name_for_code(code)
    found = COUNTRY_LIST.find { |c| c[:code].upcase == code.upcase }
    found ? _(found[:name]) : "#{_('Country')} (#{code})"
  end

  def load_countries(str)
    codes = self.class.parse_country_string(str)
    @preferred_store.clear
    codes.each_with_index do |code, idx|
      name = self.class.country_name_for_code(code)
      iter = @preferred_store.append
      iter[0] = (idx + 1).to_s
      iter[1] = name
      iter[2] = code
    end
    update_ranks
  end

  def generate_country_string
    codes = []
    @preferred_store.each do |_model, _path, iter|
      codes << iter[2]
    end
    self.class.format_country_string(codes)
  end

  private

  def create_dialog
    @dialog = Gtk::Dialog.new(
      title: _("Configure Preferred Countries"),
      parent: @parent,
      flags: [:modal, :destroy_with_parent],
      buttons: [
        [_("Cancel"), Gtk::ResponseType::CANCEL],
        [_("Apply"), Gtk::ResponseType::OK]
      ]
    )
    @dialog.default_response = Gtk::ResponseType::OK
    @dialog.set_default_size(620, 420)
  end

  def build_ui
    content_area = @dialog.content_area
    content_area.spacing = 10
    content_area.margin = 10

    lbl_info = Gtk::Label.new(_("Select and order your country release preferences for MusicBrainz (1st = highest priority)."))
    lbl_info.halign = :start
    lbl_info.wrap = true
    content_area.add(lbl_info)

    main_hbox = Gtk::Box.new(:horizontal, 8)
    main_hbox.pack_start(build_available_frame, expand: true, fill: true, padding: 0)
    main_hbox.pack_start(build_middle_buttons, expand: false, fill: false, padding: 0)
    main_hbox.pack_start(build_preferred_frame, expand: true, fill: true, padding: 0)

    content_area.pack_start(main_hbox, expand: true, fill: true, padding: 0)
  end

  def build_available_frame
    vbox = Gtk::Box.new(:vertical, 5)

    @search_entry = Gtk::SearchEntry.new
    @search_entry.placeholder_text = _("Search country or code...")
    vbox.pack_start(@search_entry, expand: false, fill: false, padding: 0)

    # Store: [Name, Code]
    @available_store = Gtk::ListStore.new(String, String)
    populate_available_store

    @filter_store = Gtk::TreeModelFilter.new(@available_store)
    @filter_store.set_visible_func do |_model, iter|
      query = @search_entry.text.to_s.strip.downcase
      if query.empty?
        true
      else
        name = iter[0].to_s.downcase
        code = iter[1].to_s.downcase
        name.include?(query) || code.include?(query)
      end
    end

    @search_entry.signal_connect("search-changed") do
      @filter_store.refilter
    end

    @available_view = Gtk::TreeView.new(@filter_store)
    @available_view.headers_visible = true

    col_name = Gtk::TreeViewColumn.new(_("Country"), Gtk::CellRendererText.new, text: 0)
    col_code = Gtk::TreeViewColumn.new(_("Code"), Gtk::CellRendererText.new, text: 1)
    col_name.resizable = true
    col_code.resizable = true

    @available_view.append_column(col_name)
    @available_view.append_column(col_code)

    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_policy(:automatic, :automatic)
    scrolled.add(@available_view)
    vbox.pack_start(scrolled, expand: true, fill: true, padding: 0)

    @available_view.selection.signal_connect("changed") do
      update_buttons_sensitivity
    end
    @available_view.signal_connect("row-activated") do
      add_selected_country
    end

    new_frame(_("Available Countries"), vbox)
  end

  def build_middle_buttons
    vbox = Gtk::Box.new(:vertical, 8)
    vbox.valign = :center

    @btn_add = Gtk::Button.new(label: _("Add >"))
    @btn_remove = Gtk::Button.new(label: _("< Remove"))

    @btn_add.signal_connect("clicked") { add_selected_country }
    @btn_remove.signal_connect("clicked") { remove_selected_country }

    vbox.pack_start(@btn_add, expand: false, fill: false, padding: 0)
    vbox.pack_start(@btn_remove, expand: false, fill: false, padding: 0)
    vbox
  end

  def build_preferred_frame
    hbox = Gtk::Box.new(:horizontal, 5)
    vbox_tree = Gtk::Box.new(:vertical, 5)

    # Store: [Rank, Name, Code]
    @preferred_store = Gtk::ListStore.new(String, String, String)
    @preferred_view = Gtk::TreeView.new(@preferred_store)
    @preferred_view.headers_visible = true

    col_rank = Gtk::TreeViewColumn.new(_("Rank"), Gtk::CellRendererText.new, text: 0)
    col_name = Gtk::TreeViewColumn.new(_("Country"), Gtk::CellRendererText.new, text: 1)
    col_code = Gtk::TreeViewColumn.new(_("Code"), Gtk::CellRendererText.new, text: 2)
    col_rank.resizable = false
    col_name.resizable = true
    col_code.resizable = true

    @preferred_view.append_column(col_rank)
    @preferred_view.append_column(col_name)
    @preferred_view.append_column(col_code)

    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_policy(:automatic, :automatic)
    scrolled.add(@preferred_view)
    vbox_tree.pack_start(scrolled, expand: true, fill: true, padding: 0)

    vbox_order = Gtk::Box.new(:vertical, 5)
    vbox_order.valign = :center

    @btn_up = Gtk::Button.new(label: _("Move up"))
    @btn_down = Gtk::Button.new(label: _("Move down"))

    @btn_up.signal_connect("clicked") { move_selected_up }
    @btn_down.signal_connect("clicked") { move_selected_down }

    vbox_order.pack_start(@btn_up, expand: false, fill: false, padding: 0)
    vbox_order.pack_start(@btn_down, expand: false, fill: false, padding: 0)

    hbox.pack_start(vbox_tree, expand: true, fill: true, padding: 0)
    hbox.pack_start(vbox_order, expand: false, fill: false, padding: 0)

    @preferred_view.selection.signal_connect("changed") do
      update_buttons_sensitivity
    end
    @preferred_view.signal_connect("row-activated") do
      remove_selected_country
    end

    new_frame(_("Preferred Priority Order"), hbox)
  end

  def populate_available_store
    @available_store.clear
    COUNTRY_LIST.each do |country|
      iter = @available_store.append
      iter[0] = _(country[:name])
      iter[1] = country[:code]
    end
  end

  def new_frame(title, child)
    frame = Gtk::Frame.new(title)
    frame.shadow_type = :etched_in
    frame.border_width = DEFAULT_BORDER_WIDTH
    frame.add(child)
    frame
  end

  def add_selected_country
    iter = @available_view.selection.selected
    return unless iter

    model = @available_view.model
    name = model.get_value(iter, 0)
    code = model.get_value(iter, 1)

    # Don't add duplicate country codes
    already_exists = false
    @preferred_store.each do |_m, _p, p_iter|
      if p_iter[2] == code
        already_exists = true
        break
      end
    end

    unless already_exists
      p_iter = @preferred_store.append
      p_iter[0] = ""
      p_iter[1] = name
      p_iter[2] = code
      update_ranks
    end
    update_buttons_sensitivity
  end

  def remove_selected_country
    iter = @preferred_view.selection.selected
    return unless iter

    @preferred_store.remove(iter)
    update_ranks
    update_buttons_sensitivity
  end

  def move_selected_up
    iter = @preferred_view.selection.selected
    return unless iter

    model = @preferred_store
    path = model.get_path(iter)
    return if path.indices[0] == 0

    prev_path = Gtk::TreePath.new((path.indices[0] - 1).to_s)
    prev_iter = model.get_iter(prev_path)
    return unless prev_iter

    model.swap(iter, prev_iter)
    update_ranks
    @preferred_view.selection.select_iter(iter)
    update_buttons_sensitivity
  end

  def move_selected_down
    iter = @preferred_view.selection.selected
    return unless iter

    model = @preferred_store
    path = model.get_path(iter)
    return if path.indices[0] >= model.iter_n_children(nil) - 1

    next_path = Gtk::TreePath.new((path.indices[0] + 1).to_s)
    next_iter = model.get_iter(next_path)
    return unless next_iter

    model.swap(iter, next_iter)
    update_ranks
    @preferred_view.selection.select_iter(iter)
    update_buttons_sensitivity
  end

  def update_ranks
    rank = 1
    @preferred_store.each do |_model, _path, iter|
      iter[0] = rank.to_s
      rank += 1
    end
  end

  def update_buttons_sensitivity
    avail_selected = @available_view && @available_view.selection.selected
    pref_selected = @preferred_view && @preferred_view.selection.selected

    @btn_add.sensitive = !avail_selected.nil?
    @btn_remove.sensitive = !pref_selected.nil?

    if pref_selected
      path = @preferred_store.get_path(pref_selected)
      idx = path ? path.indices[0] : -1
      total = @preferred_store.iter_n_children(nil)
      @btn_up.sensitive = (idx > 0)
      @btn_down.sensitive = (idx >= 0 && idx < total - 1)
    else
      @btn_up.sensitive = false
      @btn_down.sensitive = false
    end
  end
end
