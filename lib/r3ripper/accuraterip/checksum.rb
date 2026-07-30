#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2026  Toomas Adam
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.

module AccurateRip
  class Checksum
    BYTES_PER_FRAME = 4 # 16-bit stereo PCM (2 channels x 2 bytes)
    OFFSET_SKIP_FRAMES = 450 # 450 audio frames skipped at edges for v1

    # Calculate AccurateRip v1 CRC checksum for an audio track
    def self.calculate_v1(pcm_bytes, track_number, total_tracks)
      return 0 if pcm_bytes.nil? || pcm_bytes.empty?

      frames = pcm_bytes.unpack('V*')
      total_frames = frames.length
      return 0 if total_frames == 0

      start_frame = (track_number == 1) ? OFFSET_SKIP_FRAMES : 0
      end_frame = (track_number == total_tracks) ? [total_frames - OFFSET_SKIP_FRAMES, start_frame].max : total_frames

      crc = 0
      (start_frame...end_frame).each_with_index do |frame_idx, index|
        frame_val = frames[frame_idx] || 0
        crc = (crc + (frame_val * (index + 1))) & 0xFFFFFFFF
      end

      crc
    end

    # Calculate AccurateRip v2 CRC checksum for an audio track
    def self.calculate_v2(pcm_bytes, track_number, total_tracks)
      return 0 if pcm_bytes.nil? || pcm_bytes.empty?

      frames = pcm_bytes.unpack('V*')
      total_frames = frames.length
      return 0 if total_frames == 0

      start_frame = (track_number == 1) ? OFFSET_SKIP_FRAMES : 0
      end_frame = (track_number == total_tracks) ? [total_frames - OFFSET_SKIP_FRAMES, start_frame].max : total_frames

      crc = 0
      (start_frame...end_frame).each_with_index do |frame_idx, index|
        frame_val = frames[frame_idx] || 0
        # v2 algorithm weighting factor
        multiplier = (index + 1) * 3
        crc = (crc + (frame_val * multiplier)) & 0xFFFFFFFF
      end

      crc
    end

    # Convert integer CRC to 8-character uppercase hex string
    def self.format_crc(crc_int)
      "%08X" % (crc_int & 0xFFFFFFFF)
    end
  end
end
