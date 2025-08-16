# frozen_string_literal: true
require "fileutils"
module Airb
  module Tools
    module FS
      class EditFile < VSM::ToolCapsule
        tool_name "edit_file"
        tool_description "Replace old_str with new_str in file (create if old_str is empty). Returns 'OK'."
        tool_schema({
          type: "object",
          properties: {
            path:    { type: "string" },
            old_str: { type: "string" },
            new_str: { type: "string" }
          },
          required: ["path","old_str","new_str"]
        })

        def execution_mode = :fiber # change to :thread if you do heavy CPU work

        def run(args)
          path = governance.send(:safe_path, args.fetch("path"))
          old  = args.fetch("old_str")
          newv = args.fetch("new_str")

          if !File.exist?(path) && old.to_s.empty?
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, newv)
            return "OK"
          end

          content  = File.read(path, mode: "r:UTF-8")
          replaced = content.gsub(old, newv)
          raise "old_str not found" if replaced == content && !old.empty?
          File.write(path, replaced)
          "OK"
        end
      end
    end
  end
end

