# frozen_string_literal: true
require_relative "systems/intelligence"
require_relative "systems/governance"
require_relative "systems/coordination"
require_relative "systems/identity"
require_relative "systems/monitoring"
require_relative "tools/fs/list_files"
require_relative "tools/fs/read_file"
require_relative "tools/fs/edit_file"

module Airb
  module Organism
    def self.build
      workspace_root = `git rev-parse --show-toplevel`.strip
      workspace_root = Dir.pwd if workspace_root.empty?

      provider = (ENV["AIRB_PROVIDER"] || "openai").downcase

      driver =
        case provider
        when "anthropic"
          VSM::Drivers::Anthropic::AsyncDriver.new(
            api_key: ENV.fetch("ANTHROPIC_API_KEY"),
            model:   ENV["AIRB_MODEL"] || "claude-4-sonnet-latest"
          )
        when "gemini"
          VSM::Drivers::Gemini::AsyncDriver.new(
            api_key: ENV.fetch("GEMINI_API_KEY"),
            model:   ENV["AIRB_MODEL"] || "gemini-2.5-flash"
          )
        else
          VSM::Drivers::OpenAI::AsyncDriver.new(
            api_key: ENV.fetch("OPENAI_API_KEY"),
            model:   ENV["AIRB_MODEL"] || "gpt-4o-mini"
          )
        end

      VSM::DSL.define(:airb) do
        identity     klass: Airb::Systems::Identity,    args: { name: "airb", invariants: [] }
        governance   klass: Airb::Systems::Governance,  args: { workspace_root: workspace_root }
        coordination klass: Airb::Systems::Coordination
        intelligence klass: Airb::Systems::Intelligence, args: { driver: driver }
        monitoring   klass: VSM::Monitoring

        operations do
          capsule :list_files, klass: Airb::Tools::FS::ListFiles
          capsule :read_file,  klass: Airb::Tools::FS::ReadFile
          capsule :edit_file,  klass: Airb::Tools::FS::EditFile
        end
      end
    end
  end
end

