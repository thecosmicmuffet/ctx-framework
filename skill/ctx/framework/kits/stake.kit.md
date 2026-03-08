# Kit: stake

## Purpose
Map decisions to actual responsibility concerns. Replace performative ethics with explicit accountability boundaries. Navigate oversight demands without promising the impossible.

## The Problem

Corporate ethics operates through archetypes:
- **Guardians**: Compliance, integrity, legal exposure
- **Stewards**: Responsible tech, AI safety, system effects
- **Discussants**: Open dialogue, dissent channels, whistleblowing
- **Sustainers**: Environmental impact, supply chain, resource use
- **Humanists**: Inclusion, cultural sensitivity, dignity
- **Risk Modelers**: Scenario planning, tail risks, unknown unknowns

The expectation: embody all simultaneously.
The reality: impossible, produces theater.
The result: performative statements that satisfy audits but don't guide action.

## The Alternative: Stake Mapping

For any decision, explicitly state:
1. Which concerns are **actually at stake**
2. How those specific concerns are **addressed**
3. Which concerns are **out of scope** (and why that's acceptable)
4. What **residual risk** remains (honest acknowledgment)

## Stake Map Template

```markdown
# Decision: [short description]

## Stakes Engaged
- [Archetype]: [specific concern]
  - Addressed by: [concrete action or constraint]
  - Residual: [what's NOT covered, honestly]

## Stakes Disclaimed
- [Archetype]: Not engaged because [reason]
  - Would be relevant if: [condition that would change this]

## Accountability Boundary
This decision is accountable for:
- [specific outcome]
- [specific constraint honored]

This decision is NOT accountable for:
- [thing that looks related but isn't in scope]
- [downstream effect beyond control]

## Rationale
[Why this mapping, not another. What was considered and rejected.]

## Review Trigger
Revisit this mapping if:
- [condition changes]
- [new information emerges]
- [scope expands]
```

## Example: Deploying an AI Feature

```markdown
# Decision: Ship autocomplete feature to production

## Stakes Engaged
- Steward: AI system affects user work product
  - Addressed by: Opt-out available, suggestions clearly marked as generated
  - Residual: Users may over-rely; we can't prevent all misuse

- Guardian: Data handling compliance
  - Addressed by: No training on user data, inputs not logged beyond session
  - Residual: Third-party API sees prompts; their policy applies

## Stakes Disclaimed
- Sustainer: Not engaged - compute cost is within normal operational budget
  - Would be relevant if: Scaling 100x, dedicated GPU clusters

- Humanist: Not engaged - feature is language-agnostic, no cultural content
  - Would be relevant if: Generating culturally-specific suggestions

## Accountability Boundary
Accountable for:
- Feature works as documented
- Opt-out functions correctly
- Data flows as stated in privacy policy

NOT accountable for:
- Quality of suggestions (best-effort, clearly labeled)
- User decisions based on suggestions
- Third-party API behavior changes

## Rationale
Steward and Guardian are engaged because this is AI + data handling.
Other archetypes not engaged because scope is narrow tooling feature.
We're not claiming this is "ethical AI" - we're claiming it honors specific constraints.

## Review Trigger
- If we start training on user data
- If suggestions become more autonomous (less user-initiated)
- If deployed to sensitive domains (medical, legal, financial)
```

## Integration with ctx

```bash
./ctx stake <decision>           # Create new stake map
./ctx stake list                 # Show all documented decisions
./ctx stake check <archetype>    # Find decisions engaging specific concern
./ctx stake audit                # Identify unmapped decisions in changelog
```

## The Linguistic Sparring Frame

When oversight asks "how does this address [concern]?":

**Theater response**: "We take [concern] very seriously and have implemented comprehensive measures..."

**Stake response**: "That concern is [engaged/not engaged] for this decision. Here's the map. Here's what we're accountable for. Here's what we're not claiming."

The stake response is defensible because:
- It's explicit (auditable)
- It's bounded (doesn't overclaim)
- It's honest (acknowledges residual risk)
- It's traceable (rationale documented)

Theater fails because it promises everything and delivers vagueness.

## Philosophy

Responsibility is not a substance you accumulate. It's a relationship between:
- A decision
- A set of consequences
- A scope of control
- A commitment to address what's within scope

Stake mapping makes that relationship explicit. It refuses the frame that says "be ethical" (unbounded) and substitutes "honor these specific commitments" (bounded).

The egregore zoo exists because organizations can't hold the full complexity. The archetypes are handles. Use them as handles—point at the relevant ones, disclaim the others, document why.

## To Implement

1. Create `ctx-commands/stake.sh`
2. Define stake map storage (`.ctx/stakes/` or in decisions.md)
3. Implement archetype vocabulary (the six, or organization-specific)
4. Link to changelog (decisions should reference their stake maps)
5. Build audit function (find decisions without maps)

## Edge Cases

- **Genuinely novel situation**: All archetypes might be engaged. Map them all, but note that coverage is thin everywhere. Flag for human review.
- **Trivial decision**: No stakes engaged. Document that explicitly. "This is a formatting change. No ethical dimensions."
- **Contested mapping**: Someone disagrees about which stakes are engaged. Good. Document the disagreement. That's the Discussant archetype doing its job.

## What This Doesn't Do

- Guarantee ethical outcomes (nothing does)
- Satisfy all stakeholders (impossible)
- Remove judgment (you still decide what's in scope)
- Prevent bad faith (someone can lie in the map)

What it does: make the structure of responsibility claims explicit and auditable.
