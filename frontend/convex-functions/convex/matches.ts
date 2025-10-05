import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

/**
 * Get all live matches
 */
export const getLiveMatches = query({
  handler: async (ctx) => {
    const matches = await ctx.db
      .query("matches")
      .withIndex("by_is_live", (q) => q.eq("is_live", true))
      .order("desc")
      .take(20);

    return matches;
  },
});

/**
 * Get all matches (live and recent)
 */
export const getAllMatches = query({
  handler: async (ctx) => {
    const matches = await ctx.db
      .query("matches")
      .order("desc")
      .take(50);

    return matches;
  },
});

/**
 * Get match by match_id
 */
export const getMatchById = query({
  args: { matchId: v.string() },
  handler: async (ctx, args) => {
    const match = await ctx.db
      .query("matches")
      .withIndex("by_match_id", (q) => q.eq("match_id", args.matchId))
      .first();

    return match;
  },
});

/**
 * Upsert match data (called by backend consumer or webhook)
 */
export const upsertMatch = mutation({
  args: {
    match_id: v.string(),
    competition: v.string(),
    matchday: v.optional(v.number()),
    home_team: v.object({
      id: v.string(),
      name: v.string(),
      short_name: v.string(),
      tla: v.string(),
    }),
    away_team: v.object({
      id: v.string(),
      name: v.string(),
      short_name: v.string(),
      tla: v.string(),
    }),
    score: v.object({
      home: v.number(),
      away: v.number(),
      half_time_home: v.number(),
      half_time_away: v.number(),
    }),
    kpis: v.optional(v.object({
      total_goals: v.number(),
      goal_difference: v.number(),
      second_half_goals: v.number(),
      is_draw: v.boolean(),
      leading_team: v.string(),
    })),
    status: v.string(),
    is_live: v.boolean(),
    utc_date: v.optional(v.string()),
    event_timestamp: v.optional(v.string()),
    processed_timestamp: v.string(),
    event_type: v.string(),
  },
  handler: async (ctx, args) => {
    // Check if match exists
    const existing = await ctx.db
      .query("matches")
      .withIndex("by_match_id", (q) => q.eq("match_id", args.match_id))
      .first();

    if (existing) {
      // Update existing match
      await ctx.db.patch(existing._id, args);
      return existing._id;
    } else {
      // Insert new match
      const matchId = await ctx.db.insert("matches", args);
      return matchId;
    }
  },
});

/**
 * Delete old matches (cleanup function)
 */
export const deleteOldMatches = mutation({
  args: { olderThanDays: v.number() },
  handler: async (ctx, args) => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - args.olderThanDays);
    const cutoffISO = cutoffDate.toISOString();

    const oldMatches = await ctx.db
      .query("matches")
      .filter((q) => q.lt(q.field("processed_timestamp"), cutoffISO))
      .collect();

    for (const match of oldMatches) {
      await ctx.db.delete(match._id);
    }

    return { deleted: oldMatches.length };
  },
});
