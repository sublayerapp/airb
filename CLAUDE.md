# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem called "airb" - an AI-powered programming assistant that runs in a terminal chat interface. It uses the VSM (Virtual State Machine) framework to coordinate between different systems including intelligence, governance, coordination, identity, and monitoring.

## Development Commands

- `bin/setup` - Install dependencies
- `rake spec` - Run tests
- `bin/console` - Interactive console for experimentation
- `bundle exec rake install` - Install gem locally
- `rake` or `rake default` - Run both tests and RuboCop
- `rake rubocop` - Run RuboCop linter
- `bin/airb` - Run the airb CLI directly

## Architecture

The codebase follows a modular VSM-based architecture:

### Core Components
- `Airb::CLI` - Entry point that builds the organism and starts the runtime
- `Airb::Organism` - Factory that assembles all systems and tools using VSM DSL
- `Airb::Ports::ChatTTY` - Terminal interface for user interaction

### Systems (VSM Components)
- `Intelligence` - Handles LLM interactions with support for OpenAI, Anthropic, and Gemini providers
- `Governance` - Security layer that validates file operations and prompts for risky actions
- `Coordination` - Manages async message flow and turn-taking
- `Identity` - System identification 
- `Monitoring` - VSM monitoring system

### Tools
File system tools in `lib/airb/tools/fs/`:
- `ListFiles` - Directory listing
- `ReadFile` - File reading with path safety
- `EditFile` - File editing with governance approval

## Configuration

- `AIRB_PROVIDER` - LLM provider (openai, anthropic, gemini)
- `AIRB_MODEL` - Specific model to use
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` - API keys
- `VSM_LENS=1` - Enable VSM visualization dashboard
- `VSM_LENS_PORT`, `VSM_LENS_TOKEN` - Lens configuration

## Code Style

- Uses RuboCop with double quotes for strings
- Ruby 3.1+ required
- Frozen string literals enabled throughout
- VSM framework patterns for system composition