# frozen_string_literal: true
require "airb"

class FakeDriver
  def run!(conversation:, tools:, policy: {})
    # On first user input, request tool; after tool_result arrives, respond
    last = conversation.last
    if last && last[:role] == "user" && last[:content] =~ /create file/i
      yield :tool_calls, [{ id: "1", name: "edit_file", arguments: { "path" => "tmp.txt", "old_str" => "", "new_str" => "hello" } }]
    elsif last && last[:role] == "tool"
      yield :assistant_final, "Created."
    else
      yield :assistant_final, "Hi."
    end
    :done
  end
end

RSpec.describe "airb organism" do
  include Async::RSpec::Reactor

  it "runs a tool then answers" do
    # Build organism with fake driver
    allow(Airb::Systems::Intelligence).to receive(:new).and_wrap_original do |orig, *args, **kw|
      orig.call(driver: FakeDriver.new)
    end

    # Mock governance to auto-approve all confirmations
    allow(Airb::Systems::Governance).to receive(:new).and_wrap_original do |orig, *args, **kw|
      fake_governance = orig.call(*args, **kw)
      allow(fake_governance).to receive(:risky?).and_return(false)
      fake_governance
    end

    capsule = Airb::Organism.build
    seen = []
    capsule.bus.subscribe { |m| seen << m if [:tool_call, :tool_result, :assistant].include?(m.kind) }

    sid = SecureRandom.uuid

    Async do |task|
      # Start the capsule loop in background
      capsule_task = task.async { capsule.run }
      
      # Give it time to start
      task.sleep(0.01)
      
      capsule.bus.emit VSM::Message.new(kind: :user, payload: "Please create file", meta: { session_id: sid })

      # Wait for the turn to complete
      capsule.roles[:coordination].wait_for_turn_end(sid)
      
      # Stop the capsule
      capsule_task.stop

      # Check that we got the expected message types
      kinds = seen.map(&:kind)
      expect(kinds).to include(:tool_call, :tool_result, :assistant)
    end
  end
end

