const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();

app.get("/task", (req, res) => {
  try {
    const filePath = path.join(__dirname, "task.json");
    const raw = fs.readFileSync(filePath, "utf-8");
    const task = JSON.parse(raw);
    res.json(task);
  } catch (err) {
    res.status(500).json({ error: "Failed to load task.json", details: String(err) });
  }
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Backend listening on http://0.0.0.0:3000");
});
