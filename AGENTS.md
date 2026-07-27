# Project Modernization Log - RubyRipperReborn (r3ripper)

**RubyRipperReborn** is a modernized, maintained continuation of **Rubyripper** (originally created by Bouke Woudstra and archived at [https://code.google.com/archive/p/rubyripper/](https://code.google.com/archive/p/rubyripper/)). Originally orphaned in 2014, the project was modernized to run on contemporary Linux distributions with GTK+ 3 and Ruby 3.4+.

## Modernization Agent
*   **Gemini CLI**: An interactive CLI agent specializing in software engineering.

## Summary of Modernization Work (May 2026)

### 1. Environment & Infrastructure
*   **Ruby 3.4+ Support**: Updated the codebase to be fully compatible with Ruby 3.4.9, including handling changes to the standard library (adding `base64` and `rexml` as explicit dependencies).
*   **Dependency Management**: Introduced a standard `Gemfile` and `.gemspec`. Transitioned the project from a legacy custom build system to `Bundler` for reliable, reproducible installations.
*   **Type Safety**: Replaced all instances of deprecated `Fixnum` and `Bignum` with `Integer`.

### 2. Service Migration
*   **Metadata Retrieval**: Migrated the defunct **Freedb.org** provider to **GnuDB.org**, ensuring that automatic disc information retrieval continues to function in the modern era.

### 3. UI Framework Migration (GTK+ 2 to GTK+ 3)
*   **Library Port**: Completely ported the graphical user interface from the deprecated `ruby-gtk2` to the modern `ruby-gtk3`.
*   **Widget Refactoring**: Systematically replaced legacy layout widgets (`Gtk::Table`, `Gtk::VBox`, `Gtk::HBox`) with modern GTK3 equivalents (`Gtk::Grid`, `Gtk::Box`).
*   **API Modernization**: Updated signal connections, object property handling, and layout logic across all 7 GUI-related library files and the main GTK entry point.
*   **Bug Fixes**: Resolved critical logic errors in the GTK controller, including uninitialized variables (`@instances`) and incorrect method referencing.

### 4. Code Quality & Logic Fixes
*   **Data Integrity**: Fixed string mutation bugs in metadata filters (`filterAll`, `filterDirs`, `filterFiles`, `filterTags`) where in-place mutation was causing data side-effects and test failures.
*   **Concurrency**: Resolved a race condition in `ScanDiscCdrdao` related to threaded TOC scanning and error reporting.
*   **Logic Errors**: Fixed flawed `case` statement logic (e.g., `when 211 || 210`) that would have behaved incorrectly in Ruby.

### 5. Test Suite Modernization
*   **RSpec 3 Migration**: Manually refactored the entire test suite (249 examples) from legacy RSpec 2 syntax to modern RSpec 3 (`expect`, `allow`, `receive`).
*   **Verification**: Achieved a 100% pass rate on all core logic, metadata, and codec tests, ensuring a stable and verified baseline for future development.

### 6. CLI Startup & GTK3 GUI Maintenance (July 2026)
*   **File Method Modernization**: Replaced all instances of deprecated/removed `File.exists?` with `File.exist?` across `Preferences::Load`, `Execute`, and `FileAndDir`.
*   **Binary Executable Flags**: Added explicit executable permissions (`chmod +x`) to `bin/rubyripper_cli` and `bin/rubyripper_gtk2`.
*   **Invocation Guard**: Updated script entry point check from `if __FILE__ == $0` to `if File.expand_path(__FILE__) == File.expand_path($0)` to support reliable execution across all shell invocation methods.
*   **GTK3 Widget & Constructor Fixes**:
    *   Updated `Gtk::CheckButton.new(...)` and `Gtk::RadioButton.new(...)` constructors from legacy keyword options to valid GTK3 positional/keyword parameters across `gtkPreferences.rb` and `gtkDisc.rb`.
    *   Updated `Gtk::Label#set_text` calls to single-argument assignments to match GTK3 API contracts.
    *   Updated `GdkPixbuf::Pixbuf.new(file: path)` initialization for window icons.
    *   Guarded `Gtk::BINDING_VERSION` check and added default fallback cases for `loadNormalizer` and `loadMetadataProvider`.
    *   Ensured `.to_s` string conversion on all GTK text and buffer assignments (`Gtk::Entry#text=`, `Gtk::Label#text=`, `Gtk::TextBuffer#insert`) to prevent `nil` `ArgumentError` crashes.
    *   Fixed percent sign format specifier escaping (`%%`) in `RipStatus#updateProgress`.
    *   Fixed `@instances` initialization in `GraphicalUserInterface#initialize`.
*   **Test Suite Stability**: Fixed test pollution and header size assertion math in `spec/waveFile_spec.rb`, bringing total test pass rate to 100% (249/249 passing).

### 7. GNOME HIG GUI Capitalization & Branding Standard
*   **GNOME HIG Compliance**: Standardized all GUI strings to strictly follow GNOME Human Interface Guidelines (HIG):
    *   **Control Labels**: Use **Sentence case** for all push buttons, check buttons, radio buttons, spin buttons, entry labels, and tooltips (e.g., `Mark disc as various artists`, `Pad missing samples with zeros`, `Eject CD when finished`).
    *   **Titles & Headers**: Use **Title Case** for window titles, dialog frames, notebook tabs, section headers, and expander titles (e.g., `Directory Already Exists...`, `CD-ROM Device`, `TOC Analysis`, `Active Audio Codecs`, `Choose Metadata Provider`).
    *   **Proper Software & Technology Naming**: Enforce standard capitalization for technical tools, file formats, and services (`CD-ROM`, `FreeDB`, `MusicBrainz`, `ReplayGain`, `M3U`, `SoX`, `cdparanoia`, `cdrdao`, `cue sheet`, `log file`).
*   **Application Branding**: Updated user-facing application name strings in CLI and GUI to **RubyRipperReborn**.

### 8. GTK3 cdparanoia Configuration Dialog
*   **GTK3 Options Dialog (`GtkCdparanoiaDialog`)**: Added a modal GTK3 configuration dialog to visually select and configure `cdparanoia` options from Preferences:
    *   **Categorized Layout**: Grouped controls into GNOME HIG-compliant frames (`Paranoia & Verification Modes`, `Drive & Speed Controls`, `Custom Parameters`, `Result Preview`).
    *   **Interactive Controls**: Added options for `-Z` (disable extra verification), `-Y` (disable all paranoia), `-X` (disable scratch repair), `-S` (read speed limit), `-o` (overlap search sectors), and custom raw flags.
    *   **Dynamic Mutual Exclusion**: Enforced UI sensitivity rules (e.g., `-Y` automatically disables `-Z` and `-X` controls).
    *   **Live Preview & Bidirectional Parsing**: Real-time generation of command string and parsing of existing option strings upon opening the dialog.
*   **Preferences Integration**: Added `Configure...` push button (`Gtk::Button`) next to `Pass cdparanoia options` in `GtkPreferences`.
*   **Test Suite Expansion**: Added unit tests in `spec/gtk2/gtkCdparanoiaDialog_spec.rb` covering flag parsing, option string formatting, and widget synchronization (262 examples passing).

### 9. GTK3 Preferred Countries Selection Dialog
*   **GTK3 Dual-List Dialog (`GtkCountryDialog`)**: Added a modal GTK3 configuration dialog to visually search, pick, and rank preferred countries for MusicBrainz metadata retrieval:
    *   **Searchable Available List**: Master tree view featuring real-time `Gtk::SearchEntry` filtering over standard MusicBrainz region codes (`XW` Worldwide, `XE` Europe, `XU` Unknown) and ISO 3166-1 country codes.
    *   **Priority Order List**: Ordered tree view displaying active country priorities with rank indices (`1.`, `2.`, `3.`).
    *   **Reordering Controls**: Action push buttons to add countries, remove countries, and shift priority ranks up/down.
    *   **Bidirectional Parsing**: Converts raw comma-separated country codes (including alias mapping like `UK` -> `GB`) on dialog open, and formats ordered strings on apply.
*   **Preferences Integration**: Added `Configure...` push button (`Gtk::Button`) next to `Preferred countries:` in `GtkPreferences`.
*   **Test Suite Expansion**: Added unit tests in `spec/gtk2/gtkCountryDialog_spec.rb` covering country string parsing, code alias mapping, name formatting, and store updates (272 examples passing).

### 10. GTK3 & CLI GnuDB Options Section Modernization
*   **GTK3 Preferences Section (`GtkPreferences`)**:
    *   Renamed section frame title from legacy `FreeDB Options` to **`GnuDB Options`** following GNOME HIG Title Case standards.
    *   Updated primary metadata provider dropdown option from `FreeDB` to **`GnuDB`**.
    *   Standardized control labels to GNOME HIG Sentence case (`Always use first GnuDB hit`, `GnuDB server:`).
    *   Added **Reset to Default** push button (`Gtk::Button`) next to the server entry to quickly restore the default GnuDB endpoint (`http://gnudb.gnudb.org/~cddb/cddb.cgi`).
    *   Added tooltips explaining CDDB protocol handshake identity parameter roles (`Username` & `Hostname`).
*   **CLI Preferences Modernization (`CliPreferences`)**:
    *   Updated menu labels and option prompts from `Freedb...` to **`GnuDB...`**.
*   **Active Audio Codecs Workflow Modernization**: Streamlined codec selection in `GtkPreferences` by automatically adding chosen codecs upon combo box selection (`changed` signal) and removing the redundant `Add` push button. Replaced deprecated `Gtk::Stock::REMOVE` with HIG-compliant labeled push button (`Remove`).
*   **Test Suite Expansion**: Added unit test specs in `spec/gtk2/gtkPreferences_spec.rb` for GnuDB frame initialization, controls, server reset behavior, and codec auto-addition UX (279 examples passing).

### 11. GTK3 Visual Codec Configuration Dialog
*   **GTK3 Codec Options Dialog (`GtkCodecDialog`)**: Added a modal GTK3 configuration dialog to visually select and configure audio encoder options per active codec (`flac`, `opus`, `mp3`, `ogg`, `wavpack`):
    *   **Codec-Specific Controls**: Exposed primary encoder knobs (FLAC compression level 0–8 & verify flag `-V`; Opus bitrate & VBR/CVBR/Hard-VBR modes; LAME MP3 VBR quality vs CBR bitrate; Ogg Vorbis quality level -1–10; WavPack compression mode & bitstream verification).
    *   **Custom Parameters & Real-Time Preview**: Added live option string generator and custom parameter entry for power users.
    *   **Bidirectional Option Parsing**: Robust parsing of CLI flag tokens into visual UI controls on dialog open and formatting back to clean parameter strings on apply.
*   **Preferences Integration**: Added `Configure...` push button (`Gtk::Button`) next to each configurable active audio codec entry in `GtkPreferences`.
*   **Test Suite Expansion**: Added unit test specs in `spec/gtk2/gtkCodecDialog_spec.rb` covering option string parsing, flag formatting, and UI generation for all supported codecs (290 examples passing).

### 12. GTK3 File Naming Scheme Builder & Folder Chooser Modernization
*   **Base Directory Folder Chooser**: Added a **`Browse...`** push button (`Gtk::Button`) next to `Base directory:` in `GtkPreferences` to open native GTK folder chooser dialogs (`Gtk::FileChooserDialog`).
*   **GTK3 Naming Scheme Dialog (`GtkNamingDialog`)**: Added an interactive modal GTK3 configuration builder for file naming patterns:
    *   **Preset Templates**: Built-in dropdown presets (`Artist/Album/Track - Title`, `Artist (Year) Album/Track - Title`, `Genre/Artist/Album/Track - Title`, `Artist - Album/Track. Title`).
    *   **Quick Tag Insertion Bar**: Interactive tag insertion buttons (`[+ Artist]`, `[+ Album]`, `[+ Year]`, `[+ Track #]`, `[+ Title]`, `[+ Genre]`, `[+ Codec]`, `[+ Various]`) inserting format tokens directly at cursor focus.
    *   **Live Path Preview**: Real-time sample file path generator rendering realistic metadata output paths (`Pink Floyd (1973) The Dark Side of the Moon/01 - Speak to Me.flac`).
*   **Preferences Integration**: Added `Configure...` push buttons (`Gtk::Button`) next to `Standard:`, `Various artists:`, and `Single file image:` fields in `GtkPreferences`.
*   **Per-Scheme Live Preview Labels**: Removed the single legacy context-sensitive `@example_label` and `@expander100` expander. Replaced with dedicated, simultaneous live path preview labels directly beneath each of the three scheme fields (`Standard`, `Various artists`, `Single file image`), updating in real-time as paths or schemes are edited.
*   **Test Suite Expansion**: Added unit test specs in `spec/gtk2/gtkNamingDialog_spec.rb` and `spec/gtk2/gtkPreferences_spec.rb` covering sample path rendering, tag insertion, and per-scheme live preview labels (296 examples passing).

## Current Project Status
*   **Core Engine**: Stable and verified on Ruby 3.4+.
*   **CLI Interface**: Fully functional (`bin/rubyripper_cli` or `bundle exec ./bin/rubyripper_cli`).
*   **Modernized GUI**: Fully functional on GTK3 with GNOME HIG compliance (`bin/rubyripper_gtk2` or `bundle exec ./bin/rubyripper_gtk2`).
*   **Test Suite**: Modern RSpec 3, 100% passing (296 examples).
