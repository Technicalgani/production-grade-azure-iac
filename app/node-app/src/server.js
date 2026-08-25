const express = require("express");

const app = express();

const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.json({
    message: "Hello from Node.js running on Azure AKS!",
    version: "1.0.0",
    environment: process.env.NODE_ENV || "production"
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy"
  });
});

app.get("/ready", (req, res) => {
  res.status(200).json({
    status: "ready"
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Node.js application listening on port ${PORT}`);
});