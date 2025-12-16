#!/usr/bin/env node
/**
 * SABO Arena Documentation Organizer
 * 
 * Script tự động tổ chức tài liệu cho project SABO Arena
 * Sử dụng shared config từ _SHARED/configs/docs-management.config.json
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ROOT = path.join(__dirname, '..');
const DOCS_ROOT = path.join(PROJECT_ROOT, '_DOCS');

// Categories mapping for SABO Arena specific files
const FILE_MAPPINGS = {
  // Architecture
  '01-ARCHITECTURE': [
    'FLUTTER_PROJECT_STRUCTURE.md',
    'CODING_GUIDELINES_SPA_UPDATES.md',
    'SINGLE_SOURCE_OF_TRUTH_IMPLEMENTATION.md',
    'SPA_SAFETY_SYSTEM_README.md',
  ],
  
  // Features  
  '02-FEATURES': [
    // Tournament
    'CROSS_FINALS_LAYOUT.md',
    'AUTO_FILL_CROSS_FINALS_SOLUTION.md',
    'GUARANTEE_16_PARTICIPANTS.md',
    'SABO_DE24_FORMAT.md',
    'SABO_DE24_INTEGRATION_COMPLETE.md',
    'TOURNAMENT_FIX_SUMMARY.md',
    'DE16_ADVANCEMENT_FIX_COMPLETE.md',
    'SABO_DE32_SERVICE_FIX_COMPLETE.md',
    'SABO_DE24_DATABASE_FIX.md',
    // ELO System
    'ELO_UPDATE_FLOW.md',
    'ELO_UPDATE_FLOW_SIMPLE.md',
    'ELO_HISTORY_CARD_ENHANCEMENT.md',
    'ELO_HISTORY_MISSING_FIX.md',
    'ELO_PROFILE_UPDATE_FIX.md',
    'FIX_ELO_NOT_UPDATING_PROFILE.md',
    'FIX_ELO_UPDATE_FINAL_SUMMARY.md',
    'ADD_ELO_ENABLED_COLUMN_GUIDE.md',
    'QUICK_FIX_elo_enabled.md',
    'RANK_HISTORY_FIX.md',
    // Voucher
    'VOUCHER_SYSTEM_100_COMPLETE.md',
    'VOUCHER_SYSTEM_FIX_COMPLETE.md',
    'VOUCHER_FIX_APPLIED.md',
    'VOUCHER_FALLBACK_SOLUTION.md',
    'MINIMAL_VOUCHER_FIX.md',
    'CLB_VOUCHER_MANAGEMENT_GUIDE.md',
    'PROFESSIONAL_VOUCHER_MODAL_CREATED.md',
    'TEST_PROFESSIONAL_VOUCHER_SYSTEM.md',
    // Rewards
    'DUPLICATE_REWARDS_FIX_COMPLETE.md',
    'DUPLICATE_REWARDS_BUG_REPORT.md',
    'DUPLICATE_REWARD_PREVENTION_FIXED.md',
    'USER_JOURNEY_TOURNAMENT_REWARDS.md',
    'END_TO_END_USER_REWARDS_FLOW.md',
    // Notifications
    'NOTIFICATION_SYSTEM_FIXED.md',
    // Posts
    'FIX_POST_IMAGE_IOS_PERMISSION.md',
    // Profile
    'AUTO_REFRESH_PROFILE_COMPLETE.md',
    // iPad
    'IPAD_OPTIMIZATION_IMPLEMENTATION_PLAN.md',
    'PHASE_3_IPAD_OPTIMIZATION_COMPLETE.md',
    // QR/DeepLink
    'TEST_QR_DEEPLINK_FIX.md',
    // Analytics
    'ANALYTICS_USAGE.md',
    // SPA
    'FIX_SPA_RACE_CONDITION.md',
    'FIX_LOG_SABO_DE16_COMPLETION.md',
  ],
  
  // Operations
  '03-OPERATIONS': [
    'TESTING_GUIDE.md',
    'END_TO_END_VERIFICATION_COMPLETE.md',
    'FINAL_VERIFICATION_REPORT.md',
    'IMPLEMENTATION_COMPLETE.md',
  ],
  
  // Deployment
  '04-DEPLOYMENT': [
    'GOOGLE_PLAY_UPLOAD_CHECKLIST.md',
    'IOS_RELEASE_NOTES.md',
    'APP_STORE_WHATS_NEW.md',
    'BUILD_SUCCESS_v1.2.1.md',
    'BUILD_DEPLOY_IOS_SSL_FIX.md',
    'IOS_SSL_CERTIFICATE_FIX_COMPLETE.md',
    'SSL_FIX_SUMMARY.md',
    'FOREIGN_KEY_FIX_APPLIED.md',
  ],
  
  // Guides
  '05-GUIDES': [
    'README.md',
    'QUICK_START_DE24.md',
    'CHANGELOG.md',
  ],
  
  // Database
  '08-DATABASE': [
    'DATABASE_MIGRATIONS_GUIDE.md',
  ],
  
  // Reports/Phases
  '09-REPORTS': [
    'PHASE_2_COMPLETE.md',
    'PHASE_3_PROGRESS_UPDATE.md',
  ],
};

class SaboArenaDocsOrganizer {
  constructor() {
    this.stats = {
      moved: 0,
      skipped: 0,
      errors: []
    };
  }

  /**
   * Ensure _DOCS folder structure exists
   */
  ensureStructure() {
    const folders = [
      '01-ARCHITECTURE',
      '02-FEATURES',
      '02-FEATURES/tournament',
      '02-FEATURES/elo-ranking',
      '02-FEATURES/voucher',
      '02-FEATURES/rewards',
      '02-FEATURES/notifications',
      '02-FEATURES/posts',
      '02-FEATURES/profile',
      '02-FEATURES/ipad',
      '02-FEATURES/deeplink',
      '02-FEATURES/analytics',
      '02-FEATURES/spa',
      '03-OPERATIONS',
      '04-DEPLOYMENT',
      '05-GUIDES',
      '06-AI',
      '07-API',
      '08-DATABASE',
      '09-REPORTS',
      '99-ARCHIVE',
    ];

    for (const folder of folders) {
      const fullPath = path.join(DOCS_ROOT, folder);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
        console.log(`📁 Created: ${folder}`);
      }
    }
  }

  /**
   * Move files to correct folders
   */
  organizeFiles(dryRun = true) {
    console.log(`\n${dryRun ? '🔍 DRY RUN' : '🚀 EXECUTING'} - Organizing files...\n`);

    for (const [folder, files] of Object.entries(FILE_MAPPINGS)) {
      for (const file of files) {
        const sourcePath = path.join(PROJECT_ROOT, file);
        const destPath = path.join(DOCS_ROOT, folder, file);

        if (fs.existsSync(sourcePath)) {
          if (dryRun) {
            console.log(`  📄 ${file} → _DOCS/${folder}/`);
          } else {
            try {
              // Create subfolder if needed
              const destDir = path.dirname(destPath);
              if (!fs.existsSync(destDir)) {
                fs.mkdirSync(destDir, { recursive: true });
              }
              
              fs.copyFileSync(sourcePath, destPath);
              console.log(`  ✅ Moved: ${file}`);
              this.stats.moved++;
            } catch (err) {
              console.log(`  ❌ Error: ${file} - ${err.message}`);
              this.stats.errors.push({ file, error: err.message });
            }
          }
        } else {
          this.stats.skipped++;
        }
      }
    }

    return this.stats;
  }

  /**
   * Generate INDEX.md
   */
  generateIndex() {
    const index = `# 📚 SABO Arena Documentation

*Tài liệu hoàn chỉnh cho SABO Arena Mobile App*

**Last Updated:** ${new Date().toISOString().split('T')[0]}

---

## 🗂️ Danh Mục Tài Liệu

### 🏗️ [01-ARCHITECTURE](./01-ARCHITECTURE/)
Kiến trúc hệ thống và design patterns
- Flutter Project Structure
- Coding Guidelines
- Single Source of Truth Pattern
- SPA Safety System

### ✨ [02-FEATURES](./02-FEATURES/)
Tài liệu các tính năng chính

#### 🏆 Tournament System
- [SABO DE16/DE24/DE32 Formats](./02-FEATURES/tournament/)
- Cross Finals Layout
- Auto Advancement Logic

#### 📊 ELO & Ranking
- [ELO Update Flow](./02-FEATURES/elo-ranking/)
- Rank History System
- Profile Integration

#### 🎟️ Voucher System
- [Voucher Management](./02-FEATURES/voucher/)
- CLB Voucher Guide
- Professional Voucher Modal

#### 🎁 Rewards System
- [User Journey & Rewards](./02-FEATURES/rewards/)
- Duplicate Prevention
- End-to-End Flow

#### 🔔 Notifications
- Push Notification System
- In-App Alerts

#### 📱 Platform Specific
- iPad Optimization
- iOS Permissions

### ⚙️ [03-OPERATIONS](./03-OPERATIONS/)
Testing & Verification
- Testing Guide
- E2E Verification
- Final Reports

### 🚀 [04-DEPLOYMENT](./04-DEPLOYMENT/)
Build & Release
- Google Play Checklist
- iOS Release Notes
- SSL Certificate Fixes
- App Store Guidelines

### 📖 [05-GUIDES](./05-GUIDES/)
Hướng dẫn sử dụng
- README & Quick Start
- Changelog

### 🗄️ [08-DATABASE](./08-DATABASE/)
Database & Migrations
- Migration Guide
- Schema Documentation

### 📊 [09-REPORTS](./09-REPORTS/)
Progress Reports
- Phase Completion Reports
- Status Updates

---

## 🔗 Quick Links

| Resource | Description |
|----------|-------------|
| [README.md](./05-GUIDES/README.md) | Project overview |
| [CHANGELOG.md](./05-GUIDES/CHANGELOG.md) | Version history |
| [Testing Guide](./03-OPERATIONS/TESTING_GUIDE.md) | How to test |
| [Deploy Checklist](./04-DEPLOYMENT/GOOGLE_PLAY_UPLOAD_CHECKLIST.md) | Release process |

---

## 📁 Legacy Documentation

Các tài liệu cũ đã được tổ chức tại:
- \`_CORE_DOCS/\` - Core consolidated docs
- \`_CORE_DOCS_OPTIMIZED/\` - Optimized versions
- \`docs/\` - Original docs folder

---

*Generated by organize-project-docs.js*
`;

    const indexPath = path.join(DOCS_ROOT, 'INDEX.md');
    fs.writeFileSync(indexPath, index);
    console.log(`\n✅ Generated INDEX.md`);
    return indexPath;
  }

  /**
   * Consolidate existing docs folders
   */
  consolidateExistingDocs() {
    // Copy important files from _CORE_DOCS
    const coreDocsPath = path.join(PROJECT_ROOT, '_CORE_DOCS');
    if (fs.existsSync(coreDocsPath)) {
      const consolidatedFiles = fs.readdirSync(coreDocsPath)
        .filter(f => f.endsWith('_CONSOLIDATED.md'));
      
      for (const file of consolidatedFiles) {
        const source = path.join(coreDocsPath, file);
        const categoryName = file.replace('_CONSOLIDATED.md', '').toLowerCase();
        
        // Map to appropriate folder
        let destFolder = '02-FEATURES';
        if (categoryName.includes('database')) destFolder = '08-DATABASE';
        if (categoryName.includes('operation')) destFolder = '03-OPERATIONS';
        if (categoryName.includes('auth')) destFolder = '01-ARCHITECTURE';
        
        const dest = path.join(DOCS_ROOT, destFolder, file);
        
        try {
          fs.copyFileSync(source, dest);
          console.log(`  📄 Consolidated: ${file}`);
        } catch (err) {
          console.log(`  ⚠️ Skip: ${file}`);
        }
      }
    }
  }

  /**
   * Run full organization
   */
  run(execute = false) {
    console.log('🏟️ SABO Arena Documentation Organizer\n');
    console.log('=' .repeat(50));
    
    // Step 1: Ensure structure
    console.log('\n📁 Step 1: Creating folder structure...');
    this.ensureStructure();
    
    // Step 2: Organize root files
    console.log('\n📄 Step 2: Organizing root markdown files...');
    this.organizeFiles(!execute);
    
    // Step 3: Consolidate existing docs
    if (execute) {
      console.log('\n📚 Step 3: Consolidating existing docs...');
      this.consolidateExistingDocs();
    }
    
    // Step 4: Generate index
    if (execute) {
      console.log('\n📝 Step 4: Generating INDEX.md...');
      this.generateIndex();
    }
    
    // Summary
    console.log('\n' + '='.repeat(50));
    console.log('📊 Summary:');
    console.log(`   Files to move: ${Object.values(FILE_MAPPINGS).flat().length}`);
    console.log(`   Moved: ${this.stats.moved}`);
    console.log(`   Skipped (not found): ${this.stats.skipped}`);
    console.log(`   Errors: ${this.stats.errors.length}`);
    
    if (!execute) {
      console.log('\n💡 Run with --execute to apply changes');
    }
  }
}

// CLI
const args = process.argv.slice(2);
const organizer = new SaboArenaDocsOrganizer();

if (args.includes('--help')) {
  console.log(`
Usage: node organize-project-docs.js [options]

Options:
  --execute    Apply changes (default is dry-run)
  --index      Generate INDEX.md only
  --help       Show this help
`);
} else if (args.includes('--index')) {
  organizer.ensureStructure();
  organizer.generateIndex();
} else {
  organizer.run(args.includes('--execute'));
}
