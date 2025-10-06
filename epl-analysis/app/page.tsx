"use client";

import { Authenticated, Unauthenticated, useQuery } from "convex/react";
import { api } from "../convex/_generated/api";
import { SignInButton, UserButton } from "@clerk/nextjs";
import { MatchCard } from "../components/MatchCard";
import { MatchStats } from "../components/MatchStats";
import { useState, useEffect } from "react";
import { Sun, Moon, Search, Star } from "lucide-react";

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

export default function Home() {
  const [isDarkMode, setIsDarkMode] = useState(false);

  // Apply dark mode class to document
  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }, [isDarkMode]);

  // Check system preference on mount
  useEffect(() => {
    const darkModeQuery = window.matchMedia("(prefers-color-scheme: dark)");
    setIsDarkMode(darkModeQuery.matches);
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      {/* Header */}
      <header className="sticky top-0 z-10 border-b bg-white/50 dark:bg-slate-900/50 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 bg-primary rounded-lg flex items-center justify-center">
              <span className="text-2xl">⚽</span>
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                Live EPL
              </h1>
              <p className="text-sm text-slate-600 dark:text-slate-400">
                Real-time Premier League Stats
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            {/* Dark Mode Toggle */}
            <button
              onClick={() => setIsDarkMode(!isDarkMode)}
              className="p-2 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-white hover:bg-slate-200 dark:hover:bg-slate-700 transition"
              title={isDarkMode ? "Switch to light mode" : "Switch to dark mode"}
            >
              {isDarkMode ? <Sun size={20} /> : <Moon size={20} />}
            </button>
            <UserButton />
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <Unauthenticated>
          <SignInPrompt />
        </Unauthenticated>
        <Authenticated>
          <LiveMatches />
        </Authenticated>
      </main>

      {/* Footer */}
      <footer className="border-t bg-white/50 dark:bg-slate-900/50 backdrop-blur-sm mt-20">
        <div className="container mx-auto px-4 py-6 text-center text-sm text-slate-600 dark:text-slate-400">
          <p>Live EPL - Real-time Premier League Data Pipeline</p>
          <p className="mt-2">
            Built with Kafka, FastAPI, Next.js, Convex & Clerk
          </p>
        </div>
      </footer>
    </div>
  );
}

function SignInPrompt() {
  return (
    <div className="text-center py-20">
      <h2 className="text-3xl font-bold text-slate-900 dark:text-white mb-4">
        Welcome to Live EPL
      </h2>
      <p className="text-lg text-slate-600 dark:text-slate-400 mb-8">
        Sign in to view live Premier League match statistics
      </p>
      <SignInButton mode="modal">
        <button className="px-6 py-3 bg-primary text-white rounded-lg hover:bg-primary/90 transition text-lg font-semibold">
          Get Started
        </button>
      </SignInButton>
    </div>
  );
}

function SearchAndFilters({
  searchQuery,
  setSearchQuery,
  showFavoritesOnly,
  setShowFavoritesOnly,
  favoriteTeams,
}: {
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  showFavoritesOnly: boolean;
  setShowFavoritesOnly: (show: boolean) => void;
  favoriteTeams: string[];
}) {
  return (
    <div className="mb-6 flex flex-col md:flex-row gap-4">
      {/* Search Bar */}
      <div className="flex-1 relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
        <input
          type="text"
          placeholder="Search teams..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-10 pr-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 dark:placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-primary"
        />
      </div>

      {/* Favorites Filter */}
      <button
        onClick={() => setShowFavoritesOnly(!showFavoritesOnly)}
        className={`px-4 py-2 rounded-lg font-medium transition flex items-center gap-2 ${
          showFavoritesOnly
            ? "bg-primary text-white"
            : "bg-white dark:bg-slate-800 text-slate-900 dark:text-white border border-slate-300 dark:border-slate-600"
        }`}
      >
        <Star size={18} className={showFavoritesOnly ? "fill-white" : ""} />
        Favorites {favoriteTeams.length > 0 && `(${favoriteTeams.length})`}
      </button>
    </div>
  );
}

function LiveMatches() {
  const liveMatches = useQuery(api.matches.getLiveMatches);
  const recentMatches = useQuery(api.matches.getAllMatches);
  const [searchQuery, setSearchQuery] = useState("");
  const [favoriteTeams, setFavoriteTeams] = useState<string[]>([]);
  const [showFavoritesOnly, setShowFavoritesOnly] = useState(false);

  if (liveMatches === undefined || recentMatches === undefined) {
    return (
      <div className="text-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-slate-600 dark:text-slate-400">
          Loading matches...
        </p>
      </div>
    );
  }

  const filterMatches = (matches: Match[]) => {
    return matches.filter((match) => {
      const homeTeam = match.home_team.name.toLowerCase();
      const awayTeam = match.away_team.name.toLowerCase();
      const query = searchQuery.toLowerCase();

      const matchesSearch =
        homeTeam.includes(query) ||
        awayTeam.includes(query) ||
        match.home_team.tla.toLowerCase().includes(query) ||
        match.away_team.tla.toLowerCase().includes(query);

      const matchesFavorites = !showFavoritesOnly ||
        favoriteTeams.includes(match.home_team.name) ||
        favoriteTeams.includes(match.away_team.name);

      return matchesSearch && matchesFavorites;
    });
  };

  const filteredLiveMatches = filterMatches(liveMatches);
  const filteredRecentMatches = filterMatches(recentMatches);

  const hasLive = filteredLiveMatches.length > 0;
  const hasRecent = filteredRecentMatches.length > 0;

  const toggleFavoriteTeam = (teamName: string) => {
    setFavoriteTeams((prev) =>
      prev.includes(teamName)
        ? prev.filter((t) => t !== teamName)
        : [...prev, teamName]
    );
  };

  if (!hasLive && !hasRecent && (searchQuery || showFavoritesOnly)) {
    return (
      <>
        <SearchAndFilters
          searchQuery={searchQuery}
          setSearchQuery={setSearchQuery}
          showFavoritesOnly={showFavoritesOnly}
          setShowFavoritesOnly={setShowFavoritesOnly}
          favoriteTeams={favoriteTeams}
        />
        <div className="text-center py-12 bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700">
          <p className="text-slate-600 dark:text-slate-400 mb-2">
            No matches found
          </p>
          <p className="text-sm text-slate-500 dark:text-slate-500">
            Try adjusting your search or filters
          </p>
        </div>
      </>
    );
  }

  if (liveMatches.length === 0 && recentMatches.length === 0) {
    return (
      <div className="text-center py-12 bg-white dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700">
        <p className="text-slate-600 dark:text-slate-400 mb-2">
          No matches available
        </p>
        <p className="text-sm text-slate-500 dark:text-slate-500">
          Make sure the Kafka pipeline is running with Docker Compose
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Search and Filters */}
      <SearchAndFilters
        searchQuery={searchQuery}
        setSearchQuery={setSearchQuery}
        showFavoritesOnly={showFavoritesOnly}
        setShowFavoritesOnly={setShowFavoritesOnly}
        favoriteTeams={favoriteTeams}
      />

      {/* Live Matches Section */}
      {hasLive && (
        <section>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-6">
            🔴 Live Matches
          </h2>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {filteredLiveMatches.map((match) => (
              <MatchCard
                key={match._id}
                match={match}
                favoriteTeams={favoriteTeams}
                onToggleFavorite={toggleFavoriteTeam}
              />
            ))}
          </div>
        </section>
      )}

      {/* Recent Matches Section */}
      {hasRecent && (
        <section>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-6">
            {hasLive ? "Recent Matches" : "Latest Matches"}
          </h2>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {filteredRecentMatches.slice(0, 12).map((match) => (
              <MatchCard
                key={match._id}
                match={match}
                favoriteTeams={favoriteTeams}
                onToggleFavorite={toggleFavoriteTeam}
              />
            ))}
          </div>
        </section>
      )}

      {/* Match Statistics */}
      {(hasLive || hasRecent) && (
        <section>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-6">
            Match Statistics
          </h2>
          <MatchStats matches={hasLive ? liveMatches : recentMatches.slice(0, 10)} />
        </section>
      )}
    </div>
  );
}
