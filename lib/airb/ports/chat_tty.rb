# frozen_string_literal: true
module Airb
  module Ports
    class ChatTTY < VSM::Port
      def loop
        session_id = SecureRandom.uuid
        @capsule.roles[:coordination].grant_floor!(session_id)
        puts "airb — chat (Ctrl-C to exit)"
        print "\e[94mYou\e[0m: "

        while (line = $stdin.gets&.chomp)
          @capsule.bus.emit VSM::Message.new(kind: :user, payload: line, meta: { session_id: session_id }, path: [:airb])
          @capsule.roles[:coordination].wait_for_turn_end(session_id)
          print "\e[94mYou\e[0m: "
        end
      end

      def render_out(message)
        case message.kind
        when :assistant_delta
          $stdout.print(message.payload)
          $stdout.flush
        when :assistant
          puts
          puts "\e[93mairb\e[0m: #{message.payload}"
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

