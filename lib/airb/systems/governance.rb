# frozen_string_literal: true
module Airb
  module Systems
    class Governance < VSM::Governance
      def initialize(workspace_root:)
        @workspace_root = File.expand_path(workspace_root)
        @pending = {}   # corr_id => original :tool_call message
      end

      # Capture bus reference for emitting confirm requests, etc.
      def observe(bus) = (@bus = bus)

      def enforce(message, &pass)
        case message.kind
        when :tool_call
          if risky?(message)
            ensure_corr_id!(message)
            @pending[message.corr_id] = message
            @bus.emit VSM::Message.new(
              kind: :confirm_request,
              payload: confirm_text(message),
              meta: message.meta.merge({ corr_id: message.corr_id }),
              path: [:airb, :governance]
            )
            return true # swallow for now; will resume on confirm_response
          else
            check_paths!(message)
          end
        when :confirm_response
          corr = message.meta&.fetch(:corr_id, nil)
          if corr && (orig = @pending.delete(corr))
            if message.payload[:accepted]
              # proceed with original tool_call
              return pass.call(orig)
            else
              # inform user and drop
              @bus.emit VSM::Message.new(
                kind: :assistant,
                payload: "Cancelled.",
                meta: orig.meta,
                path: [:airb, :governance]
              )
              return true
            end
          end
        end

        pass.call(message)
      end

      private

      def risky?(message)
        message.payload[:tool].to_s == "edit_file"
      end

      def confirm_text(message)
        args = message.payload[:args] || {}
        path = args["path"] || "(no path)"
        "Write to #{path}? (shows diff in a future version)"
      end

      def ensure_corr_id!(message)
        message.corr_id ||= SecureRandom.uuid
      end

      def check_paths!(message)
        args = message.payload[:args] || {}
        if message.payload[:tool].to_s == "edit_file"
          safe_path(args.fetch("path"))
        elsif message.payload[:tool].to_s == "read_file"
          safe_path(args.fetch("path"))
        elsif message.payload[:tool].to_s == "list_files"
          path = args["path"]
          safe_path(path) if path && !path.empty?
        end
      end

      def safe_path(rel)
        full = File.expand_path(File.join(@workspace_root, rel.to_s))
        raise "Path escapes workspace" unless full.start_with?(@workspace_root)
        full
      end
    end
  end
end

