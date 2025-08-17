# frozen_string_literal: true

require "airb"
require "async/rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Mock VSM drivers to prevent external API calls in tests
  config.before(:each) do
    # Create a fake driver that doesn't make real API calls
    fake_driver = instance_double("VSM::Driver")
    allow(fake_driver).to receive(:run!).and_yield(:assistant_final, "Mocked response")

    # Mock the driver classes directly to return our fake driver
    allow(VSM::Drivers::OpenAI::AsyncDriver).to receive(:new).and_return(fake_driver)
    allow(VSM::Drivers::Anthropic::AsyncDriver).to receive(:new).and_return(fake_driver)
    allow(VSM::Drivers::Gemini::AsyncDriver).to receive(:new).and_return(fake_driver)

    # Also set fake API keys to prevent ENV.fetch errors
    allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("fake-key")
    allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY").and_return("fake-key") 
    allow(ENV).to receive(:fetch).with("GEMINI_API_KEY").and_return("fake-key")
    allow(ENV).to receive(:fetch).and_call_original
  end

  # Clean up test files after each test
  config.after(:each) do
    File.delete("tmp.txt") if File.exist?("tmp.txt")
  end
end
