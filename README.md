# airb

An open-source, CLI-based programming agent for Rubyists.

## 🌌 Why use airb?

airb is an open‑source, CLI‑based programming agent for Rubyists. We built it to explore a clean, composable agent architecture grounded in cybernetics—specifically Stafford Beer's Viable System Model (VSM)—and to make a practical tool you can run in your terminal to read, list, and edit files with the help of modern LLMs.

**In short:**

- **A new spine for agents:** Operations, Coordination, Intelligence, Governance, Identity—recursive, inspectable, testable.
- **A minimal, useful CLI** that streams responses and uses structured tool calls (no fragile "JSON from text" parsing).
- **A foundation to learn from and extend:** add tools, swap models (OpenAI/Anthropic/Gemini), plug in UI/observability, grow sub‑agents.

If you like small objects, clear seams, and UNIXy ergonomics, airb is for you.

## 🌌 Who benefits from airb?

- **Ruby developers** who want a capable, hackable terminal agent that can actually work on a codebase.
- **Framework/tool authors** exploring agent design (capsules, tools, sub‑agents) with high cohesion & low coupling.
- **Educators and teams** who need a clear, auditable loop to reason about tool calling, streaming, and safety.
- **Researchers** playing with agent recursion (sub‑agents, tool‑as‑capsule), budget homeostasis, and observability.

## 🌌 What does airb do?

A CLI programming agent that:

- **Streams assistant output** to your terminal as it thinks.

- **Uses native, structured tool calling** across providers:
  - OpenAI "tools" (functions) — streaming + parallel tool calls
  - Anthropic tool_use / tool_result — streaming (input_json_delta)
  - Gemini function calling — non‑streaming MVP (streaming later)

- **Ships with core programming tools** (as capsules):
  - `list_files(path?)` — directory listing (dirs end with /)
  - `read_file(path)` — read UTF‑8 text files
  - `edit_file(path, old_str, new_str)` — replace/create with confirmation

- **Runs on a VSM engine** (via the vsm gem):
  - Operations — dispatches tool calls; concurrency per tool
  - Coordination — session floor control & turn lifecycle
  - Intelligence — LLM driver + conversation + streaming
  - Governance — workspace sandbox, confirmations, budgets
  - Identity — purpose/invariants & escalation hooks

- **Provides observability from day one:**
  - JSONL event ledger (`.vsm.log.jsonl`)
  - Optional web Lens (local SSE app) for live timelines

### High‑level architecture

```
airb (top capsule)
├─ Identity        – name, invariants
├─ Governance      – sandbox, confirms, budgets
├─ Coordination    – floor control, turn end
├─ Intelligence    – driver(OpenAI/Anthropic/Gemini), streaming, tool loop
├─ Operations      – dispatch tools as child capsules (parallel)
│   ├─ list_files (tool capsule)
│   ├─ read_file  (tool capsule)
│   └─ edit_file  (tool capsule)
└─ Ports           – ChatTTY (CLI), Lens (web)
```

## 🌌 How to use it

### Install

Requires Ruby 3.4+.

Add to your app or install globally:

```bash
# Using Bundler in a project
bundle add airb

# Or install gem globally
gem install airb
```

airb depends on the vsm gem (the agent runtime & drivers).

### Configure a provider

Pick one provider and set env vars:

```bash
# OpenAI (streaming + tools)
export AIRB_PROVIDER=openai
export OPENAI_API_KEY=sk-...
export AIRB_MODEL=gpt-5-nano   # default if unset

# Anthropic (streaming + tool_use)
# export AIRB_PROVIDER=anthropic
# export ANTHROPIC_API_KEY=...
# export AIRB_MODEL=claude-sonnet-4-0   # default if unset

# Gemini (MVP: non-streaming tool calls)
# export AIRB_PROVIDER=gemini
# export GEMINI_API_KEY=...
# export AIRB_MODEL=gemini-2.5-flash    # default if unset
```

### Quickstart

From the root of a Git repo:

```bash
airb
```

Sample session:

```
airb — chat (Ctrl-C to exit)
You: what's in this directory?
<streams…>
airb: README.md
      lib/
      spec/
      tmp/
You: open README.md
<streams…>
airb: (prints file contents)
You: replace the title with "Airb Demo"
<streams…>
confirm? Write to README.md? [y/N] y
<streams…>
airb: OK. Title updated.
```

### Live visualizer (optional)

Start the local Lens web app (SSE):

```bash
VSM_LENS=1 airb
# Lens: http://127.0.0.1:9292
```

See live timeline & sessions: user messages, assistant deltas, tool calls/results, confirms, audits.

### Configuration reference

| Variable | Meaning | Default |
|----------|---------|---------|
| `AIRB_PROVIDER` | openai \| anthropic \| gemini | openai |
| `AIRB_MODEL` | Model name for chosen provider | see examples above |
| `OPENAI_API_KEY` | OpenAI auth | — |
| `ANTHROPIC_API_KEY` | Anthropic auth | — |
| `GEMINI_API_KEY` | Gemini auth | — |
| `VSM_LENS` | 1 to enable web Lens | off |
| `VSM_LENS_PORT` | Lens port | 9292 |
| `VSM_LENS_TOKEN` | Optional access token (append ?token=...) | none |

**Workspace:** airb auto‑detects repo root (git rev-parse). If not a repo, it uses `Dir.pwd`.

### What happens on each turn?

1. You type text.
2. Intelligence appends it to the conversation and calls the provider driver.
3. The driver streams assistant text (assistant_delta).
4. If the model needs a tool, the driver emits tool_calls → Operations routes to the proper capsule.
5. The tool runs (in parallel, if multiple) and returns tool_result which is fed back to Intelligence.
6. The model produces a final assistant message; Coordination marks the turn complete.
7. Everything is emitted on the bus and logged; the Lens renders it live.

### Provider behavior (at a glance)

| Capability | OpenAI | Anthropic | Gemini (MVP) |
|------------|--------|-----------|--------------|
| Streaming text | ✅ SSE | ✅ SSE (text_delta) | ➖ (planned) |
| Structured tool calls | ✅ tools/tool_calls | ✅ tool_use/tool_result | ✅ functionCall/Response |
| Parallel tool calls | ✅ supported | ✅ supported | ✅ supported |
| System prompt handling | in messages | header param (system) | in content / safety opts |

airb normalizes these differences so your CLI experience is the same.

## Advanced Usage

### Add your own tool (as a capsule)

Create a class that inherits `VSM::ToolCapsule`, describe its schema, implement `#run`.

```ruby
# lib/airb/tools/search_repo.rb
class SearchRepo < VSM::ToolCapsule
  tool_name "search_repo"
  tool_description "Search files for a regex under optional path"
  tool_schema({
    type: "object",
    properties: { path: {type:"string"}, pattern:{type:"string"} },
    required: ["pattern"]
  })

  # Optional: choose how it executes (fiber/thread/ractor/subprocess)
  def execution_mode = :thread

  def run(args)
    root = governance.send(:safe_path, args["path"] || ".")
    rx   = Regexp.new(args["pattern"])
    matches = Dir.glob("#{root}/**/*", File::FNM_DOTMATCH).
      select { |p| File.file?(p) }.
      filter_map do |file|
        lines = File.readlines(file, chomp:true, encoding:"UTF-8") rescue []
        hits  = lines.each_with_index.filter_map { |line,i| "#{file}:#{i+1}:#{line}" if rx.match?(line) }
        hits unless hits.empty?
      end
    matches.flatten.join("\n")
  end
end
```

Register it in your organism under Operations:

```ruby
operations do
  capsule :search_repo, klass: SearchRepo
end
```

The Intelligence system automatically advertises it to the model as a structured tool (OpenAI/Anthropic/Gemini shapes).

### Create a sub‑agent (recursive capsule)

When a "tool" needs multiple steps (plan → read → patch → verify), make it a full capsule with its own 5 systems (Operations/Coordination/Intelligence/Governance/Identity). Expose it as a tool by including `VSM::ActsAsTool` and implementing `#run(args)` that orchestrates internally, then returns a summary.

This keeps the parent simple while the sub‑agent stays cohesive and testable.

### Concurrency & performance

- The runtime uses async fibers for orchestration and streaming.
- Each tool call runs in its own task; set `execution_mode` to `:thread` for CPU‑heavier work.
- Governance can add timeouts and semaphores to limit concurrent tool calls.

### Safety & governance

- airb runs in a workspace sandbox (repo root or CWD).
- `edit_file` prompts for confirmation before writing.
- You can extend Governance to show diffs, enforce allowlists, or budget tokens/time.

## Troubleshooting

- **"No streaming"** — Gemini driver is MVP (non‑streaming). Use OpenAI/Anthropic for streaming.
- **"Path escapes workspace"** — Governance blocked a write; run airb from the repo root or adjust logic.
- **"No tool calls"** — Ensure your provider key & model are set; some models require enabling tools.
- **Lens shows nothing** — Start with `VSM_LENS=1`, then open http://127.0.0.1:9292.

## Table of Contents

- [Why use airb?](#-why-use-airb)
- [Who benefits from airb?](#-who-benefits-from-airb)
- [What does airb do?](#-what-does-airb-do)
- [How to use it](#-how-to-use-it)
  - [Install](#install)
  - [Configure a provider](#configure-a-provider)
  - [Quickstart](#quickstart)
  - [Live visualizer](#live-visualizer-optional)
  - [Configuration reference](#configuration-reference)
  - [Provider behavior](#provider-behavior-at-a-glance)
- [Advanced Usage](#advanced-usage)
  - [Add your own tool](#add-your-own-tool-as-a-capsule)
  - [Create a sub-agent](#create-a-sub-agent-recursive-capsule)
  - [Concurrency & performance](#concurrency--performance)
  - [Safety & governance](#safety--governance)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Roadmap

- Streaming for Gemini driver
- Diff previews & undo for `edit_file`
- MCP client/server ports (tool ecosystem)
- "Command mode" (`airb -e "…"`) for one‑shot automation
- Rich Lens (search, replay, swimlanes, token counters)
- Additional built‑in capsules (planner, tester, editor)

## Contributing

Bug reports, ideas, and PRs welcome!

- Please keep code SRP‑friendly, name things clearly, and favor composition over inheritance.
- Tests for drivers should include small fixture streams → expected events.

## License

MIT (same as vsm), unless noted otherwise in subdirectories.

## Acknowledgements

- Inspired by Stafford Beer's Viable System Model and the broader cybernetics community.
- Thanks to the Ruby OSS ecosystem for gems like async that make structured concurrency practical.
- Early discussions about good agent loops, tool use, and safety shaped this project.
