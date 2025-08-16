# frozen_string_literal: true
module Airb
  module Tools
    module FS
      class ListFiles < VSM::ToolCapsule
        tool_name "list_files"
        tool_description "List files/directories under a path (default: .). Directories end with '/'."
        tool_schema({
          type: "object",
          properties: { path: { type: "string" } },
          required: []
        })

        def run(args)
          path = args["path"].to_s.empty? ? "." : args["path"]
          root = governance.send(:safe_path, path) rescue Dir.pwd
          entries = Dir.children(root).sort.map do |e|
            full = File.join(root, e)
            File.directory?(full) ? "#{e}/" : e
          end
          entries.join("\n")
        end
      end
    end
  end
end

