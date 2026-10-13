import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export const FREE_AI_LIMIT = 3;
export const identityHash = (value) => createHash("sha256").update(value).digest("hex");

// Single-process durable quota. Run one instance with a persistent volume;
// replace this store with an atomic shared database before horizontal scaling.
export class FreeUsageStore {
  constructor(path) {
    this.path = path;
    this.counts = new Map();
    if (existsSync(path)) {
      const saved = JSON.parse(readFileSync(path, "utf8"));
      if (saved.version !== 1 || !Array.isArray(saved.counts)) throw new Error("Invalid quota data.");
      for (const [key, count] of saved.counts) {
        if (!/^[a-f0-9]{64}$/.test(key) || !Number.isInteger(count) || count < 0 || count > FREE_AI_LIMIT) throw new Error("Invalid quota data.");
        this.counts.set(key, count);
      }
    }
  }
  save() {
    mkdirSync(dirname(this.path), { recursive: true, mode: 0o700 });
    const temporary = `${this.path}.tmp`;
    writeFileSync(temporary, JSON.stringify({ version: 1, counts: [...this.counts] }), { mode: 0o600 });
    renameSync(temporary, this.path);
  }
  reserve(clientId) {
    const key = identityHash(clientId);
    const used = this.counts.get(key) ?? 0;
    if (used >= FREE_AI_LIMIT) throw Object.assign(new Error("Your three free AI requests have been used. Upgrade to Kindling Pro to continue."), { status: 402 });
    if (!this.counts.has(key) && this.counts.size >= 100_000) throw Object.assign(new Error("The AI service is temporarily at capacity."), { status: 503 });
    this.counts.set(key, used + 1);
    try { this.save(); } catch (error) { this.counts.set(key, used); throw error; }
    let released = false;
    return () => {
      if (released) return;
      released = true;
      this.counts.set(key, Math.max(0, (this.counts.get(key) ?? 1) - 1));
      this.save();
    };
  }
}

export class RateLimiter {
  constructor({ limit = 20, windowMs = 600_000, now = Date.now } = {}) {
    this.limit = limit;
    this.windowMs = windowMs;
    this.now = now;
    this.entries = new Map();
  }
  exceeds(key) {
    const now = this.now();
    for (const [id, entry] of this.entries) if (now - entry.start >= this.windowMs) this.entries.delete(id);
    let entry = this.entries.get(key);
    if (!entry) {
      if (this.entries.size >= 10_000) return true;
      entry = { start: now, count: 0 };
      this.entries.set(key, entry);
    }
    return ++entry.count > this.limit;
  }
}
