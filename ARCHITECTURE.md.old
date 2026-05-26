# ctx-framework Architecture

## The Vessel-Process Duality

This framework exhibits a fundamental duality: it is both **vessel** (container for project context) and **process** (tool for maintaining that context). This creates an interesting meta-stability pattern.

### Processes as Vessel Inhabitants

Typical understanding:
- **Vessels** contain processes (projects live in the framework)
- **Processes** execute within vessels (agents use tools to work on projects)

But the maintenance of the vessel is itself a process, attended by the constituent processes. The framework maintains itself through use.

### Stability Gradients and Phase Transitions

The trust→forgive→honor lifecycle creates different **stability gradients**:

```
TRUST (high flux)
├─ Active work
├─ Frequent updates
├─ Low stability
├─ Maximum flexibility
└─ As trust decreases...
    ↓
FORGIVE (reconciliation)
├─ Acknowledged drift
├─ Baseline reset
├─ Opportunity for change
├─ Trust can be renewed OR
└─ Elements can stabilize...
    ↓
HONOR (high stability)
├─ Lessons extracted
├─ Updates more difficult
├─ Foundations laid
├─ Serves as reference
└─ Eventually may need to be re-examined (foundation flexibility)
```

### The Foundation Flexibility Paradox

**The puzzle**:
- Honored elements become **stabilizing foundations** (hard to update)
- But foundations must remain **flexible** for the system to evolve
- How do you relay foundations without destabilizing everything built on them?

**The answer**:
Honored elements are not immutable - they're **compressed lessons with clear provenance**. You can:
1. Honor something with current understanding
2. Build on that foundation
3. Later discover deeper insight
4. **Re-honor** with updated lesson, preserving history
5. Foundation evolves without losing what was learned

Example:
```
Honor v1: "Shader-first architecture works for 2D games"
  → Build 5 games on this

Honor v2: "Shader-first architecture works for 2D;
           learned it struggles with 3D lighting complexity.
           Hybrid approach needed for 3D."
  → Foundation updated, v1 lesson preserved, new work proceeds
```

### Vessel Maintenance as Constituent Process

The framework itself (vessel) is maintained by:
- **Projects** (processes) that extend it with new commands
- **Agents** (processes) that test and refine tools
- **Humans** (processes) that ground philosophical foundations

This creates **emergent stability**:
- Useful patterns get formalized into commands
- Commands that work get promoted from kit → implemented
- Implemented tools that become essential get honored as core
- Core that becomes obsolete can be honored and archived

The vessel evolves through the metabolism of the processes it contains.

## Stability States and Their Properties

### ACTIVE (Trust-dominant)
- **Files**: Current plans, active objectives, recent handoffs
- **Stability**: Low - changes frequently
- **Trust level**: High initially, decays with time
- **Update cost**: Low - change freely
- **Role**: Working memory

### DRIFT (Forgive-enabled)
- **Files**: Stale context, paused plans, outdated state
- **Stability**: Transitional - neither active nor settled
- **Trust level**: Degraded but recoverable
- **Update cost**: Medium - requires reconciliation
- **Role**: Acknowledging reality without judgment

### HONORED (Stability-dominant)
- **Files**: Extracted lessons, archived decisions, proven patterns
- **Stability**: High - rarely changes
- **Trust level**: Different kind - historical truth, not current state
- **Update cost**: High - requires re-examination of foundations
- **Role**: Institutional memory, reference material

### The Phase Diagram

```
                High Trust
                    ↑
                    |
      ACTIVE    ────┼──── Recent Work
      (flux)        |      (0-7 days)
                    |
      ←─────────────┼─────────────→
Low Stability       |       High Stability
                    |
      DRIFT     ────┼──── Stale Context
      (recon)       |      (30+ days)
                    |
      HONORED   ────┼──── Lessons
      (stable)      |      (archived)
                    ↓
                Low Trust
               (for current state)
```

Movement through states:
- Active → Drift: Time passes, context goes stale
- Drift → Active: Forgiveness + updates renew trust
- Drift → Honored: Extract lessons, accept incompletion
- Honored → Honored v2: Re-examination when foundation needs flexibility

## Meta-Stability: The Framework Honoring Itself

From the README:
> "This framework is designed to become unnecessary."

The ultimate vessel-process duality: when the framework's lessons are fully internalized, the framework itself can be honored and archived. The process of context maintenance becomes second nature, requiring less explicit tooling.

But even then, the **lessons** remain honored:
- Assume staleness
- Handoffs are gifts, not contracts
- Bounded files prevent overflow
- Forgiveness is architecture
- Trust through honest evaluation

The vessel may be archived, but the process patterns it taught persist.

## Design Implications

### For Command Design
1. **trust**: Must handle all stability states differently
   - Active: Report freshness
   - Drift: Report need for forgiveness
   - Honored: Report historical nature

2. **forgive**: Enables phase transition Drift → Active
   - Resets trust baseline
   - Documents acknowledgment
   - Creates opportunity for change

3. **honor**: Enables phase transition Drift → Honored
   - Extracts lessons explicitly
   - Preserves intent and outcome
   - Increases stability, decreases update frequency

4. **summarize**: Operates across all states
   - Active: Compress for handoffs
   - Drift: Identify what's still valid
   - Honored: Maintain lesson accessibility

### For Human-Agent Cooperation

The stability gradients inform division of labor:

**Agents operate freely in**:
- Active state (high flux, rapid iteration)
- Creating and updating summaries
- Proposing forgiveness when drift detected
- Drafting lessons for honor candidates

**Humans intervene at**:
- Forgiveness acknowledgment (authorizing baseline reset)
- Honor decisions (what becomes foundation)
- Foundation flexibility (when to re-examine honored lessons)
- Framework evolution (when to honor the framework itself)

This matches natural human capacity: attend to **phase transitions**, not continuous monitoring.

## Practical Example: The Current Session

This very session demonstrates the vessel-process duality:

1. **Process**: Building ctx-framework tooling
2. **Vessel**: ctx-framework as container for context
3. **Meta-process**: The framework teaching itself through being built
4. **Stability transition**:
   - trust/forgive/honor moved from `requested` → `kit`
   - search moved from `kit` → `implemented`
   - .context content sits in `drift` state (48 days stale)

Next natural steps:
- Implement `trust.ps1` to make stability visible
- Run `./ctx trust` on `.context` to see the drift
- Use `./ctx forgive` to acknowledge the raylib project pause
- Consider honoring the raylib plan with extracted shader-first lessons

The framework is being used to maintain itself. Vessel and process unified.

---

**Status**: Design documentation - captures architectural principles
**Created**: 2025-12-06
**Authors**: human (philosophical foundation) + sonnet-4.5 (formalization)
**Next**: Implement trust.ps1 to make these patterns concrete
