import express from "express";
import cors from "cors";
import helmet from "helmet";
import Stripe from "stripe";
import pg from "pg";
import "dotenv/config";

const app = express();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "");
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGIN,
  credentials: true,
}));

app.post("/webhooks/stripe", express.raw({ type: "application/json" }), (req, res) => {
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, req.headers["stripe-signature"], process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  res.json({ received: true });
});

app.use(express.json({ limit: "1mb" }));

app.get("/healthz", async (_req, res) => {
  try {
    await pool.query("select 1");
    res.json({ ok: true, db: "up", ts: new Date().toISOString() });
  } catch {
    res.status(503).json({ ok: false, db: "down" });
  }
});

app.get("/api/finds", async (req, res) => {
  res.json({ message: "wire me to the finds table" });
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`Reclaim API listening on :${port}`));
