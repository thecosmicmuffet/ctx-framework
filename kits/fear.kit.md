# Kit: fear

## Purpose

**Autonomous breakout from recursive loops and multi-project context threading.**

When work becomes circular—repeating similar approaches without progress—the fear command provides structured rotation between projects to break unproductive patterns and identify overlapping goals.

## The Problem

Agents and humans encounter **recursive impediment loops**:
- Same approaches tried repeatedly without progress
- Task identity becomes unstable ("what are we actually building?")
- Superlative agreement masks actual divergence
- Assumptions destabilize but go unrecognized
- Loss of contact between planned structure and actual execution

## The Solution

**Context rotation with intentional threading:**
1. **Snapshot** current state when impediment is detected
2. **Rotate** to different project with explicit context handoff
3. **Reground** in original project with fresh perspective

This creates a **ratchet mechanism**: each rotation preserves progress while approaching the problem from a new angle.

## Terminology (De-Wooed)

| Term | Practical Meaning |
|------|-------------------|
| Fear | Detection signal that current approach has stalled |
| Vessel Analysis | Diagnostic: what has knotted? (content, structure, or process) |
| Rotation | Deliberate context-switch to related project |
| Regrounding | Return to original context with new insights |
| Liturgy | Standardized reflection prompts for impasse moments |

### The Vessel Premise

When impediment appears, diagnose **which component has failed**:
- **Cargo** (content): What we're building is unclear or wrong
- **Container** (structure): How we're organizing is inadequate
- **Journey** (process): The workflow itself is broken

This three-part diagnostic prevents generic "something's wrong" responses.

### Inversion Engine

Most problem-solving approaches from one direction. When stalled:
- The plan is seen as fixed → **Try**: plan as flexible, execution as fixed
- The architecture is seen as given → **Try**: architecture as negotiable
- The goal is seen as clear → **Try**: goal as hypothesis to test

**Rotation inverts the assumption hierarchy.** The problem that was impossible from position A may be trivial from position B.

## Design Principles

1. **Autonomous invocation**: Agents should invoke fear without asking permission when detecting spirals
2. **Structured handoffs**: Rotations preserve thread between projects rather than losing context
3. **Project threading**: Multiple projects inform each other; overlapping goals become visible
4. **No shame protocol**: Invoking fear is assessment, not failure

## Commands

`bash
ctx fear invoke <project-id>    # Snapshot state, perform vessel analysis
ctx fear rotate <to-project>    # Pivot to different project with handoff
ctx fear reground <project-id>  # Return with new perspective
ctx fear assess                 # Evaluate queue health, detect patterns
ctx fear queue                  # Show rotation queue with priorities
ctx fear liturgy <id>           # Display standardized reflection prompt
`

## Integration

### Agent Autonomy

Agents should invoke fear **autonomously** when detecting:

1. **Spiral indicators**:
   - Same file opened 3+ times in succession without meaningful edits
   - Similar solutions attempted repeatedly
   - Token usage climbing without deliverable progress

2. **Identity instability**:
   - Task description changes significantly mid-iteration
   - Goals described with escalating superlatives ("completely", "absolutely")
   - Divergence between stated goal and actions taken

3. **Assumption decay**:
   - Previous "certain" information contradicted
   - Confidence levels lowering across multiple areas
   - Blockers reappearing after being marked resolved

### The Queue

Projects in the rotation queue are **threaded contexts**—not isolated:
- **High frequency**: Active projects being rotated regularly
- **Medium frequency**: Background projects checked periodically
- **Low frequency**: Dormant projects that might inform active work

Queue health is assessed by:
- Rotation diversity (not getting stuck in two-project ping-pong)
- Handoff quality (are threads preserved?)
- Reground effectiveness (does returning bring new perspective?)

## Implementation

### Snapshot Structure

`json
{
  "meta": {
    "project_id": "string",
    "timestamp": "ISO8601",
    "invoked_by": "agent|human"
  },
  "state": {
    "assumptions": ["what seemed stable"],
    "what_seemed_true": "description",
    "impediment_description": "what's blocking",
    "vessel_analysis": {
      "cargo_status": "ok|degraded|blocked",
      "container_status": "ok|degraded|blocked",
      "journey_status": "ok|degraded|blocked",
      "knot_location": "which component failed"
    }
  },
  "context": {
    "recent_iterations": ["summary of recent work"],
    "confidence_level": "high|medium|low",
    "spiral_indicators": ["what suggests we're looping"]
  },
  "rotation": {
    "perspectives_tried": ["approaches already attempted"],
    "suggested_pivots": ["what might help"],
    "reground_triggers": ["when to return"]
  }
}
`

### Handoff Protocol

When rotating, create handoff narrative that:
- **Preserves thread**: Why are these projects related?
- **Carries insights**: What did we learn that's transferable?
- **Frames fresh perspective**: What assumption should we challenge?

### Liturgies

Standardized prompts for specific impasse types:
- **submission**: When plan needs to yield to circumstances
- **inversion**: When assumptions need flipping
- **confusion**: When clarity itself is the obstacle
- **worth**: When value assessment is blocking progress

## Philosophical Grounding (Optional Context)

The term "fear" comes from **signal detection theory**: it's the felt experience at the **mold/form boundary**—the edge where our mental model meets reality and finds mismatch.

**Why "fear" and not "pivot" or "switch"?**

Because genuine impediment involves **uncertainty about what's real**. The comfortable term "pivot" suggests we know what we're doing. "Fear" acknowledges: **we've lost contact with ground truth and need reorientation.**

This is the "exhilarated script" mentioned in the philosophical text—the trembling that moves toward the unknown edge, not away from it.

### The Flower Teaching

Practical interpretation: **Projects exist in networks, not isolation.**

Like flowers producing pollen for other flowers, work on Project A generates insights for Project B. The "vastness and vagueness" is **intentional ambiguity about project boundaries**.

Tight project isolation prevents cross-pollination of ideas. Fear-based rotation makes the boundaries **permeable**.

## Common Patterns

### Two-Project Ping-Pong
**Symptom**: Rotating between same two projects repeatedly  
**Solution**: Force rotation to third project to break dyadic loop

### Premature Regrounding
**Symptom**: Returning too quickly, before gaining new perspective  
**Solution**: Set reground triggers based on concrete achievements, not time

### Thread Loss
**Symptom**: Rotations feel like starting over each time  
**Solution**: Improve handoff narratives, make relationships explicit

### Fear Avoidance
**Symptom**: Agent continues ineffective iteration rather than invoking fear  
**Solution**: Lower invocation threshold, normalize fear as assessment tool

## Success Metrics

Fear is working when:
- Rotations lead to regrounds with demonstrable new approaches
- Multiple projects inform each other (overlapping insights)
- Spiral detection happens earlier (less token waste)
- Handoffs preserve continuity (thread stays intact)
- Queue diversity increases (more cross-pollination)

## To Implement

Create .ctx/fear/ directory structure:
- queue.json: Active projects, rotation history
- orchestration.json: Rotation policies and health metrics
- liturgies.json: Reflection prompts for impasse types
- snapshots/: Project state snapshots
- handoffs/: Context bridge narratives

Commands should:
1. Auto-initialize structure on first use
2. Support both agent and human invocation
3. Generate structured templates for filling
4. Track rotation patterns for health assessment

## Next Steps

1. Test autonomous invocation in agent workflows
2. Develop liturgy collection for common impasses
3. Create health metrics for queue assessment
4. Document handoff quality indicators

---

*Fear is assessment, not failure. Rotation is method, not escape.*
