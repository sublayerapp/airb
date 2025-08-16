# frozen_string_literal: true
module Airb
  module Systems
    class Intelligence < VSM::Intelligence
      SYSTEM_PROMPT = <<~PROMPT
        You are "airb", a careful coding assistant inside a git workspace.
        Use tools when needed. Prefer minimal, reversible edits and concise explanations.
      PROMPT

      def initialize(driver:)
        super(driver: driver, system_prompt: SYSTEM_PROMPT)
      end
    end
  end
end

