#!/usr/bin/env node
/**
 * Runs the ArogyaMitra domain verification suite against the local Supabase
 * database and summarises the result.
 *
 * The suite wraps everything in a transaction and rolls back, so it is safe to
 * run repeatedly without resetting the database.
 *
 * Usage: npm run db:verify
 */
import { execFileSync, execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';

const SQL_FILE = path.join('supabase', 'tests', 'domain_checks.sql');
const REMOTE_PATH = '/tmp/arogyamitra_domain_checks.sql';

if (!existsSync(SQL_FILE)) {
  console.error(`Cannot find ${SQL_FILE}`);
  process.exit(1);
}

/** Locates the running local Supabase database container. */
function findDbContainer() {
  const names = execSync('docker ps --format "{{.Names}}"', { encoding: 'utf8' })
    .split('\n')
    .map((n) => n.trim())
    .filter(Boolean);

  const match = names.find((n) => n.startsWith('supabase_db_'));
  if (!match) {
    console.error(
      'No running supabase_db_* container found. Start the stack with: npm run db:start',
    );
    process.exit(1);
  }
  return match;
}

const container = findDbContainer();

execFileSync('docker', ['cp', SQL_FILE, `${container}:${REMOTE_PATH}`], {
  stdio: 'inherit',
});

// psql reports assertion results as NOTICE on stderr, so stderr is folded into
// stdout inside the container rather than being discarded.
const psqlCommand =
  `psql -U postgres -d postgres -v ON_ERROR_STOP=1 -q -f ${REMOTE_PATH} 2>&1`;

let output = '';
let exitCode = 0;
try {
  output = execFileSync(
    'docker',
    ['exec', container, 'sh', '-c', psqlCommand],
    { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'] },
  );
} catch (error) {
  output = `${error.stdout ?? ''}${error.stderr ?? ''}`;
  exitCode = 1;
}

const lines = output.split('\n');
const passed = lines.filter((l) => l.includes('NOTICE:  pass')).length;
// A genuine problem is an ERROR line or an explicit FAIL assertion, not the
// word "fail" appearing inside a check description.
const problems = lines.filter(
  (l) => l.includes('ERROR:') || l.includes('FAIL:'),
);

for (const line of lines) {
  const cleaned = line.replace(/^psql:[^:]+:\d+:\s*/, '').trim();
  if (cleaned.startsWith('NOTICE:  pass')) {
    console.log(`  ok  ${cleaned.replace('NOTICE:  pass', '').trim()}`);
  } else if (cleaned.includes('ERROR:') || cleaned.includes('FAIL:')) {
    console.error(`  XX  ${cleaned}`);
  }
}

console.log('');
console.log(`${passed} checks passed, ${problems.length} failed.`);

// A run that asserted nothing is a broken harness, not a green build.
if (passed === 0) {
  console.error('No assertions ran. The verification harness is not working.');
  process.exit(1);
}

if (problems.length > 0 || exitCode !== 0) {
  process.exit(1);
}
