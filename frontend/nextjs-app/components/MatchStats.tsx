"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

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
      <Card>
        <CardHeader>
          <CardTitle>Goals per Match</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="home" fill="#22c55e" name="Home" />
              <Bar dataKey="away" fill="#3b82f6" name="Away" />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Live Statistics</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
            <span className="text-muted-foreground">Total Live Matches</span>
            <span className="text-2xl font-bold">{matches.length}</span>
          </div>
          <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
            <span className="text-muted-foreground">Total Goals</span>
            <span className="text-2xl font-bold">{totalGoals}</span>
          </div>
          <div className="flex items-center justify-between p-4 bg-slate-50 dark:bg-slate-800 rounded-lg">
            <span className="text-muted-foreground">Avg Goals/Match</span>
            <span className="text-2xl font-bold">
              {matches.length > 0 ? (totalGoals / matches.length).toFixed(1) : 0}
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
