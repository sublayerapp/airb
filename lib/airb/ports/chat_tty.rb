# frozen_string_literal: true
require "json"
require "securerandom"
module Airb
  module Ports
    class ChatTTY < VSM::Port
      def should_render?(message)
        [:assistant_delta, :assistant, :tool_call, :tool_result, :confirm_request].include?(message.kind)
      end

      def loop
        session_id = SecureRandom.uuid
        @capsule.roles[:coordination].grant_floor!(session_id)
        @streaming_active = false
        display_banner
        print "\e[94mYou\e[0m: "

        while (line = $stdin.gets&.chomp)
          @capsule.bus.emit VSM::Message.new(kind: :user, payload: line, meta: { session_id: session_id }, path: [:airb])
          @capsule.roles[:coordination].wait_for_turn_end(session_id)
          print "\e[94mYou\e[0m: "
        end
      end

      private

      def display_banner
        puts <<~BANNER
          \e[91m
           ██████  ██ ██████  ██████ 
          ██    ██ ██ ██   ██ ██   ██
          ████████ ██ ██████  ██████ 
          ██    ██ ██ ██   ██ ██   ██
          ██    ██ ██ ██   ██ ██████ 
          \e[0m
          \e[96mAI-powered Ruby assistant\e[0m (Ctrl-C to exit)
        BANNER
      end

      def render_out(message)
        case message.kind
        when :assistant_delta
          @streaming_active = true
          $stdout.print(message.payload)
          $stdout.flush
        when :assistant
          if @streaming_active
            # We already streamed the content; just end the line cleanly.
            puts
          else
            puts
            puts "\e[93mairb\e[0m: #{message.payload}"
          end
          @streaming_active = false
          # Prompt is printed by the input loop after turn end
        when :tool_call
          tool = message.payload[:tool]
          puts
          puts "\e[90m→ tool\e[0m #{tool}"
        when :tool_result
          # Suppress tool result output; we only announce that the tool was called.
          # Intentionally no-op for cleaner UI.
        when :confirm_request
          print "\n\e[95mconfirm?\e[0m #{message.payload} [y/N] "
          ans = ($stdin.gets || "").strip.downcase.start_with?("y")
          @capsule.bus.emit VSM::Message.new(
            kind: :confirm_response,
            payload: { accepted: ans },
            meta: message.meta,                 # preserve corr_id/session_id
            path: [:airb, :governance]
          )
        when :audit, :policy, :progress
          # optional: print to stderr or keep quiet for now
        end
      end
    end
  end
end

