import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  matches: defineTable({
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
  })
    .index("by_match_id", ["match_id"])
    .index("by_status", ["status"])
    .index("by_is_live", ["is_live"]),
});
