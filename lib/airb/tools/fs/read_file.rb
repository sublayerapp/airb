# frozen_string_literal: true
module Airb
  module Tools
    module FS
      class ReadFile < VSM::ToolCapsule
        tool_name "read_file"
        tool_description "Read a UTF-8 text file at relative path."
        tool_schema({
          type: "object",
          properties: { path: { type: "string" } },
          required: ["path"]
        })

        def run(args)
          path = governance.send(:safe_path, args.fetch("path"))
          File.read(path, mode: "r:UTF-8")
        end
      end
    end
  end
end

