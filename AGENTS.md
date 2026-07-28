# AI Agent Guidelines - RubyRipperReborn (r3ripper)

**RubyRipperReborn** (`r3ripper`) is a modernized digital audio extraction tool for contemporary Linux distributions, featuring both GTK+ 3 graphical and terminal command-line interfaces built with Ruby 3.4+.

This document provides architectural context, development standards, and design guidelines for AI agents working on features, bug fixes, and improvements in this codebase.

---

## 1. Codebase Architecture & Structure

```
r3ripper/
├── bin/
│   ├── rubyripper_cli       # CLI executable entry point
│   └── rubyripper_gtk2      # GTK+ 3 GUI executable entry point
├── lib/
│   └── rubyripper/
│       ├── cli/             # CLI menu handlers (CliPreferences, CliDisc, etc.)
│       ├── codecs/          # Audio encoder wrappers (FLAC, Opus, MP3, Ogg, WavPack)
│       ├── datamodel/       # Data structures & track/disc models
│       ├── disc/            # Disc reading & TOC scanning logic (cdparanoia, cdrdao)
│       ├── gtk2/            # GTK3 GUI windows, modal dialogs, and layout controllers
│       ├── metadata/        # Metadata providers (GnuDB, MusicBrainz) & parser logic
│       ├── modules/         # Utility modules and helpers
│       ├── preferences/     # Settings persistence and default preference loading
│       ├── system/          # System execution & OS-specific drive discovery
│       └── base.rb          # Core application orchestration
├── spec/                    # RSpec 3 unit test suite
│   ├── cli/                 # Unit tests for CLI components
│   ├── gtk2/                # Unit tests for GTK3 dialogs and UI controls
│   └── ...                  # Core logic, metadata, and codec tests
├── Gemfile                  # Dependency manifest (Ruby 3.4+)
└── rubyripper.gemspec       # Gem specification
```

---

## 2. Environment & Development Commands

*   **Ruby Version**: Ruby 3.4+
*   **Dependency Setup**:
    ```bash
    bundle install
    ```
*   **Run Unit Tests**:
    ```bash
    bundle exec rspec
    ```
    *Requirement*: All unit tests must pass with 0 failures before finalizing any changes.
*   **Run CLI Interface**:
    ```bash
    bundle exec ./bin/rubyripper_cli
    ```
*   **Run GTK3 GUI Interface**:
    ```bash
    bundle exec ./bin/rubyripper_gtk2
    ```

---

## 3. Standards & Guidelines for AI Agents

### GTK+ 3 UI Framework Standards
*   **Containers**: Use modern GTK3 layout widgets (`Gtk::Grid`, `Gtk::Box`) instead of deprecated GTK2 widgets (`Gtk::Table`, `Gtk::VBox`, `Gtk::HBox`).
*   **Constructor Signatures**: Use standard GTK3 positional/keyword parameters for widget initialization (e.g., `Gtk::CheckButton`, `Gtk::RadioButton`, `Gtk::Button`).
*   **Safe Property Assignments**: Always perform explicit `.to_s` string conversion on all GTK text and buffer assignments (`Gtk::Entry#text=`, `Gtk::Label#text=`, `Gtk::TextBuffer#insert`) to prevent `nil` `ArgumentError` crashes.

### User Interface Copy & GNOME HIG Standards
All user-facing copy in GUI components, CLI prompts, and dialogs must adhere strictly to GNOME Human Interface Guidelines (HIG):
*   **Control Labels**: Use **Sentence case** for all push buttons, check buttons, radio buttons, spin buttons, entry labels, and tooltips (e.g., `Mark disc as various artists`, `Pad missing samples with zeros`, `Eject CD when finished`).
*   **Titles & Headers**: Use **Title Case** for window titles, dialog frames, notebook tabs, section headers, and expander titles (e.g., `Directory Already Exists...`, `CD-ROM Device`, `TOC Analysis`, `Active Audio Codecs`, `Choose Metadata Provider`).
*   **Proper Software & Technical Terms**: Enforce standard capitalization for technical tools, file formats, and services (`CD-ROM`, `FreeDB`, `GnuDB`, `MusicBrainz`, `ReplayGain`, `M3U`, `SoX`, `cdparanoia`, `cdrdao`, `cue sheet`, `log file`).

### Ruby 3.4+ Code Quality Standards
*   **File API**: Always use `File.exist?` instead of deprecated `File.exists?`.
*   **Types**: Use `Integer` instead of deprecated `Fixnum` or `Bignum`.
*   **Data Integrity**: Avoid unintended in-place string mutations (`String#gsub!`) in metadata filters and filename generators to prevent side-effects across track processing.

### Testing & Verification Hygiene
*   **RSpec 3 Syntax**: Write tests using `expect(...)`, `allow(...)`, and `receive(...)`.
*   **Coverage**: Add unit tests in `spec/` for any new feature, visual configuration dialog, metadata handler, or encoder setting.
*   **No Assertion Suppression**: Never delete failing tests or comment out assertions to hide bugs. Fix the underlying root cause.

---

## 4. History & Modernization Record

For a detailed log of past infrastructure, UI framework migration (GTK2 to GTK3), Freedb to GnuDB service migration, and RSpec 3 modernization milestones, refer to [MODERNIZATION.md](file:///home/smoot/workspace/r3ripper/MODERNIZATION.md).
