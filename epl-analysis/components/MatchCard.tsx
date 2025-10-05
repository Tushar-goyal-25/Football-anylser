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
    <div className="bg-white dark:bg-slate-800 rounded-lg shadow-md hover:shadow-lg transition-shadow p-6 border border-slate-200 dark:border-slate-700">
      {/* Status Badge */}
      <div className="flex items-center justify-between mb-4">
        <span
          className={`px-3 py-1 rounded-full text-xs font-semibold ${
            match.is_live
              ? "bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300"
              : "bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-300"
          }`}
        >
          {match.is_live ? "🔴 LIVE" : match.status}
        </span>
        <span className="text-sm text-slate-500 dark:text-slate-400">EPL</span>
      </div>

      {/* Home Team */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-slate-100 dark:bg-slate-700 rounded-full flex items-center justify-center text-sm font-bold">
            {match.home_team.tla}
          </div>
          <span className="font-semibold text-slate-900 dark:text-white">
            {match.home_team.name}
          </span>
        </div>
        <span className="text-3xl font-bold text-slate-900 dark:text-white">
          {match.score.home}
        </span>
      </div>

      {/* Away Team */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-slate-100 dark:bg-slate-700 rounded-full flex items-center justify-center text-sm font-bold">
            {match.away_team.tla}
          </div>
          <span className="font-semibold text-slate-900 dark:text-white">
            {match.away_team.name}
          </span>
        </div>
        <span className="text-3xl font-bold text-slate-900 dark:text-white">
          {match.score.away}
        </span>
      </div>

      {/* Stats */}
      {match.kpis && (
        <div className="pt-4 border-t border-slate-200 dark:border-slate-700 flex items-center justify-between text-sm text-slate-600 dark:text-slate-400">
          <span>Total Goals: {match.kpis.total_goals}</span>
          {match.kpis.leading_team !== "draw" && (
            <span className="px-2 py-1 bg-primary/10 text-primary rounded text-xs font-medium">
              {match.kpis.leading_team === "home"
                ? match.home_team.tla
                : match.away_team.tla}{" "}
              leading
            </span>
          )}
        </div>
      )}
    </div>
  );
}
