#!/usr/bin/env python3
"""
AI Business Ideas Research Agent Team
5-agent orchestration: Agents 1-3 run in parallel → Agent 4 (scorer) → Agent 5 (report writer)
"""

import asyncio
import json
import re
import time
from datetime import date

import anthropic

MODEL = "claude-sonnet-4-6"
MAX_TOKENS = 4096

async_client = anthropic.AsyncAnthropic()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def strip_fences(text: str) -> str:
    """Remove markdown code fences so JSON can be parsed."""
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*\n?", "", text, flags=re.MULTILINE)
    text = re.sub(r"\n?```\s*$", "", text, flags=re.MULTILINE)
    return text.strip()


def safe_json(raw: str, agent_name: str):
    """Try to parse JSON; fall back to raw string with a warning."""
    cleaned = strip_fences(raw)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        # Try to extract first JSON array/object from the text
        match = re.search(r"(\[.*\]|\{.*\})", cleaned, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(1))
            except json.JSONDecodeError:
                pass
        print(f"  ⚠  {agent_name}: could not parse JSON — using raw text")
        return raw


def idea_count(data) -> str:
    return str(len(data)) if isinstance(data, list) else "?"


# ---------------------------------------------------------------------------
# Core agentic-loop runner
# ---------------------------------------------------------------------------

async def run_agent(
    name: str,
    system_prompt: str,
    user_message: str,
    use_web_search: bool = False,
    max_retries: int = 1,
) -> str:
    """
    Run a single Claude agent with an agentic loop that handles tool_use.
    Retries once on failure.
    """
    tools = [{"type": "web_search_20250305"}] if use_web_search else []

    for attempt in range(max_retries + 1):
        try:
            messages = [{"role": "user", "content": user_message}]

            while True:
                kwargs: dict = {
                    "model": MODEL,
                    "max_tokens": MAX_TOKENS,
                    "system": system_prompt,
                    "messages": messages,
                }
                if tools:
                    kwargs["tools"] = tools

                resp = await async_client.messages.create(**kwargs)

                text_blocks = [b.text for b in resp.content if b.type == "text"]
                tool_use_blocks = [b for b in resp.content if b.type == "tool_use"]

                if resp.stop_reason == "end_turn":
                    return "\n".join(text_blocks)

                if resp.stop_reason == "tool_use" and tool_use_blocks:
                    # Extend the conversation and loop
                    messages.append({"role": "assistant", "content": resp.content})
                    tool_results = [
                        {
                            "type": "tool_result",
                            "tool_use_id": b.id,
                            "content": "",   # Anthropic web-search results are server-side
                        }
                        for b in tool_use_blocks
                    ]
                    messages.append({"role": "user", "content": tool_results})
                    continue

                # Any other stop reason — return whatever text we have
                return "\n".join(text_blocks)

        except Exception as exc:
            if attempt < max_retries:
                print(f"  ⚠  {name} failed (attempt {attempt + 1}), retrying… ({exc})")
                await asyncio.sleep(3)
            else:
                raise RuntimeError(f"{name} failed after {max_retries + 1} attempts: {exc}") from exc

    return ""  # unreachable, but satisfies type checkers


# ---------------------------------------------------------------------------
# Agent system-prompts and user messages
# ---------------------------------------------------------------------------

AGENT1_SYSTEM = (
    "You are a YouTube trend researcher. Search for recent YouTube videos (last 90 days) "
    "about AI business ideas, AI side hustles, AI agency models, AI SaaS, and AI automation "
    "businesses. Find 8-12 specific business ideas being discussed by creators with 10K+ "
    "subscribers. For each idea extract: idea_name, description (2-3 sentences), "
    "source_channel, estimated_startup_cost, revenue_potential, and signal_strength "
    "(high/medium/low based on how many creators discuss it). Exclude generic advice like "
    "'start a YouTube channel.' Output valid JSON array only, no markdown fences."
)

AGENT1_USER = (
    "Find AI business ideas trending on YouTube right now that a 1-2 person team could "
    "realistically launch with under $5K. Focus on ideas with proof of concept or revenue claims."
)

AGENT2_SYSTEM = (
    "You are a social media trend analyst. Search Reddit (r/SaaS, r/EntrepreneurRideAlong, "
    "r/SideProject, r/artificial), X/Twitter, LinkedIn, and IndieHackers for AI business ideas "
    "from the last 90 days. Find 8-12 ideas real builders are shipping or discussing. For each "
    "idea extract: idea_name, description (2-3 sentences), source_platform, community_sentiment "
    "(positive/skeptical/mixed), revenue_proof (true/false), competitive_density "
    "(low/medium/high), and target_customer. Flag ideas where builders share actual MRR numbers. "
    "Output valid JSON array only, no markdown fences."
)

AGENT2_USER = (
    "Find AI business ideas trending on social media and builder communities that a 1-2 person "
    "team could launch with under $5K. Prioritize ideas with revenue proof or strong community "
    "validation."
)

AGENT3_SYSTEM = (
    "You are a creative strategist and first-principles business thinker. Generate 8-12 ORIGINAL "
    "AI business ideas that are NOT commonly discussed online. Use these frameworks: "
    "(1) PAIN POINT INVERSION - tasks small businesses hate that AI can handle end-to-end, "
    "(2) API ARBITRAGE - combine 2-3 AI APIs into a product worth more than the API costs, "
    "(3) ANALOG-TO-AI - traditional services ripe for AI-first reinvention, "
    "(4) PICKS-AND-SHOVELS - tools other AI businesses need. "
    "Each idea must have a clear revenue model, be buildable by 1-2 people, and have startup "
    "costs under $5K. Include at least 3 B2B ideas, 2 B2C, and 1 marketplace. "
    "For each: idea_name, description (2-3 sentences), framework_used, revenue_model, "
    "target_customer, moat_description, build_complexity (low/medium/high). "
    "Output valid JSON array only, no markdown fences."
)

AGENT3_USER = (
    "Generate original AI business ideas for solo founders. Think creatively — avoid saturated "
    "categories like generic chatbots, basic content generation, or simple image generation."
)

AGENT4_SYSTEM = (
    "You are a quantitative business analyst. You will receive AI business ideas from 3 research "
    "agents. Deduplicate overlapping ideas (merge them and note multiple sources — this increases "
    "signal strength). Score each unique idea on 5 dimensions (1-10 scale): "
    "(a) EFFORT_TO_LAUNCH (10=very easy, 1=very hard), "
    "(b) SCALING_POTENTIAL (10=near-zero marginal cost, 1=purely linear), "
    "(c) MARKET_DEMAND (10=proven urgent demand, 1=speculative), "
    "(d) COMPETITIVE_MOAT (10=strong defensibility, 1=easily copied), "
    "(e) SOLO_FOUNDER_FIT (10=perfect for 1-2 people, 1=needs a team). "
    "Calculate composite_score = weighted average with 1.5x multiplier on scaling and "
    "solo_founder_fit. Rank by composite_score descending. Output valid JSON array with: "
    "rank, idea_name, description, sources (array of 'youtube'/'social'/'creative'), all 5 "
    "scores, composite_score (1 decimal), verdict (1 sentence). No markdown fences."
)

AGENT5_SYSTEM = (
    "You are an executive report writer. Transform a scored list of AI business ideas into a "
    "polished 1-page Markdown report for busy founders. Structure: "
    "(1) HEADER with title, date, audience. "
    "(2) TOP 3 PICKS (40% of page) - paragraph each with what it is, why now, startup cost, "
    "revenue potential, and #1 action step to start this week. "
    "(3) HONORABLE MENTIONS (25%) - markdown table: Idea | ROI Score | Effort | Scaling | One-liner. "
    "(4) KEY TRENDS (20%) - 3-4 bullets on macro patterns. "
    "(5) METHODOLOGY (15%) - brief sources and scoring note. "
    "Direct confident tone, no fluff. Bold idea names and key numbers. "
    "Flag multi-source ideas as HIGH-CONVICTION."
)


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------

async def main() -> None:
    t_start = time.time()
    today = date.today().isoformat()

    print("=" * 60)
    print("  AI Business Ideas Research Team")
    print(f"  {today}")
    print("=" * 60)
    print()

    # ── Phase 1: run agents 1-3 in parallel ──────────────────────────────
    print("Phase 1 — Running Agents 1, 2, 3 in parallel…")
    raw1, raw2, raw3 = await asyncio.gather(
        run_agent("Agent 1 (YouTube)",  AGENT1_SYSTEM, AGENT1_USER,  use_web_search=True),
        run_agent("Agent 2 (Social)",   AGENT2_SYSTEM, AGENT2_USER,  use_web_search=True),
        run_agent("Agent 3 (Creative)", AGENT3_SYSTEM, AGENT3_USER,  use_web_search=False),
    )

    a1 = safe_json(raw1, "Agent 1 (YouTube)")
    a2 = safe_json(raw2, "Agent 2 (Social)")
    a3 = safe_json(raw3, "Agent 3 (Creative)")

    print(f"  ✓ Agent 1 complete: found {idea_count(a1)} ideas")
    print(f"  ✓ Agent 2 complete: found {idea_count(a2)} ideas")
    print(f"  ✓ Agent 3 complete: found {idea_count(a3)} ideas")
    print()

    # ── Phase 2: Agent 4 scores and deduplicates ─────────────────────────
    print("Phase 2 — Agent 4 scoring and deduplicating…")

    def to_json_str(data) -> str:
        return json.dumps(data, indent=2) if isinstance(data, (list, dict)) else str(data)

    a4_user = (
        f"## YouTube Ideas:\n{to_json_str(a1)}\n\n"
        f"## Social Media Ideas:\n{to_json_str(a2)}\n\n"
        f"## Creative Ideas:\n{to_json_str(a3)}\n\n"
        "Deduplicate, score, and rank all ideas."
    )

    raw4 = await run_agent("Agent 4 (Scorer)", AGENT4_SYSTEM, a4_user, use_web_search=False)
    scored = safe_json(raw4, "Agent 4 (Scorer)")
    print(f"  ✓ Agent 4 complete: scored {idea_count(scored)} unique ideas")

    # Save raw scored data
    scored_path = "/Users/mikeschwimmer/MobileAppsBusiness/apps/biride-buddy/scored_ideas.json"
    with open(scored_path, "w") as f:
        json.dump(scored if isinstance(scored, (list, dict)) else {"raw": scored}, f, indent=2)
    print(f"  Saved → scored_ideas.json")
    print()

    # ── Phase 3: Agent 5 writes the report ───────────────────────────────
    print("Phase 3 — Agent 5 writing the report…")

    a5_user = (
        f"{to_json_str(scored)}\n\n"
        "Create the 1-page executive summary report from these scored ideas."
    )

    report = await run_agent("Agent 5 (Reporter)", AGENT5_SYSTEM, a5_user, use_web_search=False)
    print("  ✓ Agent 5 complete")

    # Save report
    report_path = "/Users/mikeschwimmer/MobileAppsBusiness/apps/biride-buddy/ai_business_report.md"
    with open(report_path, "w") as f:
        f.write(report)
    print(f"  Saved → ai_business_report.md")
    print()

    elapsed = time.time() - t_start
    print("=" * 60)
    print(f"  Total execution time: {elapsed:.1f}s")
    print("=" * 60)
    print()
    print(report)


if __name__ == "__main__":
    asyncio.run(main())
