# RubyRipperReborn (r3ripper)

**RubyRipperReborn** is a high-quality audio CD ripper for Linux, BSD, and macOS. It is designed with a singular focus on **data integrity** through its unique "secure rip" method.

RubyRipperReborn is a modernized continuation of **Rubyripper**, originally created by Bouke Woudstra (archived original source: [https://code.google.com/archive/p/rubyripper/](https://code.google.com/archive/p/rubyripper/)). This project has been updated to run on contemporary Linux distributions with modern Ruby (3.4+) and GTK+ 3.

## The Secure Rip Method

Rubyripper ensures your rips are bit-perfect by:
1.  Ripping each track multiple times using `cdparanoia`.
2.  Comparing the results of each trial at the sector level (chunk by chunk).
3.  Only considering a chunk "correct" when a user-defined number of trials (default: 2) produce identical data.
4.  Continuing to rip and compare until a consensus is reached or a maximum trial limit is hit.

## Key Features

*   **Modern Core**: Updated for Ruby 3.4+ and contemporary system libraries.
*   **Modern GUI**: Ported to GTK+ 3 for compatibility with modern desktop environments.
*   **Survivable Metadata**: Queries **GnuDB** (successor to Freedb) and **MusicBrainz** for automatic disc info.
*   **Simultaneous Multi-Codec Encoding**: Rip once, encode to FLAC, MP3, Vorbis, AAC, and WavPack all at the same time using multiple CPU threads.
*   **Advanced Audio Handling**: Support for drive offsets, normalization, ReplayGain, and EAC-compliant cuesheets.

## Installation

### Prerequisites

You will need the following system tools:
*   `cdparanoia` (Required for ripping)
*   `cd-discid` (Recommended for metadata)
*   Encoders: `flac`, `lame`, `vorbis-tools`, etc.

**Development Headers (Required for building gems):**
Most modern Linux distributions require development packages to build Ruby native extensions:
*   **Ubuntu/Debian**: `sudo apt install ruby-dev libffi-dev libyaml-dev libgtk-3-dev gobject-introspection`
*   **Fedora/RHEL**: `sudo dnf install ruby-devel libffi-devel libyaml-devel gtk3-devel gobject-introspection-devel`
*   **Void Linux**: `sudo xbps-install -S base-devel ruby-devel gtk+3-devel libyaml-devel libgirepository-devel`

### Ruby Dependencies

Rubyripper uses Bundler to manage its Ruby environment.

```bash
# Clone the repository
git clone https://github.com/youruser/r3ripper.git
cd r3ripper

# For FULL installation (CLI + GUI)
bundle config set --local path 'vendor/bundle'
bundle install

# For CLI-ONLY installation (Bypasses GTK3 requirements)
bundle config set --local without 'gui'
bundle config set --local path 'vendor/bundle'
bundle install
```

## Usage

### Command Line Interface (CLI)

```bash
./bin/rubyripper_cli
# Or via Bundler:
bundle exec ./bin/rubyripper_cli
```

### Graphical User Interface (GUI)

The GUI has been modernized to use GTK+ 3.

```bash
./bin/rubyripper_gtk2
# Or via Bundler:
bundle exec ./bin/rubyripper_gtk2
```

## Development & Testing

The project includes a comprehensive RSpec test suite that has been updated to RSpec 3 standards.

```bash
# Run all unit tests
bundle exec rspec -I lib
```

## License & Attribution

RubyRipperReborn is based on the original **Rubyripper** project created by Bouke Woudstra ([https://code.google.com/archive/p/rubyripper/](https://code.google.com/archive/p/rubyripper/)).

RubyRipperReborn is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
