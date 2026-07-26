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
  extend GetText
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
    @loading = true
    @parent = parent_window
    @initial_countries = initial_countries.to_s.strip
    @result_countries = nil
    @keep_alive = []

    create_dialog
    build_ui
    load_countries(@initial_countries)
    @loading = false
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

    dlg = @dialog
    cleanup
    dlg.destroy if dlg

    @result_countries
  end

  def cleanup
    @keep_alive.clear if @keep_alive
    @dialog = nil
    @available_store = nil
    @preferred_store = nil
    @available_view = nil
    @preferred_view = nil
    @search_entry = nil
    @btn_add = nil
    @btn_remove = nil
    @btn_up = nil
    @btn_down = nil
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
    @preferred_view.model = nil if @preferred_view
    codes = self.class.parse_country_string(str)
    @preferred_store.clear if @preferred_store
    codes.each_with_index do |code, idx|
      name = self.class.country_name_for_code(code)
      iter = @preferred_store.append
      iter.set_values([(idx + 1).to_s, name, code])
    end
    update_ranks
    @preferred_view.model = @preferred_store if @preferred_view
  end

  def generate_country_string
    codes = []
    return '' unless @preferred_store
    iter = @preferred_store.iter_first
    while iter
      codes << iter[2]
      break unless iter.next!
    end
    self.class.format_country_string(codes)
  end

  private

  def create_dialog
    @dialog = Gtk::Dialog.new
    @dialog.title = _("Configure Preferred Countries")
    @dialog.transient_for = @parent if @parent && @parent.is_a?(Gtk::Window)
    @dialog.modal = true
    @dialog.destroy_with_parent = true
    @dialog.add_button(_("Cancel"), Gtk::ResponseType::CANCEL)
    @dialog.add_button(_("Apply"), Gtk::ResponseType::OK)
    @dialog.default_response = Gtk::ResponseType::OK
    @dialog.set_default_size(620, 420)
    @keep_alive << @dialog
  end

  def build_ui
    content_area = @dialog.content_area
    content_area.spacing = 10
    content_area.margin = 10

    lbl_info = Gtk::Label.new(_("Select and order your country release preferences for MusicBrainz (1st = highest priority)."))
    lbl_info.halign = :start
    lbl_info.wrap = true
    content_area.add(lbl_info)
    @keep_alive << lbl_info

    main_hbox = Gtk::Box.new(:horizontal, 8)
    main_hbox.pack_start(build_available_frame, expand: true, fill: true, padding: 0)
    main_hbox.pack_start(build_middle_buttons, expand: false, fill: false, padding: 0)
    main_hbox.pack_start(build_preferred_frame, expand: true, fill: true, padding: 0)
    main_hbox.pack_start(build_right_buttons, expand: false, fill: false, padding: 0)
    @keep_alive << main_hbox

    content_area.pack_start(main_hbox, expand: true, fill: true, padding: 0)
  end

  def build_available_frame
    vbox = Gtk::Box.new(:vertical, 5)

    @search_entry = Gtk::SearchEntry.new
    @search_entry.placeholder_text = _("Search country or code...")
    vbox.pack_start(@search_entry, expand: false, fill: false, padding: 0)
    @keep_alive << @search_entry

    # Store: [Name, Code]
    @available_store = Gtk::ListStore.new(String, String)
    populate_available_store('')
    @keep_alive << @available_store

    @search_entry.signal_connect("search-changed") do
      populate_available_store(@search_entry.text)
      update_buttons_sensitivity
    end

    @available_view = Gtk::TreeView.new(@available_store)
    @available_view.headers_visible = true
    @keep_alive << @available_view

    @renderer_avail_name = Gtk::CellRendererText.new
    @renderer_avail_code = Gtk::CellRendererText.new
    @keep_alive << @renderer_avail_name << @renderer_avail_code

    @col_avail_name = Gtk::TreeViewColumn.new(_("Country"), @renderer_avail_name, text: 0)
    @col_avail_code = Gtk::TreeViewColumn.new(_("Code"), @renderer_avail_code, text: 1)
    @col_avail_name.resizable = true
    @col_avail_code.resizable = true
    @keep_alive << @col_avail_name << @col_avail_code

    @available_view.append_column(@col_avail_name)
    @available_view.append_column(@col_avail_code)

    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_policy(:automatic, :automatic)
    scrolled.add(@available_view)
    vbox.pack_start(scrolled, expand: true, fill: true, padding: 0)
    @keep_alive << scrolled << vbox

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
    @keep_alive << @btn_add << @btn_remove << vbox
    vbox
  end

  def build_preferred_frame
    vbox_tree = Gtk::Box.new(:vertical, 5)

    # Store: [Rank, Name, Code]
    @preferred_store = Gtk::ListStore.new(String, String, String)
    @preferred_view = Gtk::TreeView.new(@preferred_store)
    @preferred_view.headers_visible = true
    @keep_alive << @preferred_store << @preferred_view

    @renderer_pref_rank = Gtk::CellRendererText.new
    @renderer_pref_name = Gtk::CellRendererText.new
    @renderer_pref_code = Gtk::CellRendererText.new
    @keep_alive << @renderer_pref_rank << @renderer_pref_name << @renderer_pref_code

    @col_pref_rank = Gtk::TreeViewColumn.new(_("Rank"), @renderer_pref_rank, text: 0)
    @col_pref_name = Gtk::TreeViewColumn.new(_("Country"), @renderer_pref_name, text: 1)
    @col_pref_code = Gtk::TreeViewColumn.new(_("Code"), @renderer_pref_code, text: 2)
    @col_pref_rank.resizable = false
    @col_pref_name.resizable = true
    @col_pref_code.resizable = true
    @keep_alive << @col_pref_rank << @col_pref_name << @col_pref_code

    @preferred_view.append_column(@col_pref_rank)
    @preferred_view.append_column(@col_pref_name)
    @preferred_view.append_column(@col_pref_code)

    scrolled = Gtk::ScrolledWindow.new
    scrolled.set_policy(:automatic, :automatic)
    scrolled.add(@preferred_view)
    vbox_tree.pack_start(scrolled, expand: true, fill: true, padding: 0)

    @preferred_view.selection.signal_connect("changed") do
      update_buttons_sensitivity
    end
    @preferred_view.signal_connect("row-activated") do
      remove_selected_country
    end

    @keep_alive << scrolled << vbox_tree
    new_frame(_("Preferred Priority Order"), vbox_tree)
  end

  def build_right_buttons
    vbox_order = Gtk::Box.new(:vertical, 8)
    vbox_order.valign = :center

    @btn_up = Gtk::Button.new(label: _("Move up"))
    @btn_down = Gtk::Button.new(label: _("Move down"))

    @btn_up.signal_connect("clicked") { move_selected_up }
    @btn_down.signal_connect("clicked") { move_selected_down }

    vbox_order.pack_start(@btn_up, expand: false, fill: false, padding: 0)
    vbox_order.pack_start(@btn_down, expand: false, fill: false, padding: 0)
    @keep_alive << @btn_up << @btn_down << vbox_order
    vbox_order
  end

  def populate_available_store(query = '')
    return unless @available_store
    @available_store.clear
    q = query.to_s.strip.downcase
    COUNTRY_LIST.each do |country|
      name = _(country[:name])
      code = country[:code]
      if q.empty? || name.downcase.include?(q) || code.downcase.include?(q)
        iter = @available_store.append
        iter.set_values([name, code])
      end
    end
  end

  def new_frame(title, child)
    frame = Gtk::Frame.new(title)
    frame.shadow_type = :etched_in
    frame.border_width = DEFAULT_BORDER_WIDTH
    frame.add(child)
    @keep_alive << frame
    frame
  end

  def safe_selection_selected(view)
    return nil unless view && view.selection && view.model
    return nil unless view.selection.count_selected_rows > 0
    begin
      view.selection.selected
    rescue => e
      nil
    end
  end

  def add_selected_country
    return unless @available_view && @available_store && @preferred_store
    iter = safe_selection_selected(@available_view)
    return unless iter && @available_store.iter_is_valid?(iter)

    name = begin
             @available_store.get_value(iter, 0)
           rescue => e
             nil
           end
    code = begin
             @available_store.get_value(iter, 1)
           rescue => e
             nil
           end
    return unless name && code

    # Don't add duplicate country codes
    already_exists = false
    p_iter = @preferred_store.iter_first
    while p_iter
      if p_iter[2] == code
        already_exists = true
        break
      end
      break unless p_iter.next!
    end

    unless already_exists
      p_iter = @preferred_store.append
      p_iter.set_values(["", name, code])
      update_ranks
    end
    update_buttons_sensitivity
  end

  def remove_selected_country
    return unless @preferred_view && @preferred_store
    iter = safe_selection_selected(@preferred_view)
    return unless iter && @preferred_store.iter_is_valid?(iter)

    @preferred_store.remove(iter)
    update_ranks
    update_buttons_sensitivity
  end

  def move_selected_up
    return unless @preferred_view && @preferred_store
    iter = safe_selection_selected(@preferred_view)
    return unless iter && @preferred_store.iter_is_valid?(iter)

    model = @preferred_store
    path = begin
             model.get_path(iter)
           rescue => e
             nil
           end
    return unless path && path.indices && path.indices[0]
    idx = path.indices[0]
    return if idx == 0

    prev_path = Gtk::TreePath.new((idx - 1).to_s)
    prev_iter = begin
                  model.get_iter(prev_path)
                rescue => e
                  nil
                end
    return unless prev_iter && model.iter_is_valid?(prev_iter)

    model.swap(iter, prev_iter)
    update_ranks

    new_iter = begin
                 model.get_iter(prev_path)
               rescue => e
                 nil
               end
    @preferred_view.selection.select_iter(new_iter) if new_iter && model.iter_is_valid?(new_iter)
    update_buttons_sensitivity
  end

  def move_selected_down
    return unless @preferred_view && @preferred_store
    iter = safe_selection_selected(@preferred_view)
    return unless iter && @preferred_store.iter_is_valid?(iter)

    model = @preferred_store
    path = begin
             model.get_path(iter)
           rescue => e
             nil
           end
    return unless path && path.indices && path.indices[0]
    idx = path.indices[0]
    return if idx >= model.iter_n_children(nil) - 1

    next_path = Gtk::TreePath.new((idx + 1).to_s)
    next_iter = begin
                  model.get_iter(next_path)
                rescue => e
                  nil
                end
    return unless next_iter && model.iter_is_valid?(next_iter)

    model.swap(iter, next_iter)
    update_ranks

    new_iter = begin
                 model.get_iter(next_path)
               rescue => e
                 nil
               end
    @preferred_view.selection.select_iter(new_iter) if new_iter && model.iter_is_valid?(new_iter)
    update_buttons_sensitivity
  end

  def update_ranks
    return unless @preferred_store
    rank = 1
    iter = @preferred_store.iter_first
    while iter
      iter[0] = rank.to_s
      rank += 1
      break unless iter.next!
    end
  end

  def update_buttons_sensitivity
    return if @loading
    return unless @available_view && @preferred_view && @btn_add && @btn_remove && @btn_up && @btn_down

    avail_selected = safe_selection_selected(@available_view)
    avail_selected = nil if avail_selected && @available_store && !@available_store.iter_is_valid?(avail_selected)

    pref_selected = safe_selection_selected(@preferred_view)
    pref_selected = nil if pref_selected && @preferred_store && !@preferred_store.iter_is_valid?(pref_selected)

    @btn_add.sensitive = !avail_selected.nil?
    @btn_remove.sensitive = !pref_selected.nil?

    if pref_selected && @preferred_store
      path = begin
               @preferred_store.get_path(pref_selected)
             rescue => e
               nil
             end
      idx = (path && path.indices && path.indices[0]) ? path.indices[0] : -1
      total = @preferred_store.iter_n_children(nil)
      @btn_up.sensitive = (idx > 0)
      @btn_down.sensitive = (idx >= 0 && idx < total - 1)
    else
      @btn_up.sensitive = false
      @btn_down.sensitive = false
    end
  end
end
