"use client";

import { useCallback, useEffect, useState } from "react";

type Job = {
  id: string;
  task: string;
  status: string;
  result: string | null;
  created_at: string;
};

export default function Home() {
  const [task, setTask] = useState("");
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const loadJobs = useCallback(async () => {
    try {
      const response = await fetch("/api/jobs", { cache: "no-store" });
      if (!response.ok) throw new Error("Unable to load jobs");
      const data = await response.json();
      setJobs(data);
      setError("");
    } catch {
      setError("Cannot connect to the backend. Please try again.");
    }
  }, []);

  useEffect(() => {
    loadJobs();
    const interval = setInterval(loadJobs, 3000);
    return () => clearInterval(interval);
  }, [loadJobs]);

  async function submitJob(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!task.trim()) return;

    setLoading(true);
    setError("");

    try {
      const response = await fetch("/api/jobs", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ task: task.trim() }),
      });

      if (!response.ok) {
        throw new Error("Job submission failed");
      }

      setTask("");
      await loadJobs();
    } catch {
      setError("Unable to submit the job. Check the backend and try again.");
    } finally {
      setLoading(false);
    }
  }

  const statusColor = (status: string) => {
    switch (status) {
      case "COMPLETED": return "#15803d";
      case "FAILED": return "#dc2626";
      case "PROCESSING": return "#b45309";
      default: return "#475569";
    }
  };

  return (
    <main style={{
      minHeight: "100vh",
      background: "#f1f5f9",
      color: "#0f172a",
      padding: "40px 20px",
      fontFamily: "Arial, sans-serif"
    }}>
      <div style={{ maxWidth: 900, margin: "auto" }}>
        <header style={{ marginBottom: 32 }}>
          <h1 style={{ fontSize: 32, fontWeight: 800 }}>VEGAH Job Manager</h1>
          <p style={{ color: "#475569", marginTop: 8 }}>
            Submit tasks and monitor asynchronous background processing.
          </p>
        </header>

        <section style={{
          background: "white",
          padding: 24,
          borderRadius: 12,
          marginBottom: 24
        }}>
          <h2 style={{ fontSize: 20, fontWeight: 700, marginBottom: 16 }}>
            Submit a new job
          </h2>

          <form onSubmit={submitJob} style={{ display: "flex", gap: 12 }}>
            <input
              value={task}
              onChange={(event) => setTask(event.target.value)}
              placeholder="Enter a task to process..."
              maxLength={500}
              required
              style={{
                flex: 1,
                minWidth: 0,
                padding: 14,
                border: "1px solid #cbd5e1",
                borderRadius: 8,
                fontSize: 15
              }}
            />
            <button
              type="submit"
              disabled={loading}
              style={{
                padding: "12px 20px",
                background: loading ? "#64748b" : "#2563eb",
                color: "white",
                border: 0,
                borderRadius: 8,
                fontWeight: 700,
                cursor: loading ? "not-allowed" : "pointer"
              }}
            >
              {loading ? "Submitting..." : "Submit Job"}
            </button>
          </form>
        </section>

        {error && (
          <p role="alert" style={{ color: "#dc2626", marginBottom: 16 }}>
            {error}
          </p>
        )}

        <section style={{
          background: "white",
          padding: 24,
          borderRadius: 12
        }}>
          <div style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 18
          }}>
            <h2 style={{ fontSize: 20, fontWeight: 700 }}>Recent Jobs</h2>
            <button
              onClick={loadJobs}
              style={{
                padding: "8px 14px",
                border: "1px solid #cbd5e1",
                borderRadius: 8,
                background: "white",
                cursor: "pointer"
              }}
            >
              Refresh
            </button>
          </div>

          {jobs.length === 0 ? (
            <p style={{ color: "#64748b" }}>No jobs submitted yet.</p>
          ) : (
            <div style={{ display: "grid", gap: 14 }}>
              {jobs.map((job) => (
                <article key={job.id} style={{
                  border: "1px solid #e2e8f0",
                  borderRadius: 8,
                  padding: 16
                }}>
                  <div style={{
                    display: "flex",
                    justifyContent: "space-between",
                    gap: 12,
                    flexWrap: "wrap"
                  }}>
                    <strong>{job.task}</strong>
                    <span style={{
                      color: statusColor(job.status),
                      fontWeight: 700,
                      fontSize: 13
                    }}>
                      {job.status}
                    </span>
                  </div>

                  <p style={{
                    color: "#64748b",
                    fontSize: 12,
                    marginTop: 10,
                    wordBreak: "break-all"
                  }}>
                    Job ID: {job.id}
                  </p>

                  {job.result && (
                    <p style={{
                      marginTop: 10,
                      color: "#15803d",
                      fontSize: 14
                    }}>
                      Result: {job.result}
                    </p>
                  )}
                </article>
              ))}
            </div>
          )}
        </section>

        <footer style={{
          marginTop: 24,
          textAlign: "center",
          color: "#64748b",
          fontSize: 13
        }}>
          VEGAH DevOps Assessment · Next.js · NestJS · Redis · PostgreSQL
        </footer>
      </div>
    </main>
  );
}
