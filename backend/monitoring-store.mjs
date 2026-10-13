import { createHash, randomBytes, randomUUID, timingSafeEqual } from 'node:crypto';
import { closeSync, existsSync, fsyncSync, lstatSync, mkdirSync, openSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';

export const MONITOR_INTERVAL_MS = 24 * 60 * 60 * 1000;
export const MONITOR_EVENT_LIMIT = 10;
export const MONITOR_RETENTION_MS = 30 * MONITOR_INTERVAL_MS;
const MAX_BYTES = 64 * 1024 * 1024;
const digest = value => createHash('sha256').update(value).digest('hex');
const fail = (status, message) => Object.assign(new Error(message), { status });
export const monitorOwner = entitlement => digest(`${entitlement.environment}:${entitlement.originalTransactionId}`);
const date = value => new Date(value).toISOString();
const validHash = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value);

// One writer/process only. Atomic protected snapshots include the daily budget;
// a process crash can consume a reserved check but can never grant another one.
export class MonitorStore {
  constructor(path, { now = Date.now, dailyLimit = 100, maxMonitors = 1000 } = {}) {
    if (!path || !Number.isInteger(dailyLimit) || dailyLimit < 1 || !Number.isInteger(maxMonitors) || maxMonitors < 1) throw new Error('Invalid monitoring storage configuration.');
    this.path = path; this.now = now; this.dailyLimit = dailyLimit; this.maxMonitors = maxMonitors;
    this.data = { version: 1, monitors: {}, owners: {}, budget: { date: '', count: 0 } };
    if (existsSync(path)) {
      const stat = lstatSync(path);
      if (!stat.isFile() || stat.size > MAX_BYTES) throw new Error('Invalid monitoring storage.');
      const saved = JSON.parse(readFileSync(path, 'utf8'));
      if (saved.version !== 1 || !saved.monitors || typeof saved.monitors !== 'object' || Array.isArray(saved.monitors) ||
          !saved.owners || typeof saved.owners !== 'object' || Array.isArray(saved.owners) ||
          typeof saved.budget?.date !== 'string' || !Number.isInteger(saved.budget?.count) || saved.budget.count < 0) throw new Error('Invalid monitoring storage.');
      for (const [id, m] of Object.entries(saved.monitors)) {
        if (m.id !== id || !/^[a-f0-9-]{36}$/.test(id) || !validHash(m.owner) || !validHash(m.tokenHash) ||
            !Number.isFinite(m.expiresAt) || !Number.isFinite(m.nextCheckAt) || typeof m.signedTransaction !== 'string' ||
            !['active', 'expired'].includes(m.state) || !m.idea || !m.founder || !Array.isArray(m.events) || m.events.length > MONITOR_EVENT_LIMIT) throw new Error('Invalid monitoring storage.');
      }
      for (const [owner, value] of Object.entries(saved.owners)) {
        if (!validHash(owner) || !Number.isFinite(value.lastAttemptAt)) throw new Error('Invalid monitoring storage.');
      }
      this.data = saved;
    }
  }
  commit(mutator) {
    const updated = structuredClone(this.data);
    const result = mutator(updated);
    const serialized = JSON.stringify(updated);
    if (Buffer.byteLength(serialized) > MAX_BYTES) throw fail(503, 'Monitoring storage is at capacity.');
    mkdirSync(dirname(this.path), { recursive: true, mode: 0o700 });
    const temporary = `${this.path}.${randomBytes(8).toString('hex')}.tmp`;
    let fd;
    try {
      fd = openSync(temporary, 'wx', 0o600);
      writeFileSync(fd, serialized); fsyncSync(fd); closeSync(fd); fd = undefined;
      renameSync(temporary, this.path);
    } catch {
      throw fail(503, 'Monitoring storage is temporarily unavailable.');
    } finally {
      if (fd !== undefined) closeSync(fd);
      rmSync(temporary, { force: true });
    }
    this.data = updated;
    return result;
  }
  enroll(body, entitlement) {
    const now = this.now(); const owner = monitorOwner(entitlement);
    const expiresAt = entitlement.expiresAt;
    if (!Number.isFinite(expiresAt) || expiresAt <= now) throw fail(403, 'A current verified Kindling Pro subscription is required.');
    const token = randomBytes(32).toString('base64url');
    const id = this.commit(data => {
      const previous = Object.values(data.monitors).find(m => m.owner === owner);
      if (previous && previous.idea.id !== body.idea.id) throw fail(409, 'This subscription already monitors another idea. Stop that monitor before choosing a different idea.');
      if (!previous && Object.keys(data.monitors).length >= this.maxMonitors) throw fail(503, 'Monitoring is at capacity.');
      for (const [key, value] of Object.entries(data.owners)) {
        if (now - value.lastAttemptAt >= MONITOR_INTERVAL_MS && !Object.values(data.monitors).some(m => m.owner === key)) delete data.owners[key];
      }
      const wasExpired = previous?.state === 'expired';
      const inputHash = digest(JSON.stringify({ idea: body.idea, founder: body.founder }));
      const record = previous ?? {
        id: randomUUID(), owner, createdAt: now, nextCheckAt: Math.max(now, (data.owners[owner]?.lastAttemptAt ?? -MONITOR_INTERVAL_MS) + MONITOR_INTERVAL_MS),
        lastCheckedAt: null, events: [], evidence: null, report: null, lastOutcome: 'scheduled', generation: 0
      };
      if (previous && previous.inputHash !== inputHash) {
        // New input requires a fresh evidence baseline, but never resets cost/due limits.
        record.evidence = null; record.report = null; record.events = []; record.generation++;
        record.lastOutcome = 'scheduled';
      }
      if (wasExpired) { record.lastOutcome = 'scheduled'; delete record.expiredAt; }
      Object.assign(record, { inputHash, tokenHash: digest(token), idea: body.idea, founder: body.founder,
        signedTransaction: body.signedTransaction, expiresAt, state: 'active' });
      data.monitors[record.id] = record;
      return record.id;
    });
    return { id, token };
  }
  authenticate(id, token) {
    const record = typeof id === 'string' ? this.data.monitors[id] : undefined;
    if (!record || typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token) ||
        !timingSafeEqual(Buffer.from(record.tokenHash, 'hex'), Buffer.from(digest(token), 'hex'))) throw fail(404, 'Monitor not found.');
    return structuredClone(record);
  }
  remove(id, token) {
    if (typeof id === 'string' && /^[a-f0-9-]{36}$/.test(id) && !this.data.monitors[id]) return;
    this.authenticate(id, token);
    this.commit(data => { delete data.monitors[id]; });
  }
  snapshot(id, { enabled = true } = {}) {
    const m = this.data.monitors[id];
    if (!m) throw fail(404, 'Monitor not found.');
    const expired = m.state === 'expired' || m.expiresAt <= this.now();
    const status = !enabled ? 'paused' : expired ? 'expired' : 'active';
    const messages = {
      scheduled: 'Daily monitoring is scheduled. The first check establishes an evidence baseline.',
      baseline: 'Evidence baseline saved. Future daily checks will report meaningful changes.',
      unchanged: 'No meaningful new evidence was found. Your assessment is unchanged.',
      updated: 'New sourced evidence changed the assessment. Review the update below.',
      unavailable: 'The last research check could not complete. Your previous assessment is unchanged.',
      capacity: 'The daily monitoring budget is full. The next check is queued.',
      expired: 'Monitoring stopped because a current subscription could not be verified.'
    };
    return {
      id: m.id, status, idea: m.idea, founder: m.founder,
      lastCheckedAt: m.lastCheckedAt === null ? null : date(m.lastCheckedAt),
      nextCheckAt: status === 'active' ? date(m.nextCheckAt) : null, expiresAt: date(m.expiresAt),
      message: !enabled ? 'Daily monitoring is temporarily paused by the service.' : expired ? messages.expired : messages[m.lastOutcome] ?? messages.scheduled,
      events: m.events, ...(m.report ? { report: m.report } : {})
    };
  }
  maintenance(enabled) {
    const now = this.now();
    const updated = structuredClone(this.data);
    for (const [id, record] of Object.entries(updated.monitors)) {
      if (!enabled && !Number.isFinite(record.pausedAt)) record.pausedAt = now;
      if (Math.min(record.pausedAt ?? Infinity, record.expiredAt ?? Infinity, record.expiresAt) + MONITOR_RETENTION_MS <= now) {
        delete updated.monitors[id];
        continue;
      }
      if (enabled) delete record.pausedAt;
    }
    for (const [owner, value] of Object.entries(updated.owners)) {
      if (now - value.lastAttemptAt >= MONITOR_INTERVAL_MS && !Object.values(updated.monitors).some(m => m.owner === owner)) delete updated.owners[owner];
    }
    if (JSON.stringify(updated) !== JSON.stringify(this.data)) this.commit(data => Object.assign(data, updated));
  }
  isCurrent(job) {
    const record = this.data.monitors[job.id];
    return Boolean(record && record.state === 'active' && record.generation === job.generation && record.inputHash === job.inputHash);
  }
  due() {
    const now = this.now();
    return Object.values(this.data.monitors).filter(m => m.state === 'active' && m.nextCheckAt <= now)
      .sort((a, b) => a.nextCheckAt - b.nextCheckAt).map(m => m.id);
  }
  reserve(id) {
    const now = this.now();
    return this.commit(data => {
      const m = data.monitors[id];
      if (!m || m.state !== 'active' || m.nextCheckAt > now) return null;
      const ownerDue = (data.owners[m.owner]?.lastAttemptAt ?? -MONITOR_INTERVAL_MS) + MONITOR_INTERVAL_MS;
      if (ownerDue > now) { m.nextCheckAt = ownerDue; return null; }
      const today = date(now).slice(0, 10);
      if (data.budget.date !== today) data.budget = { date: today, count: 0 };
      if (data.budget.count >= this.dailyLimit) {
        m.lastOutcome = 'capacity';
        m.nextCheckAt = Date.parse(`${today}T00:00:00Z`) + MONITOR_INTERVAL_MS;
        return null;
      }
      data.budget.count++;
      data.owners[m.owner] = { lastAttemptAt: now };
      m.nextCheckAt = now + MONITOR_INTERVAL_MS;
      // The reservation is durable before verification or paid provider calls.
      return structuredClone(m);
    });
  }
  complete(job, { outcome, evidence, report, event, entitlement } = {}) {
    this.commit(data => {
      const m = data.monitors[job.id];
      // Deleting/re-enrolling or editing inputs while a check runs must not resurrect
      // old data or apply an analysis to new inputs. Token renewal alone is harmless.
      if (!m || m.owner !== job.owner || m.generation !== job.generation || m.inputHash !== job.inputHash) return;
      m.lastCheckedAt = this.now(); m.lastOutcome = outcome;
      if (entitlement) m.expiresAt = entitlement.expiresAt;
      if (outcome === 'expired') { m.state = 'expired'; m.expiredAt = this.now(); m.signedTransaction = ''; }
      if (evidence) m.evidence = evidence;
      if (report) m.report = report;
      if (event) m.events = [event, ...m.events].slice(0, MONITOR_EVENT_LIMIT);
    });
  }
}
