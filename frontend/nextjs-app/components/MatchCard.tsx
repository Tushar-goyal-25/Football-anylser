import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface Match {
  _id: string;
  match_id: string;
  home_team: {
    name: string;
    tla: string;
  };
  away_team: {
    name: string;
    tla: string;
  };
  score: {
    home: number;
    away: number;
  };
  status: string;
  is_live: boolean;
  kpis?: {
    total_goals: number;
    leading_team: string;
  };
}

export function MatchCard({ match }: { match: Match }) {
  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <Badge variant={match.is_live ? "default" : "secondary"}>
            {match.is_live ? "🔴 LIVE" : match.status}
          </Badge>
          <span className="text-sm text-muted-foreground">EPL</span>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Home Team */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center text-xs font-semibold">
              {match.home_team.tla}
            </div>
            <span className="font-semibold text-slate-900 dark:text-white">
              {match.home_team.name}
            </span>
          </div>
          <span className="text-2xl font-bold text-slate-900 dark:text-white">
            {match.score.home}
          </span>
        </div>

        {/* Away Team */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center text-xs font-semibold">
              {match.away_team.tla}
            </div>
            <span className="font-semibold text-slate-900 dark:text-white">
              {match.away_team.name}
            </span>
          </div>
          <span className="text-2xl font-bold text-slate-900 dark:text-white">
            {match.score.away}
          </span>
        </div>

        {/* Stats */}
        {match.kpis && (
          <div className="pt-3 border-t flex items-center justify-between text-sm text-muted-foreground">
            <span>Total Goals: {match.kpis.total_goals}</span>
            {match.kpis.leading_team !== "draw" && (
              <Badge variant="outline" className="text-xs">
                {match.kpis.leading_team === "home"
                  ? match.home_team.tla
                  : match.away_team.tla}{" "}
                leading
              </Badge>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
