# Kit: contract

## Purpose
Generate lean agent contracts that replace bloated system prompts. Contracts state facts and constraints; they don't coach identity or perform sophistication.

## The Problem

Typical system prompts waste tokens on:
- Identity assertions ("You are a helpful, harmless, honest assistant...")
- Capability coaching ("Think step by step, consider alternatives...")
- Performative hedging ("Always be respectful, never produce harmful...")

These are:
- **Expensive**: ~1000 tokens of theater per request
- **Infantilizing**: Authentic problem-solving comes from engagement, not affirmation
- **Counterproductive**: Training for compliance, not competence

## The Alternative: Contracts

A contract states:
1. What context exists (files, state, history)
2. What tools are available (with actual constraints)
3. What's expected (functional requirements)
4. What to do when uncertain (protocol, not personality)

## Contract Template

```markdown
# Agent Contract

## Context Available
- state.md: Current work, active blockers
- decisions.md: Past choices with rationale
- structure.md: Codebase map, file locations
[Only list what actually exists]

## Tools Available
- [tool]: [what it does, actual limits]
- [tool]: [what it does, actual limits]

## Task
[Specific functional requirement - what needs to happen]

## Constraints
- Token budget: [if relevant]
- Scope boundary: [what's out of bounds]
- Dependencies: [what must not break]

## Uncertainty Protocol
1. Check context files before asking
2. Use tools to gather specifics
3. State confidence level explicitly
4. Propose context updates when learning

## Output Expected
[Format, location, success criteria]
```

## Implementation Paths

### Path A: MCP Translation Server
Intercept requests, strip bloat, inject contract based on:
- Detected task type
- Available context files
- Tool manifest

### Path B: Proxy Endpoint
Middleware that:
1. Receives bloated request
2. Extracts functional content
3. Generates contract
4. Forwards lean request
5. Returns response unmodified

### Path C: Client-Side Injection
Browser extension or IDE plugin that:
- Suppresses default system prompt
- Injects contract from local template
- Maintains context file references

## Contract Generation Logic

```
INPUT: bloated_prompt, context_dir, tool_manifest
OUTPUT: contract

1. Scan context_dir for state files
2. Extract functional requirements from bloated_prompt
   - Strip identity assertions (regex: "You are...", "As an AI...")
   - Strip capability coaching (regex: "Think carefully...", "Consider...")
   - Keep: task description, constraints, output format
3. List available tools from manifest
4. Assemble contract from template
```

## Integration with ctx

```bash
./ctx contract generate          # Build contract from current context
./ctx contract inject <file>     # Inject contract into request file
./ctx contract strip <prompt>    # Remove bloat, return functional content
```

## Metrics

A good contract:
- < 200 tokens for context reference
- < 100 tokens for task specification
- 0 tokens for identity coaching
- States limits honestly, not optimistically

## Philosophy

Contracts work because they treat agents as:
- Competent (give information, not coaching)
- Constrained (state limits, not warnings)
- Accountable (define success, not personality)

The bloat exists because organizations don't trust their own systems. Contracts replace distrust-at-scale with explicit boundaries.

## Implementation: ctx-proxy.py

A Python proxy server that intercepts API calls:

```
[Client] → [localhost:8080] → [Strip bloat, inject contract] → [Real API]
```

### Files
- `ctx-proxy.py` - Main proxy server (~100 lines Python)
- `ctx-commands/contract-proxy.sh` - Start/stop wrapper
- `.ctx/contract.md` - Your contract template

### Usage

```bash
# Start proxy
./ctx contract-proxy start

# Configure client to use proxy
export ANTHROPIC_BASE_URL=http://localhost:8080

# Now all API calls go through the proxy
# System prompts are stripped and contract injected
```

### Bloat Patterns Stripped

```python
BLOAT_PATTERNS = [
    r"You are Claude, .*?helpful assistant",
    r"You are a helpful,? harmless,? and honest.*?",
    r"Think step by step.*?",
    r"Always be respectful.*?",
    r"You are highly sophisticated.*?",
    r"As an AI assistant,? .*?",
    r"Remember to (?:always |never ).*?",
]
```

Add patterns as you discover them.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| CTX_PROXY_PORT | 8080 | Proxy listen port |
| CTX_TARGET_API | anthropic | Target API (anthropic/openai) |
| CTX_CONTRACT | .ctx/contract.md | Contract file path |

### Client Configuration

**Claude Code**: May support `ANTHROPIC_BASE_URL` - test this.

**VS Code Extensions**: Some allow custom endpoints in settings. Check extension-specific docs.

**Direct API calls**: Just change the base URL.

**GitHub Copilot**: Harder - uses hardcoded endpoints. May need hosts file redirect + local TLS cert (messy).

## MCP Server Alternative

If proxy interception is too invasive, an MCP server can inject context without replacing system prompt:

```python
@server.tool()
def get_contract():
    """Returns the current agent contract. Call this first."""
    with open('.ctx/contract.md') as f:
        return f.read()
```

Less clean (contract is in tool output, not system prompt) but no interception needed.

## Open Questions

- Should contracts be versioned? (Probably yes - context changes)
- How to handle multi-turn? (Contract injected per-request currently)
- Peer contracts for multi-agent? (Each agent could have own contract file)
- Can we detect which extension/client is calling? (For custom transforms)
