#!/usr/bin/env ruby

files = [
  'spec/calcPeakLevel_spec.rb',
  'spec/waveFile_spec.rb',
  'spec/codecs/main_spec.rb',
  'spec/disc/cuesheet_spec.rb',
  'spec/disc/disc_spec.rb',
  'spec/disc/freedbString_spec.rb',
  'spec/disc/musicbrainzLookupPath_spec.rb',
  'spec/disc/RipStrategy_spec.rb',
  'spec/disc/scanDiscCdcontrol_spec.rb',
  'spec/disc/scanDiscCdinfo_spec.rb',
  'spec/disc/scanDiscCdparanoia_spec.rb',
  'spec/disc/scanDiscCdrdao_spec.rb',
  'spec/metadata/main_spec.rb',
  'spec/metadata/filter/filterAll_spec.rb',
  'spec/metadata/filter/filterDirs_spec.rb',
  'spec/metadata/filter/filterFiles_spec.rb',
  'spec/metadata/filter/filterTags_spec.rb',
  'spec/metadata/freedb/freedbRecordParser_spec.rb',
  'spec/metadata/freedb/getFreedbRecord_spec.rb',
  'spec/metadata/freedb/loadFreedbRecord_spec.rb',
  'spec/metadata/freedb/saveFreedbRecord_spec.rb',
  'spec/metadata/musicbrainz/getMusicBrainzRelease_spec.rb',
  'spec/metadata/musicbrainz/musicbrainzReleaseParser_spec.rb',
  'spec/system/dependency_spec.rb',
  'spec/system/network_spec.rb'
]

files.each do |file|
  next unless File.exist?(file)
  content = File.read(file)

  # 1. stub! and stub (handle both with and without parens)
  content.gsub!(/(\w+)\.stub!\((:[^)]+)\)/, 'allow(\1).to receive(\2)')
  content.gsub!(/(\w+)\.stub\((:[^)]+)\)/, 'allow(\1).to receive(\2)')
  
  # 2. should_receive
  content.gsub!(/(\w+)\.should_receive\((:[^)]+)\)/, 'expect(\1).to receive(\2)')

  # 3. should == (multi-line or single line)
  # Match as much as possible until the end of line or start of a block
  # This is still risky but we'll try to be careful.
  content.gsub!(/(\s+)(.+)\.should == (.+)/) do |match|
    indent = $1
    left = $2
    right = $3
    "#{indent}expect(#{left}).to eq(#{right})"
  end

  # 4. should_not ==
  content.gsub!(/(\s+)(.+)\.should_not == (.+)/) do |match|
    indent = $1
    left = $2
    right = $3
    "#{indent}expect(#{left}).not_to eq(#{right})"
  end

  # 5. should be_true / be_false
  content.gsub!(/(\s+)(.+)\.should be_true/, '\1expect(\2).to be true')
  content.gsub!(/(\s+)(.+)\.should be_false/, '\1expect(\2).to be false')

  # 6. lambda { ... }.should raise_error
  content.gsub!(/lambda\s*\{(.*)\}\.should\s+raise_error(\(.*\))?/) do |match|
    block_content = $1
    error_args = $2
    "expect {#{block_content}}.to raise_error#{error_args}"
  end

  # 7. and_return { |arg| ... }
  # Often used like: expect(obj).to receive(:method).and_return { |arg| ... }
  # Should become: expect(obj).to receive(:method) { |arg| ... }
  content.gsub!(/\.and_return\s*\{\s*\|(.+)\|\s*(.*?)\s*\}/m, ' { |\1| \2 }')

  # 8. as_null_object
  # The prompt says: "Remove as_null_object from doubles where it might be causing truthiness issues with boolean checks, or be careful with it."
  # I'll leave it for now unless I see issues.

  File.write(file, content)
end
