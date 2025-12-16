#!/usr/bin/env node
/**
 * Documentation Auto-Updater for SABO Arena
 * 
 * Tự động cập nhật tài liệu dựa trên:
 * 1. Git commits & changes
 * 2. Code analysis (pubspec.yaml, lib/ structure)
 * 3. Database migrations
 * 
 * Usage:
 *   node docs-auto-updater.js --check      # Check what needs update
 *   node docs-auto-updater.js --update     # Auto-update docs
 *   node docs-auto-updater.js --changelog  # Update changelog from git
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PROJECT_ROOT = path.join(__dirname, '..');
const DOCS_ROOT = path.join(PROJECT_ROOT, '_DOCS');

class DocsAutoUpdater {
  constructor() {
    this.changes = [];
    this.stats = {
      filesChecked: 0,
      docsUpdated: 0,
      warnings: []
    };
  }

  /**
   * Get project version from pubspec.yaml
   */
  getProjectVersion() {
    try {
      const pubspec = fs.readFileSync(path.join(PROJECT_ROOT, 'pubspec.yaml'), 'utf-8');
      const match = pubspec.match(/version:\s*(\d+\.\d+\.\d+)/);
      return match ? match[1] : 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /**
   * Get recent git commits
   */
  getRecentCommits(days = 7) {
    try {
      const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      const log = execSync(
        `git log --since="${since}" --oneline --no-merges`,
        { cwd: PROJECT_ROOT, encoding: 'utf-8' }
      );
      return log.trim().split('\n').filter(l => l);
    } catch (e) {
      return [];
    }
  }

  /**
   * Get changed files since last doc update
   */
  getChangedFiles() {
    try {
      // Get files changed in last 7 days
      const result = execSync(
        'git diff --name-only HEAD~20',
        { cwd: PROJECT_ROOT, encoding: 'utf-8' }
      );
      return result.trim().split('\n').filter(f => f);
    } catch (e) {
      return [];
    }
  }

  /**
   * Analyze which docs need updating based on changed files
   */
  analyzeChanges() {
    const changedFiles = this.getChangedFiles();
    const docsToUpdate = new Set();

    for (const file of changedFiles) {
      this.stats.filesChecked++;
      
      // Tournament related
      if (file.includes('tournament') || file.includes('bracket')) {
        docsToUpdate.add('02-FEATURES/TOURNAMENTS_CONSOLIDATED.md');
      }
      
      // ELO related
      if (file.includes('elo') || file.includes('rank')) {
        docsToUpdate.add('02-FEATURES/ELO_UPDATE_FLOW.md');
        docsToUpdate.add('02-FEATURES/RANKS_CONSOLIDATED.md');
      }
      
      // Auth related
      if (file.includes('auth') || file.includes('login') || file.includes('signin')) {
        docsToUpdate.add('01-ARCHITECTURE/AUTHENTICATION_CONSOLIDATED.md');
      }
      
      // Database migrations
      if (file.includes('migration') || file.endsWith('.sql')) {
        docsToUpdate.add('08-DATABASE/DATABASE_SCHEMA.md');
        docsToUpdate.add('08-DATABASE/DATABASE_MIGRATIONS_GUIDE.md');
      }
      
      // API changes
      if (file.includes('service') || file.includes('api')) {
        docsToUpdate.add('07-API/API_REFERENCE.md');
      }
      
      // Voucher/Payment
      if (file.includes('voucher') || file.includes('payment')) {
        docsToUpdate.add('02-FEATURES/VOUCHER_SYSTEM_100_COMPLETE.md');
        docsToUpdate.add('02-FEATURES/PAYMENT_CONSOLIDATED.md');
      }
    }

    return Array.from(docsToUpdate);
  }

  /**
   * Update version in docs
   */
  updateVersionInDocs() {
    const version = this.getProjectVersion();
    const today = new Date().toISOString().split('T')[0];
    
    // Update INDEX.md
    const indexPath = path.join(DOCS_ROOT, 'INDEX.md');
    if (fs.existsSync(indexPath)) {
      let content = fs.readFileSync(indexPath, 'utf-8');
      content = content.replace(/\*\*Version:\*\* [\d.]+/, `**Version:** ${version}`);
      content = content.replace(/\*\*Last Updated:\*\* .+/, `**Last Updated:** ${today}`);
      fs.writeFileSync(indexPath, content);
      this.stats.docsUpdated++;
      console.log(`✅ Updated INDEX.md with version ${version}`);
    }

    // Update 00-START-HERE.md
    const startPath = path.join(DOCS_ROOT, '00-START-HERE.md');
    if (fs.existsSync(startPath)) {
      let content = fs.readFileSync(startPath, 'utf-8');
      // Update version in download table
      content = content.replace(/\| [\d.]+ \|$/gm, `| ${version} |`);
      fs.writeFileSync(startPath, content);
      this.stats.docsUpdated++;
      console.log(`✅ Updated 00-START-HERE.md with version ${version}`);
    }
  }

  /**
   * Generate changelog from git commits
   */
  generateChangelog() {
    const commits = this.getRecentCommits(30);
    if (commits.length === 0) return;

    const changelogPath = path.join(DOCS_ROOT, '05-GUIDES', 'CHANGELOG.md');
    const today = new Date().toISOString().split('T')[0];
    const version = this.getProjectVersion();

    // Categorize commits
    const features = [];
    const fixes = [];
    const others = [];

    for (const commit of commits) {
      const lower = commit.toLowerCase();
      if (lower.includes('feat') || lower.includes('add') || lower.includes('new')) {
        features.push(commit);
      } else if (lower.includes('fix') || lower.includes('bug') || lower.includes('hotfix')) {
        fixes.push(commit);
      } else {
        others.push(commit);
      }
    }

    // Generate new section
    let newSection = `\n## [${version}] - ${today}\n\n`;
    
    if (features.length > 0) {
      newSection += `### ✨ Features\n`;
      features.slice(0, 10).forEach(c => {
        newSection += `- ${c.substring(8)}\n`; // Remove commit hash
      });
      newSection += '\n';
    }
    
    if (fixes.length > 0) {
      newSection += `### 🐛 Bug Fixes\n`;
      fixes.slice(0, 10).forEach(c => {
        newSection += `- ${c.substring(8)}\n`;
      });
      newSection += '\n';
    }

    console.log(`📝 Generated changelog section for ${version}`);
    console.log(newSection);
    
    return newSection;
  }

  /**
   * Check documentation health
   */
  checkDocsHealth() {
    const issues = [];
    
    // Check required files exist
    const requiredFiles = [
      'INDEX.md',
      '00-START-HERE.md',
      'HOW_TO_READ_DOCS.md',
      '01-ARCHITECTURE/SYSTEM_ARCHITECTURE.md',
      '05-GUIDES/QUICK_START.md',
      '07-API/API_REFERENCE.md',
      '08-DATABASE/DATABASE_SCHEMA.md',
    ];

    for (const file of requiredFiles) {
      const fullPath = path.join(DOCS_ROOT, file);
      if (!fs.existsSync(fullPath)) {
        issues.push(`❌ Missing: ${file}`);
      }
    }

    // Check for outdated docs (>30 days old)
    const thirtyDaysAgo = Date.now() - 30 * 24 * 60 * 60 * 1000;
    
    const checkDir = (dir) => {
      if (!fs.existsSync(dir)) return;
      const items = fs.readdirSync(dir);
      for (const item of items) {
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
          checkDir(fullPath);
        } else if (item.endsWith('.md')) {
          if (stat.mtimeMs < thirtyDaysAgo) {
            const relativePath = path.relative(DOCS_ROOT, fullPath);
            issues.push(`⚠️ Outdated (>30d): ${relativePath}`);
          }
        }
      }
    };
    
    checkDir(DOCS_ROOT);

    return issues;
  }

  /**
   * Generate docs status report
   */
  generateStatusReport() {
    const version = this.getProjectVersion();
    const commits = this.getRecentCommits(7);
    const needsUpdate = this.analyzeChanges();
    const healthIssues = this.checkDocsHealth();

    const report = `# 📊 Documentation Status Report

**Generated:** ${new Date().toISOString()}
**Project Version:** ${version}

## 📈 Summary

| Metric | Value |
|--------|-------|
| Recent Commits (7d) | ${commits.length} |
| Docs Needing Update | ${needsUpdate.length} |
| Health Issues | ${healthIssues.length} |

## 🔄 Docs That May Need Update

Based on recent code changes:

${needsUpdate.map(d => `- [ ] ${d}`).join('\n') || '✅ All docs appear up-to-date'}

## 🏥 Health Check

${healthIssues.map(i => `- ${i}`).join('\n') || '✅ All health checks passed'}

## 📝 Recent Commits

${commits.slice(0, 10).map(c => `- ${c}`).join('\n') || 'No recent commits'}

---
*Run \`node scripts/docs-auto-updater.js --update\` to auto-update docs*
`;

    return report;
  }

  /**
   * Main run method
   */
  run(mode = 'check') {
    console.log('📚 SABO Arena Docs Auto-Updater\n');
    console.log('='.repeat(50));

    switch (mode) {
      case 'check':
        const report = this.generateStatusReport();
        console.log(report);
        
        // Save report
        const reportPath = path.join(DOCS_ROOT, '09-REPORTS', 'DOCS_STATUS_REPORT.md');
        fs.writeFileSync(reportPath, report);
        console.log(`\n📄 Report saved to: ${reportPath}`);
        break;

      case 'update':
        console.log('\n🔄 Updating documentation...\n');
        this.updateVersionInDocs();
        console.log(`\n✅ Updated ${this.stats.docsUpdated} documents`);
        break;

      case 'changelog':
        console.log('\n📝 Generating changelog...\n');
        this.generateChangelog();
        break;

      default:
        console.log('Unknown mode. Use --check, --update, or --changelog');
    }
  }
}

// CLI
const args = process.argv.slice(2);
const updater = new DocsAutoUpdater();

if (args.includes('--help')) {
  console.log(`
Usage: node docs-auto-updater.js [options]

Options:
  --check      Check what needs updating (default)
  --update     Auto-update version info in docs
  --changelog  Generate changelog from git commits
  --help       Show this help
`);
} else if (args.includes('--update')) {
  updater.run('update');
} else if (args.includes('--changelog')) {
  updater.run('changelog');
} else {
  updater.run('check');
}
