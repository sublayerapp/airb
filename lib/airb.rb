# frozen_string_literal: true

require "vsm"
require_relative "airb/organism"
require_relative "airb/ports/chat_tty"

module Airb
  class CLI
    def self.start
      capsule = Airb::Organism.build

      # Optional: live visualizer (Lens) from VSM
      if ENV["VSM_LENS"] == "1"
        VSM::Lens.attach!(
          capsule,
          host: "127.0.0.1",
          port: (ENV["VSM_LENS_PORT"] || 9292).to_i,
          token: ENV["VSM_LENS_TOKEN"]
        )
        puts "Lens: http://127.0.0.1:#{ENV['VSM_LENS_PORT'] || 9292}"
      end

      port = Airb::Ports::ChatTTY.new(capsule:)
      VSM::Runtime.start(capsule, ports: [port]) # async reactor + port loop
    end
  end
end

