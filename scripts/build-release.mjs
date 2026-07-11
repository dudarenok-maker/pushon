#!/usr/bin/env node
// Builds the Play AAB with a strictly-increasing versionCode
// (minutes since epoch — same scheme as the Castwright companion).
import { execSync } from 'node:child_process';

const buildNumber = Math.floor(Date.now() / 60000);
const cmd = `flutter build appbundle --release --build-number=${buildNumber}`;
console.log(`versionCode ${buildNumber}\n> ${cmd}`);
if (!process.argv.includes('--dry-run')) {
  execSync(cmd, { stdio: 'inherit' });
  console.log('AAB at build/app/outputs/bundle/release/app-release.aab');
}
