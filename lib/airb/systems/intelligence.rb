# frozen_string_literal: true
module Airb
  module Systems
    class Intelligence < VSM::Intelligence
      SYSTEM_PROMPT = <<~PROMPT
        You are "airb", a safe programming assistant inside a git workspace.
        You can call tools to list, read, and edit files. Prefer minimal, reversible edits.
      PROMPT

      def initialize(driver:)
        @driver = driver
        @history_by_session = Hash.new { |h,k| h[k] = [] }
      end

      def handle(message, bus:, **)
        return false unless [:user, :tool_result].include?(message.kind)

        session_id = message.meta&.dig(:session_id)
        history = @history_by_session[session_id]
        history << to_llm_message(message)

        tools, index, family = tool_inventory(bus)

        policy = { system_prompt: SYSTEM_PROMPT }

        @driver.run!(
          conversation: initial_system(family) + history,
          tools: tools,
          policy: policy
        ) do |event, payload|
          case event
          when :assistant_delta
            bus.emit VSM::Message.new(kind: :assistant_delta, payload: payload, meta: { session_id: session_id }, path: [:airb, :intelligence])
          when :assistant_final
            bus.emit VSM::Message.new(kind: :assistant, payload: payload, meta: { session_id: session_id }, path: [:airb, :intelligence])
            history << { role: "assistant", content: payload } unless payload.to_s.empty?
          when :tool_calls
            # record assistant tool_calls for OpenAI & Anthropic history
            if payload.any?
              history << assistant_tool_calls_message(payload)
              payload.each do |tc|
                bus.emit VSM::Message.new(
                  kind: :tool_call,
                  payload: { tool: tc[:name], args: tc[:arguments] },
                  corr_id: tc[:id],
                  meta: { session_id: session_id, tool: tc[:name] },
                  path: [:airb, :operations, tc[:name]]
                )
              end
            end
          end
        end

        true
      end

      private

      def initial_system(family)
        if family == :openai
          [{ role: "system", content: SYSTEM_PROMPT }]
        else
          [] # Anthropic gets system via policy[:system_prompt]; Gemini ignores here
        end
      end

      def to_llm_message(msg)
        case msg.kind
        when :user
          { role: "user", content: msg.payload }
        when :tool_result
          { role: "tool", tool_call_id: msg.corr_id, content: msg.payload.to_s }
        end
      end

      def assistant_tool_calls_message(calls)
        # OpenAI expects an assistant message with tool_calls; Anthropic driver will coerce it to tool_use content blocks;
        # Gemini driver ignores it and relies on subsequent functionResponse.
        { role: "assistant", tool_calls: calls }
      end

      def tool_inventory(bus)
        family = VSM::Drivers::Family.of(@driver)
        openai_tools, anthropic_tools, gemini_decls = [], [], []
        index = {}
        (bus.context[:operations_children] || {}).each do |name, capsule|
          next unless capsule.respond_to?(:tool_descriptor)
          desc = capsule.tool_descriptor
          openai_tools    << desc.to_openai_tool
          anthropic_tools << desc.to_anthropic_tool
          gemini_decls    << desc.to_gemini_tool
          index[desc.name] = capsule
        end
        tools =
          case family
          when :anthropic then anthropic_tools
          when :gemini    then gemini_decls
          else                 openai_tools
          end
        [tools, index, family]
      end
    end
  end
end

