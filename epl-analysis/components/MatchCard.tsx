import { Star } from "lucide-react";

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
  utc_date?: string;
  kpis?: {
    total_goals: number;
    leading_team: string;
  };
}

export function MatchCard({
  match,
  favoriteTeams,
  onToggleFavorite,
}: {
  match: Match;
  favoriteTeams?: string[];
  onToggleFavorite?: (teamName: string) => void;
}) {
  const isHomeFavorite = favoriteTeams?.includes(match.home_team.name) || false;
  const isAwayFavorite = favoriteTeams?.includes(match.away_team.name) || false;
  const formatDate = (utcDate?: string) => {
    if (!utcDate) return "";
    const date = new Date(utcDate);
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  };

  const formatTime = (utcDate?: string) => {
    if (!utcDate) return "";
    const date = new Date(utcDate);
    return date.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

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

      {/* Match Date and Time */}
      {match.utc_date && (
        <div className="mb-3 text-center">
          <div className="text-sm font-medium text-slate-900 dark:text-white">
            {formatDate(match.utc_date)}
          </div>
          <div className="text-xs text-slate-500 dark:text-slate-400">
            {formatTime(match.utc_date)}
          </div>
        </div>
      )}

      {/* Home Team */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3 flex-1">
          <div className="w-10 h-10 bg-slate-100 dark:bg-slate-700 rounded-full flex items-center justify-center text-sm font-bold">
            {match.home_team.tla}
          </div>
          <span className="font-semibold text-slate-900 dark:text-white">
            {match.home_team.name}
          </span>
          {onToggleFavorite && (
            <button
              onClick={(e) => {
                e.stopPropagation();
                onToggleFavorite(match.home_team.name);
              }}
              className="ml-2 hover:scale-110 transition"
              title={isHomeFavorite ? "Remove from favorites" : "Add to favorites"}
            >
              <Star
                size={18}
                className={
                  isHomeFavorite
                    ? "fill-yellow-400 text-yellow-400"
                    : "text-slate-400 hover:text-yellow-400"
                }
              />
            </button>
          )}
        </div>
        <span className="text-3xl font-bold text-slate-900 dark:text-white">
          {match.score.home}
        </span>
      </div>

      {/* Away Team */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3 flex-1">
          <div className="w-10 h-10 bg-slate-100 dark:bg-slate-700 rounded-full flex items-center justify-center text-sm font-bold">
            {match.away_team.tla}
          </div>
          <span className="font-semibold text-slate-900 dark:text-white">
            {match.away_team.name}
          </span>
          {onToggleFavorite && (
            <button
              onClick={(e) => {
                e.stopPropagation();
                onToggleFavorite(match.away_team.name);
              }}
              className="ml-2 hover:scale-110 transition"
              title={isAwayFavorite ? "Remove from favorites" : "Add to favorites"}
            >
              <Star
                size={18}
                className={
                  isAwayFavorite
                    ? "fill-yellow-400 text-yellow-400"
                    : "text-slate-400 hover:text-yellow-400"
                }
              />
            </button>
          )}
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
