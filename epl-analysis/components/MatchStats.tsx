"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

interface Match {
  home_team: { name: string; tla: string };
  away_team: { name: string; tla: string };
  score: { home: number; away: number };
  kpis?: { total_goals: number };
}

export function MatchStats({ matches }: { matches: Match[] }) {
  const chartData = matches.map((match) => ({
    name: `${match.home_team.tla} vs ${match.away_team.tla}`,
    home: match.score.home,
    away: match.score.away,
    total: match.kpis?.total_goals || 0,
  }));

  const totalGoals = matches.reduce(
    (sum, match) => sum + (match.kpis?.total_goals || 0),
    0
  );

  return (
    <div className="grid gap-6 md:grid-cols-2">
      {/* Chart */}
      <div className="bg-white dark:bg-slate-800 rounded-lg shadow-md p-6 border border-slate-200 dark:border-slate-700">
        <h3 className="text-xl font-semibold text-slate-900 dark:text-white mb-4">
          Goals per Match
        </h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" className="stroke-slate-200 dark:stroke-slate-700" />
            <XAxis dataKey="name" className="text-xs fill-slate-600 dark:fill-slate-400" />
            <YAxis className="text-xs fill-slate-600 dark:fill-slate-400" />
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(15, 23, 42, 0.9)',
                border: '1px solid rgb(51, 65, 85)',
                borderRadius: '8px',
                color: '#fff'
              }}
            />
            <Bar dataKey="home" fill="#22c55e" name="Home" />
            <Bar dataKey="away" fill="#3b82f6" name="Away" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Live Statistics */}
      <div className="bg-white dark:bg-slate-800 rounded-lg shadow-md p-6 border border-slate-200 dark:border-slate-700">
        <h3 className="text-xl font-semibold text-slate-900 dark:text-white mb-4">
          Live Statistics
        </h3>
        <div className="space-y-4">
          <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
            <span className="text-slate-600 dark:text-slate-400">
              Total Live Matches
            </span>
            <span className="text-3xl font-bold text-slate-900 dark:text-white">
              {matches.length}
            </span>
          </div>
          <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
            <span className="text-slate-600 dark:text-slate-400">
              Total Goals
            </span>
            <span className="text-3xl font-bold text-primary">
              {totalGoals}
            </span>
          </div>
          <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-700/50 rounded-lg">
            <span className="text-slate-600 dark:text-slate-400">
              Avg Goals/Match
            </span>
            <span className="text-3xl font-bold text-slate-900 dark:text-white">
              {matches.length > 0 ? (totalGoals / matches.length).toFixed(1) : 0}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
