import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const pubspecPath = resolve(__dirname, '..', 'app', 'pubspec.yaml');
const newVersion = process.argv[2];

if (!newVersion) {
  console.error('Usage: node bump-pubspec.mjs <version>');
  process.exit(1);
}

const content = readFileSync(pubspecPath, 'utf8');
const match = content.match(/^version:\s*[\d.]+\+(\d+)/m);

if (!match) {
  console.error('Could not find version line in pubspec.yaml');
  process.exit(1);
}

const oldBuildNumber = parseInt(match[1], 10);
const newBuildNumber = oldBuildNumber + 1;
const updated = content.replace(
  /^version:\s*[\d.]+\+\d+/m,
  `version: ${newVersion}+${newBuildNumber}`
);

writeFileSync(pubspecPath, updated);
console.log(`pubspec.yaml: ${match[0]} → version: ${newVersion}+${newBuildNumber}`);
