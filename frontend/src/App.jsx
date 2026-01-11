import { useEffect, useState } from "react";

export default function App() {
  const [tasks, setTasks] = useState([]);
  const [err, setErr] = useState("");

  useEffect(() => {
    fetch("/task")
      .then((r) => r.json())
      .then(setTasks)
      .catch((e) => setErr(String(e)));
  }, []);

  return (
      <div style={{ padding: "24px", paddingTop: "8px", fontFamily: "Arial" }}>

      <h1>Sal's To-Do List (React + Vite)</h1>

      {err && <p style={{ color: "red" }}>{err}</p>}

      <h2>Tasks</h2>
      <ul>
        {tasks.map((t) => (
          <li key={t.id}>
            <strong>{t.title}</strong> — {t.status} — {t.priority}
          </li>
        ))}
      </ul>
    </div>
  );
}
