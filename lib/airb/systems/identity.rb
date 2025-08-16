# frozen_string_literal: true
module Airb
  module Systems
    class Identity < VSM::Identity
      def initialize(name:, invariants: [])
        super(identity: name, invariants: invariants)
      end
    end
  end
end

