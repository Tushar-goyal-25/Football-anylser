"use client";

import { Authenticated, Unauthenticated, useQuery } from "convex/react";
import { api } from "../convex/_generated/api";
import { SignInButton, UserButton } from "@clerk/nextjs";
import { MatchCard } from "../components/MatchCard";
import { MatchStats } from "../components/MatchStats";

export default function Home() {
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
            <UserButton afterSignOutUrl="/" />
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

function LiveMatches() {
  const liveMatches = useQuery(api.matches.getLiveMatches);
  const recentMatches = useQuery(api.matches.getAllMatches);

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

  const hasLive = liveMatches.length > 0;
  const hasRecent = recentMatches.length > 0;

  if (!hasLive && !hasRecent) {
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
      {/* Live Matches Section */}
      {hasLive && (
        <section>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white mb-6">
            🔴 Live Matches
          </h2>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {liveMatches.map((match) => (
              <MatchCard key={match._id} match={match} />
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
            {recentMatches.slice(0, 12).map((match) => (
              <MatchCard key={match._id} match={match} />
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
