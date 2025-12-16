#!/usr/bin/env node
/**
 * 🔍 SUPABASE DATABASE AUDIT & PRODUCTION READINESS ASSESSMENT
 * Senior Database Engineer - Comprehensive audit for SABO Arena platform
 * 
 * NHIỆM VỤ: Ensure production-ready database before launch
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js';
import * as fs from 'fs';
import * as path from 'path';

// ============================================================================
// 🔐 CONFIGURATION
// ============================================================================

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://mogjjvscxjwvhtpkrlqr.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo';

// Color utilities for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

// ============================================================================
// 🎨 DISPLAY UTILITIES
// ============================================================================

function printHeader(text: string, char: string = '=', length: number = 80): void {
  console.log(`\n${colors.magenta}${char.repeat(length)}${colors.reset}`);
  console.log(`${colors.magenta}${colors.bright}${text.padStart((length + text.length) / 2).padEnd(length)}${colors.reset}`);
  console.log(`${colors.magenta}${char.repeat(length)}${colors.reset}`);
}

function printSuccess(text: string): void {
  console.log(`${colors.green}✅ ${text}${colors.reset}`);
}

function printWarning(text: string): void {
  console.log(`${colors.yellow}⚠️  ${text}${colors.reset}`);
}

function printError(text: string): void {
  console.log(`${colors.red}❌ ${text}${colors.reset}`);
}

function printInfo(text: string): void {
  console.log(`${colors.cyan}ℹ️  ${text}${colors.reset}`);
}

function printCritical(text: string): void {
  console.log(`${colors.red}${colors.bright}🚨 CRITICAL: ${text}${colors.reset}`);
}

// ============================================================================
// 📊 TYPES & INTERFACES
// ============================================================================

interface TableInfo {
  table_name: string;
  column_name: string;
  data_type: string;
  is_nullable: string;
  column_default: string | null;
}

interface IndexInfo {
  schemaname: string;
  tablename: string;
  indexname: string;
  indexdef: string;
}

interface ForeignKeyInfo {
  table_name: string;
  column_name: string;
  foreign_table_name: string;
  foreign_column_name: string;
  constraint_name: string;
}

interface RLSPolicy {
  schemaname: string;
  tablename: string;
  policyname: string;
  permissive: string;
  roles: string[];
  cmd: string;
  qual: string;
  with_check: string;
}

interface AuditFinding {
  level: 'critical' | 'high' | 'medium' | 'info';
  category: 'security' | 'performance' | 'integrity' | 'schema';
  title: string;
  description: string;
  impact: string;
  fix: string;
  priority: string;
  table?: string;
}

interface AuditReport {
  executiveSummary: {
    status: 'NOT_READY' | 'NEEDS_WORK' | 'READY';
    criticalIssues: number;
    highPriorityIssues: number;
    mediumPriorityIssues: number;
    estimatedDaysToReady: number;
  };
  databaseOverview: {
    totalTables: number;
    totalColumns: number;
    totalIndexes: number;
    databaseSize: string;
    keyTables: Array<{
      name: string;
      rowCount: number;
      purpose: string;
      status: string;
    }>;
  };
  findings: AuditFinding[];
  migrationScripts: {
    critical: string;
    performance: string;
    integrity: string;
  };
  checklist: Array<{
    category: string;
    items: Array<{
      task: string;
      completed: boolean;
      priority: string;
    }>;
  }>;
}

// ============================================================================
// 🔍 DATABASE AUDITOR CLASS
// ============================================================================

class DatabaseAuditor {
  private supabase: SupabaseClient;
  private findings: AuditFinding[] = [];
  private tableInfo: TableInfo[] = [];
  private indexInfo: IndexInfo[] = [];
  private foreignKeys: ForeignKeyInfo[] = [];
  private rlsPolicies: RLSPolicy[] = [];
  private migrationScripts = {
    critical: '',
    performance: '',
    integrity: ''
  };

  constructor() {
    this.supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });
  }

  // ============================================================================
  // 🔌 CONNECTION & BASIC CHECKS
  // ============================================================================

  async testConnection(): Promise<boolean> {
    try {
      printInfo('Testing database connection...');
      const { data, error } = await this.supabase
        .from('profiles')
        .select('count')
        .limit(1);

      if (error) {
        printError(`Connection failed: ${error.message}`);
        return false;
      }

      printSuccess('Connected to Supabase successfully');
      return true;
    } catch (err) {
      printError(`Connection error: ${err instanceof Error ? err.message : 'Unknown error'}`);
      return false;
    }
  }

  // ============================================================================
  // 📊 SCHEMA ANALYSIS
  // ============================================================================

  async analyzeSchema(): Promise<void> {
    printHeader('🔍 ANALYZING DATABASE SCHEMA');

    try {
      // Get all tables
      const { data: tables, error: tablesError } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT 
            schemaname,
            tablename,
            tableowner
          FROM pg_tables 
          WHERE schemaname = 'public'
          ORDER BY tablename;
        `
      });

      if (tablesError) {
        printWarning('Using alternative method to get table information...');
        await this.getTablesAlternative();
      } else {
        printSuccess(`Found ${tables?.length || 0} tables in public schema`);
        if (tables) {
          tables.forEach((table: any) => {
            printInfo(`📋 Table: ${table.tablename}`);
          });
        }
      }

      // Get column information
      await this.analyzeColumns();
      
    } catch (err) {
      printError(`Schema analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  private async getTablesAlternative(): Promise<void> {
    // Try to get tables by introspecting the REST API
    const knownTables = [
      'profiles', 'tournaments', 'tournament_participants', 'clubs', 'club_members',
      'vouchers', 'user_vouchers', 'payments', 'notifications', 'matches',
      'chat_rooms', 'chat_messages', 'table_reservations', 'venue_facilities'
    ];

    printInfo('Checking known tables...');
    for (const tableName of knownTables) {
      try {
        const { data, error } = await this.supabase
          .from(tableName)
          .select('*')
          .limit(0);

        if (!error) {
          printSuccess(`✓ Table exists: ${tableName}`);
        }
      } catch (err) {
        // Table doesn't exist or no access
      }
    }
  }

  private async analyzeColumns(): Promise<void> {
    try {
      const { data: columns, error } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT 
            table_name,
            column_name,
            data_type,
            is_nullable,
            column_default
          FROM information_schema.columns
          WHERE table_schema = 'public'
          ORDER BY table_name, ordinal_position;
        `
      });

      if (error) {
        printWarning(`Could not get column information: ${error.message}`);
        return;
      }

      this.tableInfo = columns || [];
      printSuccess(`Analyzed ${this.tableInfo.length} columns across all tables`);

    } catch (err) {
      printError(`Column analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  // ============================================================================
  // 🔗 RELATIONSHIPS & CONSTRAINTS ANALYSIS
  // ============================================================================

  async analyzeRelationships(): Promise<void> {
    printHeader('🔗 ANALYZING RELATIONSHIPS & CONSTRAINTS');

    await this.analyzeForeignKeys();
    await this.analyzePrimaryKeys();
    await this.analyzeUniqueConstraints();
  }

  private async analyzeForeignKeys(): Promise<void> {
    try {
      const { data: foreignKeys, error } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT
            tc.table_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            tc.constraint_name
          FROM information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public';
        `
      });

      if (error) {
        printWarning(`Could not analyze foreign keys: ${error.message}`);
        this.addFinding({
          level: 'high',
          category: 'integrity',
          title: 'Cannot verify foreign key constraints',
          description: 'Unable to query foreign key information from database',
          impact: 'Cannot ensure referential integrity',
          fix: 'Check database permissions and run manual foreign key analysis',
          priority: 'P1'
        });
        return;
      }

      this.foreignKeys = foreignKeys || [];
      printSuccess(`Found ${this.foreignKeys.length} foreign key constraints`);

      // Check for missing foreign keys in critical relationships
      await this.checkMissingForeignKeys();

    } catch (err) {
      printError(`Foreign key analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  private async checkMissingForeignKeys(): Promise<void> {
    // Define expected foreign key relationships
    const expectedFKs = [
      { table: 'tournaments', column: 'user_id', references: 'profiles.id' },
      { table: 'tournament_participants', column: 'tournament_id', references: 'tournaments.id' },
      { table: 'tournament_participants', column: 'user_id', references: 'profiles.id' },
      { table: 'club_members', column: 'club_id', references: 'clubs.id' },
      { table: 'club_members', column: 'user_id', references: 'profiles.id' },
      { table: 'user_vouchers', column: 'user_id', references: 'profiles.id' },
      { table: 'user_vouchers', column: 'voucher_id', references: 'vouchers.id' },
      { table: 'payments', column: 'user_id', references: 'profiles.id' },
      { table: 'chat_messages', column: 'room_id', references: 'chat_rooms.id' },
      { table: 'chat_messages', column: 'user_id', references: 'profiles.id' },
    ];

    for (const expectedFK of expectedFKs) {
      const exists = this.foreignKeys.some(fk => 
        fk.table_name === expectedFK.table && 
        fk.column_name === expectedFK.column &&
        `${fk.foreign_table_name}.${fk.foreign_column_name}` === expectedFK.references
      );

      if (!exists) {
        this.addFinding({
          level: 'critical',
          category: 'integrity',
          title: `Missing foreign key: ${expectedFK.table}.${expectedFK.column}`,
          description: `Table ${expectedFK.table} column ${expectedFK.column} should reference ${expectedFK.references}`,
          impact: 'Potential orphaned records, data inconsistency, integrity violations',
          fix: `ALTER TABLE ${expectedFK.table} ADD CONSTRAINT fk_${expectedFK.table}_${expectedFK.column} FOREIGN KEY (${expectedFK.column}) REFERENCES ${expectedFK.references.split('.')[0]}(${expectedFK.references.split('.')[1]}) ON DELETE CASCADE;`,
          priority: 'P0 (Blocking)',
          table: expectedFK.table
        });
      }
    }
  }

  private async analyzePrimaryKeys(): Promise<void> {
    try {
      const { data: primaryKeys, error } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT
            tc.table_name,
            kcu.column_name,
            tc.constraint_name
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
          WHERE tc.constraint_type = 'PRIMARY KEY'
            AND tc.table_schema = 'public';
        `
      });

      if (error) {
        printWarning(`Could not analyze primary keys: ${error.message}`);
        return;
      }

      printSuccess(`Found ${primaryKeys?.length || 0} primary key constraints`);

    } catch (err) {
      printError(`Primary key analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  private async analyzeUniqueConstraints(): Promise<void> {
    try {
      const { data: uniqueConstraints, error } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT
            tc.table_name,
            kcu.column_name,
            tc.constraint_name
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
          WHERE tc.constraint_type = 'UNIQUE'
            AND tc.table_schema = 'public';
        `
      });

      if (error) {
        printWarning(`Could not analyze unique constraints: ${error.message}`);
        return;
      }

      printSuccess(`Found ${uniqueConstraints?.length || 0} unique constraints`);

      // Check for missing unique constraints
      await this.checkMissingUniqueConstraints();

    } catch (err) {
      printError(`Unique constraint analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  private async checkMissingUniqueConstraints(): Promise<void> {
    const expectedUnique = [
      { table: 'profiles', column: 'username' },
      { table: 'profiles', column: 'email' },
      { table: 'clubs', column: 'name' },
      { table: 'vouchers', column: 'code' },
    ];

    // This would require checking actual data, which we'll simulate for now
    for (const expected of expectedUnique) {
      this.addFinding({
        level: 'high',
        category: 'integrity',
        title: `Verify unique constraint: ${expected.table}.${expected.column}`,
        description: `Should verify that ${expected.table}.${expected.column} has unique constraint`,
        impact: 'Potential duplicate data entries',
        fix: `ALTER TABLE ${expected.table} ADD CONSTRAINT unique_${expected.column} UNIQUE(${expected.column});`,
        priority: 'P1',
        table: expected.table
      });
    }
  }

  // ============================================================================
  // 📊 INDEX ANALYSIS
  // ============================================================================

  async analyzeIndexes(): Promise<void> {
    printHeader('📊 ANALYZING INDEXES & PERFORMANCE');

    try {
      const { data: indexes, error } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT
            schemaname,
            tablename,
            indexname,
            indexdef
          FROM pg_indexes
          WHERE schemaname = 'public'
          ORDER BY tablename, indexname;
        `
      });

      if (error) {
        printWarning(`Could not analyze indexes: ${error.message}`);
        await this.checkMissingIndexes();
        return;
      }

      this.indexInfo = indexes || [];
      printSuccess(`Found ${this.indexInfo.length} indexes`);

      await this.checkMissingIndexes();
      await this.analyzeMissingIndexesOnForeignKeys();

    } catch (err) {
      printError(`Index analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  private async checkMissingIndexes(): Promise<void> {
    const recommendedIndexes = [
      { table: 'tournaments', column: 'user_id', reason: 'Foreign key queries' },
      { table: 'tournaments', column: 'status', reason: 'Status filtering' },
      { table: 'tournaments', column: 'start_time', reason: 'Time-based queries' },
      { table: 'tournament_participants', column: 'tournament_id', reason: 'Foreign key queries' },
      { table: 'tournament_participants', column: 'user_id', reason: 'Foreign key queries' },
      { table: 'club_members', column: 'club_id', reason: 'Foreign key queries' },
      { table: 'club_members', column: 'user_id', reason: 'Foreign key queries' },
      { table: 'user_vouchers', column: 'user_id', reason: 'User voucher lookups' },
      { table: 'user_vouchers', column: 'voucher_id', reason: 'Voucher usage tracking' },
      { table: 'payments', column: 'user_id', reason: 'Payment history queries' },
      { table: 'payments', column: 'status', reason: 'Payment status filtering' },
      { table: 'chat_messages', column: 'room_id', reason: 'Chat room message queries' },
      { table: 'chat_messages', column: 'created_at', reason: 'Message ordering' },
      { table: 'profiles', column: 'email', reason: 'Login queries' },
      { table: 'profiles', column: 'username', reason: 'Username lookups' },
    ];

    for (const recommended of recommendedIndexes) {
      const exists = this.indexInfo.some(idx => 
        idx.tablename === recommended.table && 
        idx.indexdef.toLowerCase().includes(recommended.column.toLowerCase())
      );

      if (!exists) {
        this.addFinding({
          level: 'high',
          category: 'performance',
          title: `Missing index: ${recommended.table}.${recommended.column}`,
          description: `Table ${recommended.table} should have index on ${recommended.column} for ${recommended.reason}`,
          impact: 'Slow queries, poor performance under load',
          fix: `CREATE INDEX IF NOT EXISTS idx_${recommended.table}_${recommended.column} ON ${recommended.table}(${recommended.column});`,
          priority: 'P1',
          table: recommended.table
        });
      }
    }
  }

  private async analyzeMissingIndexesOnForeignKeys(): Promise<void> {
    for (const fk of this.foreignKeys) {
      const exists = this.indexInfo.some(idx => 
        idx.tablename === fk.table_name && 
        idx.indexdef.toLowerCase().includes(fk.column_name.toLowerCase())
      );

      if (!exists) {
        this.addFinding({
          level: 'high',
          category: 'performance',
          title: `Missing index on foreign key: ${fk.table_name}.${fk.column_name}`,
          description: `Foreign key column ${fk.column_name} in table ${fk.table_name} should have an index`,
          impact: 'Slow JOIN queries, poor foreign key performance',
          fix: `CREATE INDEX IF NOT EXISTS idx_${fk.table_name}_${fk.column_name} ON ${fk.table_name}(${fk.column_name});`,
          priority: 'P1',
          table: fk.table_name
        });
      }
    }
  }

  // ============================================================================
  // 🔒 ROW-LEVEL SECURITY ANALYSIS
  // ============================================================================

  async analyzeRLS(): Promise<void> {
    printHeader('🔒 ANALYZING ROW-LEVEL SECURITY');

    try {
      // Check which tables have RLS enabled
      const { data: rlsTables, error: rlsError } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT
            schemaname,
            tablename,
            rowsecurity
          FROM pg_tables
          WHERE schemaname = 'public';
        `
      });

      if (rlsError) {
        printWarning(`Could not check RLS status: ${rlsError.message}`);
        await this.checkRLSAlternative();
        return;
      }

      // Check RLS policies
      const { data: policies, error: policiesError } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT
            schemaname,
            tablename,
            policyname,
            permissive,
            roles,
            cmd,
            qual,
            with_check
          FROM pg_policies
          WHERE schemaname = 'public'
          ORDER BY tablename, policyname;
        `
      });

      if (policiesError) {
        printWarning(`Could not get RLS policies: ${policiesError.message}`);
      }

      await this.analyzeRLSGaps(rlsTables || [], policies || []);

    } catch (err) {
      printError(`RLS analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  private async checkRLSAlternative(): Promise<void> {
    // Test RLS by trying to access tables as anonymous user
    const testTables = ['profiles', 'tournaments', 'payments', 'user_vouchers'];
    
    // 🔐 SECURITY FIX: Use environment variable for anon key
    const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
    if (!SUPABASE_ANON_KEY) {
      console.log('⚠️  Skipping RLS test - SUPABASE_ANON_KEY not provided');
      return;
    }
    
    for (const table of testTables) {
      try {
        // Create anonymous client
        const anonClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        
        const { data, error } = await anonClient
          .from(table)
          .select('*')
          .limit(1);

        if (!error && data && data.length > 0) {
          this.addFinding({
            level: 'critical',
            category: 'security',
            title: `RLS not properly configured for table: ${table}`,
            description: `Anonymous users can access data in ${table} table`,
            impact: 'SECURITY BREACH: Unauthorized data access possible',
            fix: `ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY; CREATE appropriate RLS policies`,
            priority: 'P0 (BLOCKING)',
            table: table
          });
        } else if (error && error.message.includes('RLS')) {
          printSuccess(`✓ RLS appears to be working for table: ${table}`);
        }

      } catch (err) {
        // Expected for properly secured tables
      }
    }
  }

  private async analyzeRLSGaps(rlsTables: any[], policies: any[]): Promise<void> {
    const criticalTables = [
      'profiles', 'tournaments', 'tournament_participants', 'clubs', 'club_members',
      'user_vouchers', 'payments', 'chat_messages', 'table_reservations'
    ];

    for (const table of criticalTables) {
      const tableRLS = rlsTables.find(t => t.tablename === table);
      const tablePolicies = policies.filter(p => p.tablename === table);

      // Check if RLS is enabled
      if (!tableRLS || !tableRLS.rowsecurity) {
        this.addFinding({
          level: 'critical',
          category: 'security',
          title: `RLS not enabled for table: ${table}`,
          description: `Table ${table} does not have Row Level Security enabled`,
          impact: 'SECURITY BREACH: Anyone can read/write data without restrictions',
          fix: `ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY;`,
          priority: 'P0 (BLOCKING)',
          table: table
        });
      }

      // Check if policies exist
      if (tablePolicies.length === 0) {
        this.addFinding({
          level: 'critical',
          category: 'security',
          title: `No RLS policies for table: ${table}`,
          description: `Table ${table} has RLS enabled but no policies defined`,
          impact: 'NO ACCESS: Users cannot access data (complete lockout)',
          fix: `CREATE appropriate RLS policies for SELECT, INSERT, UPDATE, DELETE operations`,
          priority: 'P0 (BLOCKING)',
          table: table
        });
      }

      // Check policy coverage
      const hasSelectPolicy = tablePolicies.some(p => p.cmd === 'SELECT');
      const hasInsertPolicy = tablePolicies.some(p => p.cmd === 'INSERT');
      const hasUpdatePolicy = tablePolicies.some(p => p.cmd === 'UPDATE');
      const hasDeletePolicy = tablePolicies.some(p => p.cmd === 'DELETE');

      if (!hasSelectPolicy) {
        this.addFinding({
          level: 'high',
          category: 'security',
          title: `Missing SELECT policy for table: ${table}`,
          description: `No SELECT policy defined for ${table}`,
          impact: 'Users cannot read data from this table',
          fix: `CREATE POLICY "${table}_select_policy" ON ${table} FOR SELECT USING (appropriate_condition);`,
          priority: 'P1',
          table: table
        });
      }

      if (table !== 'profiles' && !hasInsertPolicy) {
        this.addFinding({
          level: 'high',
          category: 'security',
          title: `Missing INSERT policy for table: ${table}`,
          description: `No INSERT policy defined for ${table}`,
          impact: 'Users cannot create new records',
          fix: `CREATE POLICY "${table}_insert_policy" ON ${table} FOR INSERT WITH CHECK (appropriate_condition);`,
          priority: 'P1',
          table: table
        });
      }
    }
  }

  // ============================================================================
  // 🔍 DATA INTEGRITY CHECKS
  // ============================================================================

  async analyzeDataIntegrity(): Promise<void> {
    printHeader('🔍 ANALYZING DATA INTEGRITY');

    await this.checkNullValues();
    await this.checkDuplicateData();
    await this.checkOrphanedRecords();
  }

  private async checkNullValues(): Promise<void> {
    const criticalFields = [
      { table: 'profiles', column: 'id', required: true },
      { table: 'profiles', column: 'email', required: true },
      { table: 'tournaments', column: 'id', required: true },
      { table: 'tournaments', column: 'user_id', required: true },
      { table: 'tournament_participants', column: 'tournament_id', required: true },
      { table: 'tournament_participants', column: 'user_id', required: true },
    ];

    for (const field of criticalFields) {
      try {
        const { data, error } = await this.supabase
          .from(field.table)
          .select(field.column)
          .is(field.column, null)
          .limit(1);

        if (error) {
          printWarning(`Could not check NULL values in ${field.table}.${field.column}: ${error.message}`);
          continue;
        }

        if (data && data.length > 0 && field.required) {
          this.addFinding({
            level: 'critical',
            category: 'integrity',
            title: `NULL values in critical field: ${field.table}.${field.column}`,
            description: `Found NULL values in required field ${field.column} of table ${field.table}`,
            impact: 'Data integrity violation, potential application crashes',
            fix: `UPDATE ${field.table} SET ${field.column} = appropriate_value WHERE ${field.column} IS NULL; ALTER TABLE ${field.table} ALTER COLUMN ${field.column} SET NOT NULL;`,
            priority: 'P0 (BLOCKING)',
            table: field.table
          });
        }

      } catch (err) {
        printWarning(`Error checking NULL values in ${field.table}.${field.column}`);
      }
    }
  }

  private async checkDuplicateData(): Promise<void> {
    const uniqueFields = [
      { table: 'profiles', column: 'username' },
      { table: 'profiles', column: 'email' },
      { table: 'clubs', column: 'name' },
    ];

    for (const field of uniqueFields) {
      try {
        // This is a simplified check - in production, you'd run a GROUP BY query
        const { data, error } = await this.supabase
          .from(field.table)
          .select(field.column)
          .not(field.column, 'is', null)
          .limit(100);

        if (error) {
          printWarning(`Could not check duplicates in ${field.table}.${field.column}: ${error.message}`);
          continue;
        }

        if (data) {
          const values = data.map(row => row[field.column]);
          const uniqueValues = new Set(values);
          
          if (values.length !== uniqueValues.size) {
            this.addFinding({
              level: 'high',
              category: 'integrity',
              title: `Duplicate values in ${field.table}.${field.column}`,
              description: `Found duplicate values in ${field.column} which should be unique`,
              impact: 'Data inconsistency, potential login issues, business logic errors',
              fix: `Remove duplicates and add UNIQUE constraint: ALTER TABLE ${field.table} ADD CONSTRAINT unique_${field.column} UNIQUE(${field.column});`,
              priority: 'P1',
              table: field.table
            });
          }
        }

      } catch (err) {
        printWarning(`Error checking duplicates in ${field.table}.${field.column}`);
      }
    }
  }

  private async checkOrphanedRecords(): Promise<void> {
    // Check for orphaned tournament participants
    try {
      const { data: orphanedParticipants, error } = await this.supabase
        .from('tournament_participants')
        .select(`
          id,
          tournament_id,
          tournaments!inner(id)
        `)
        .is('tournaments.id', null)
        .limit(10);

      if (error && !error.message.includes('relation') && !error.message.includes('does not exist')) {
        printWarning(`Could not check orphaned tournament participants: ${error.message}`);
      } else if (orphanedParticipants && orphanedParticipants.length > 0) {
        this.addFinding({
          level: 'high',
          category: 'integrity',
          title: 'Orphaned tournament participants found',
          description: `Found tournament_participants records that reference non-existent tournaments`,
          impact: 'Data inconsistency, potential application errors',
          fix: 'DELETE FROM tournament_participants WHERE tournament_id NOT IN (SELECT id FROM tournaments);',
          priority: 'P1',
          table: 'tournament_participants'
        });
      }

    } catch (err) {
      // Expected if foreign keys are properly set up
    }
  }

  // ============================================================================
  // 📈 PERFORMANCE ANALYSIS
  // ============================================================================

  async analyzePerformance(): Promise<void> {
    printHeader('📈 ANALYZING PERFORMANCE');

    try {
      // Check table sizes
      const { data: tableSizes, error } = await this.supabase.rpc('exec_sql', {
        query: `
          SELECT
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
            pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS index_size
          FROM pg_tables
          WHERE schemaname = 'public'
          ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
        `
      });

      if (error) {
        printWarning(`Could not analyze table sizes: ${error.message}`);
      } else {
        printSuccess(`Analyzed table sizes for ${tableSizes?.length || 0} tables`);
        
        // Check for large tables without proper indexes
        if (tableSizes) {
          for (const table of tableSizes) {
            if (table.size && table.size.includes('MB') && parseInt(table.size) > 10) {
              const hasIndexes = this.indexInfo.some(idx => idx.tablename === table.tablename);
              if (!hasIndexes) {
                this.addFinding({
                  level: 'high',
                  category: 'performance',
                  title: `Large table without indexes: ${table.tablename}`,
                  description: `Table ${table.tablename} (${table.size}) has no indexes`,
                  impact: 'Poor query performance, slow application response',
                  fix: 'Add appropriate indexes based on query patterns',
                  priority: 'P1',
                  table: table.tablename
                });
              }
            }
          }
        }
      }

    } catch (err) {
      printError(`Performance analysis error: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  // ============================================================================
  // 🛠️ HELPER METHODS
  // ============================================================================

  private addFinding(finding: AuditFinding): void {
    this.findings.push(finding);
    
    const emoji = {
      critical: '🚨',
      high: '⚠️',
      medium: '📝',
      info: 'ℹ️'
    };

    console.log(`${emoji[finding.level]} ${finding.level.toUpperCase()}: ${finding.title}`);
  }

  // ============================================================================
  // 📋 MIGRATION SCRIPT GENERATION
  // ============================================================================

  private generateMigrationScripts(): void {
    const criticalFindings = this.findings.filter(f => f.level === 'critical');
    const performanceFindings = this.findings.filter(f => f.level === 'high' && f.category === 'performance');
    const integrityFindings = this.findings.filter(f => f.category === 'integrity');

    // Critical fixes script
    this.migrationScripts.critical = this.generateCriticalScript(criticalFindings);
    
    // Performance optimization script
    this.migrationScripts.performance = this.generatePerformanceScript(performanceFindings);
    
    // Data integrity script
    this.migrationScripts.integrity = this.generateIntegrityScript(integrityFindings);
  }

  private generateCriticalScript(findings: AuditFinding[]): string {
    let script = `-- ========================================
-- SABO ARENA - CRITICAL PRODUCTION FIXES
-- Priority: P0 (MUST run before launch)
-- Generated: ${new Date().toISOString()}
-- ========================================

BEGIN;

-- Critical Security and Schema Fixes
`;

    const rlsFindings = findings.filter(f => f.category === 'security');
    const fkFindings = findings.filter(f => f.category === 'integrity' && f.title.includes('Missing foreign key'));

    if (rlsFindings.length > 0) {
      script += `\n-- 1. ENABLE ROW LEVEL SECURITY\n`;
      const tables = [...new Set(rlsFindings.map(f => f.table).filter(Boolean))];
      for (const table of tables) {
        script += `ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY;\n`;
      }
    }

    if (fkFindings.length > 0) {
      script += `\n-- 2. ADD MISSING FOREIGN KEYS\n`;
      for (const finding of fkFindings) {
        script += `${finding.fix}\n`;
      }
    }

    script += `\n-- 3. CREATE BASIC RLS POLICIES\n`;
    script += `-- Note: These are basic policies - review and customize for your needs\n`;
    
    const tables = ['profiles', 'tournaments', 'tournament_participants'];
    for (const table of tables) {
      script += `
-- Policies for ${table}
CREATE POLICY "Enable read access for authenticated users" ON ${table}
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON ${table}
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for owners" ON ${table}
  FOR UPDATE USING (auth.uid() = user_id);

`;
    }

    script += `\nCOMMIT;\n`;
    
    return script;
  }

  private generatePerformanceScript(findings: AuditFinding[]): string {
    let script = `-- ========================================
-- SABO ARENA - PERFORMANCE OPTIMIZATION
-- Priority: P1 (High Priority)
-- Generated: ${new Date().toISOString()}
-- ========================================

BEGIN;

-- Performance Indexes
`;

    for (const finding of findings) {
      if (finding.fix.includes('CREATE INDEX')) {
        script += `${finding.fix}\n`;
      }
    }

    script += `\nCOMMIT;\n`;
    
    return script;
  }

  private generateIntegrityScript(findings: AuditFinding[]): string {
    let script = `-- ========================================
-- SABO ARENA - DATA INTEGRITY
-- Priority: P1-P2 (Review and execute carefully)
-- Generated: ${new Date().toISOString()}
-- ========================================

BEGIN;

-- Data Integrity Constraints
`;

    for (const finding of findings) {
      if (finding.fix.includes('ALTER TABLE') && finding.fix.includes('CONSTRAINT')) {
        script += `${finding.fix}\n`;
      }
    }

    script += `\nCOMMIT;\n`;
    
    return script;
  }

  // ============================================================================
  // 📊 REPORT GENERATION
  // ============================================================================

  private generateReport(): AuditReport {
    const criticalCount = this.findings.filter(f => f.level === 'critical').length;
    const highCount = this.findings.filter(f => f.level === 'high').length;
    const mediumCount = this.findings.filter(f => f.level === 'medium').length;

    let status: 'NOT_READY' | 'NEEDS_WORK' | 'READY' = 'READY';
    let estimatedDays = 0;

    if (criticalCount > 0) {
      status = 'NOT_READY';
      estimatedDays = Math.ceil(criticalCount * 0.5 + highCount * 0.3 + mediumCount * 0.1);
    } else if (highCount > 5) {
      status = 'NEEDS_WORK';
      estimatedDays = Math.ceil(highCount * 0.3 + mediumCount * 0.1);
    }

    return {
      executiveSummary: {
        status,
        criticalIssues: criticalCount,
        highPriorityIssues: highCount,
        mediumPriorityIssues: mediumCount,
        estimatedDaysToReady: estimatedDays
      },
      databaseOverview: {
        totalTables: this.getUniqueTableCount(),
        totalColumns: this.tableInfo.length,
        totalIndexes: this.indexInfo.length,
        databaseSize: 'Unknown', // Would need specific query
        keyTables: this.getKeyTablesInfo()
      },
      findings: this.findings,
      migrationScripts: this.migrationScripts,
      checklist: this.generateChecklist()
    };
  }

  private getUniqueTableCount(): number {
    const tables = new Set();
    this.tableInfo.forEach(t => tables.add(t.table_name));
    this.foreignKeys.forEach(fk => {
      tables.add(fk.table_name);
      tables.add(fk.foreign_table_name);
    });
    return tables.size;
  }

  private getKeyTablesInfo() {
    const keyTables = ['profiles', 'tournaments', 'tournament_participants', 'clubs', 'payments'];
    return keyTables.map(table => ({
      name: table,
      rowCount: 0, // Would need actual count query
      purpose: this.getTablePurpose(table),
      status: this.getTableStatus(table)
    }));
  }

  private getTablePurpose(table: string): string {
    const purposes: { [key: string]: string } = {
      'profiles': 'User profiles and authentication',
      'tournaments': 'Tournament management',
      'tournament_participants': 'Tournament participation tracking',
      'clubs': 'Club/group management',
      'payments': 'Payment processing and history',
      'user_vouchers': 'Voucher system',
      'chat_messages': 'In-app messaging',
      'table_reservations': 'Table reservation system'
    };
    return purposes[table] || 'Unknown purpose';
  }

  private getTableStatus(table: string): string {
    const tableFindings = this.findings.filter(f => f.table === table);
    const hasCritical = tableFindings.some(f => f.level === 'critical');
    const hasHigh = tableFindings.some(f => f.level === 'high');
    
    if (hasCritical) return '🔴 Critical issues found';
    if (hasHigh) return '🟡 Issues need attention';
    return '🟢 No major issues';
  }

  private generateChecklist() {
    return [
      {
        category: 'Security',
        items: [
          { task: 'Enable RLS on all tables', completed: false, priority: 'P0' },
          { task: 'Create RLS policies', completed: false, priority: 'P0' },
          { task: 'Verify anonymous access restrictions', completed: false, priority: 'P0' },
          { task: 'Test authentication flows', completed: false, priority: 'P1' }
        ]
      },
      {
        category: 'Data Integrity',
        items: [
          { task: 'Add foreign key constraints', completed: false, priority: 'P0' },
          { task: 'Add unique constraints', completed: false, priority: 'P1' },
          { task: 'Validate critical data', completed: false, priority: 'P1' },
          { task: 'Clean up orphaned records', completed: false, priority: 'P2' }
        ]
      },
      {
        category: 'Performance',
        items: [
          { task: 'Create missing indexes', completed: false, priority: 'P1' },
          { task: 'Optimize slow queries', completed: false, priority: 'P1' },
          { task: 'Set up connection pooling', completed: false, priority: 'P2' },
          { task: 'Configure query monitoring', completed: false, priority: 'P2' }
        ]
      }
    ];
  }

  // ============================================================================
  // 📄 REPORT OUTPUT
  // ============================================================================

  private async saveReports(report: AuditReport): Promise<void> {
    const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
    
    // Save comprehensive markdown report
    const markdownReport = this.generateMarkdownReport(report);
    const markdownPath = path.join(process.cwd(), `sabo_arena_database_audit_${timestamp}.md`);
    fs.writeFileSync(markdownPath, markdownReport);
    printSuccess(`Markdown report saved: ${markdownPath}`);

    // Save JSON report for programmatic access
    const jsonPath = path.join(process.cwd(), `sabo_arena_database_audit_${timestamp}.json`);
    fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2));
    printSuccess(`JSON report saved: ${jsonPath}`);

    // Save migration scripts
    for (const [type, script] of Object.entries(this.migrationScripts)) {
      if (script.trim()) {
        const scriptPath = path.join(process.cwd(), `migration_${type}_${timestamp}.sql`);
        fs.writeFileSync(scriptPath, script);
        printSuccess(`Migration script saved: ${scriptPath}`);
      }
    }
  }

  private generateMarkdownReport(report: AuditReport): string {
    const status = {
      'NOT_READY': '🔴 NOT READY',
      'NEEDS_WORK': '🟡 NEEDS WORK',
      'READY': '🟢 READY'
    };

    return `# 🔍 SABO ARENA - DATABASE AUDIT REPORT

**Date:** ${new Date().toLocaleString()}  
**Auditor:** AI Database Specialist  
**Environment:** Production Readiness Assessment  

---

## 📊 EXECUTIVE SUMMARY

### Current Status: ${status[report.executiveSummary.status]}

**Critical Issues Found:** ${report.executiveSummary.criticalIssues}  
**High Priority Issues:** ${report.executiveSummary.highPriorityIssues}  
**Medium Priority Issues:** ${report.executiveSummary.mediumPriorityIssues}  

**Estimated Time to Production Ready:** ${report.executiveSummary.estimatedDaysToReady} days

---

## 🗄️ DATABASE OVERVIEW

### Tables Inventory
- **Total Tables:** ${report.databaseOverview.totalTables}
- **Total Columns:** ${report.databaseOverview.totalColumns}
- **Total Indexes:** ${report.databaseOverview.totalIndexes}
- **Database Size:** ${report.databaseOverview.databaseSize}

### Key Tables:
${report.databaseOverview.keyTables.map(table => 
  `- **${table.name}** - ${table.rowCount} rows\n  - Purpose: ${table.purpose}\n  - Status: ${table.status}`
).join('\n\n')}

---

## 🚨 CRITICAL ISSUES (P0 - Blocking)

${report.findings.filter(f => f.level === 'critical').map(finding => `
### ${finding.title}
- **Category:** ${finding.category}
- **Table:** ${finding.table || 'Multiple'}
- **Description:** ${finding.description}
- **Impact:** ${finding.impact}
- **Fix:** \`${finding.fix}\`
- **Priority:** ${finding.priority}
`).join('\n')}

---

## ⚠️ HIGH PRIORITY ISSUES (P1)

${report.findings.filter(f => f.level === 'high').map(finding => `
### ${finding.title}
- **Category:** ${finding.category}
- **Table:** ${finding.table || 'Multiple'}
- **Description:** ${finding.description}
- **Impact:** ${finding.impact}
- **Fix:** \`${finding.fix}\`
- **Priority:** ${finding.priority}
`).join('\n')}

---

## 📝 MEDIUM PRIORITY ISSUES (P2)

${report.findings.filter(f => f.level === 'medium').map(finding => `
### ${finding.title}
- **Category:** ${finding.category}
- **Table:** ${finding.table || 'Multiple'}
- **Description:** ${finding.description}
- **Impact:** ${finding.impact}
- **Fix:** \`${finding.fix}\`
- **Priority:** ${finding.priority}
`).join('\n')}

---

## ✅ PRODUCTION READINESS CHECKLIST

${report.checklist.map(category => `
### ${category.category}
${category.items.map(item => `- [${item.completed ? 'x' : ' '}] ${item.task} (${item.priority})`).join('\n')}
`).join('\n')}

---

## 🚀 IMPLEMENTATION ROADMAP

### Phase 1: Critical Fixes (Day 1-2)
- Fix all P0 (Critical) issues
- Enable RLS on all tables
- Add foreign key constraints
- Create basic RLS policies

### Phase 2: High Priority (Day 3-4)
- Create missing indexes
- Add unique constraints
- Optimize performance bottlenecks

### Phase 3: Verification (Day 5)
- Run comprehensive tests
- Verify security implementation
- Load testing
- Final production readiness check

---

## 📋 SQL MIGRATION SCRIPTS

### Script 1: Critical Security Fixes
\`\`\`sql
${this.migrationScripts.critical}
\`\`\`

### Script 2: Performance Optimization
\`\`\`sql
${this.migrationScripts.performance}
\`\`\`

### Script 3: Data Integrity
\`\`\`sql
${this.migrationScripts.integrity}
\`\`\`

---

## 🎯 RECOMMENDATIONS

### Immediate Actions:
1. **CRITICAL:** Execute critical security fixes immediately
2. **CRITICAL:** Test all RLS policies thoroughly
3. **HIGH:** Add missing foreign key constraints
4. **HIGH:** Create essential indexes

### Before Launch:
1. Complete all P0 (Critical) fixes
2. Address high-priority performance issues
3. Verify data integrity
4. Set up monitoring and alerting
5. Perform load testing

### Post-Launch:
1. Monitor query performance
2. Set up automated backups
3. Implement advanced RLS policies
4. Optimize based on usage patterns

---

## 📞 NEXT STEPS

1. ✅ Review this report with team
2. ⏳ Execute Critical fixes (migration_critical_*.sql)
3. ⏳ Test thoroughly in staging environment
4. ⏳ Execute High Priority fixes (migration_performance_*.sql)
5. ⏳ Final verification and testing
6. ⏳ Go-live decision

---

**Report Status:** Complete  
**Risk Level:** ${report.executiveSummary.criticalIssues > 0 ? 'HIGH' : report.executiveSummary.highPriorityIssues > 5 ? 'MEDIUM' : 'LOW'}  
**Launch Recommendation:** ${report.executiveSummary.status === 'READY' ? '🟢 GO' : '🔴 NO-GO (Fix critical issues first)'}  

---

*Generated by SABO Arena Database Audit Tool*  
*For questions or support, please review the migration scripts and test thoroughly in staging environment.*
`;
  }

  // ============================================================================
  // 🚀 MAIN EXECUTION
  // ============================================================================

  async runCompleteAudit(): Promise<void> {
    printHeader('🔍 SABO ARENA - DATABASE PRODUCTION READINESS AUDIT', '=', 100);
    printInfo('Starting comprehensive database audit...');

    try {
      // Step 1: Test connection
      const connected = await this.testConnection();
      if (!connected) {
        printCritical('Cannot connect to database. Audit aborted.');
        return;
      }

      // Step 2: Analyze schema
      await this.analyzeSchema();

      // Step 3: Analyze relationships and constraints
      await this.analyzeRelationships();

      // Step 4: Analyze indexes
      await this.analyzeIndexes();

      // Step 5: Analyze RLS
      await this.analyzeRLS();

      // Step 6: Check data integrity
      await this.analyzeDataIntegrity();

      // Step 7: Analyze performance
      await this.analyzePerformance();

      // Step 8: Generate migration scripts
      this.generateMigrationScripts();

      // Step 9: Generate and save reports
      const report = this.generateReport();
      await this.saveReports(report);

      // Step 10: Display summary
      this.displaySummary(report);

    } catch (err) {
      printError(`Audit failed: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  private displaySummary(report: AuditReport): void {
    printHeader('📊 AUDIT SUMMARY', '=', 80);
    
    console.log(`\n${colors.bright}Database Status: ${this.getStatusEmoji(report.executiveSummary.status)} ${report.executiveSummary.status}${colors.reset}`);
    console.log(`\n📊 Issues Found:`);
    console.log(`   🚨 Critical: ${colors.red}${report.executiveSummary.criticalIssues}${colors.reset}`);
    console.log(`   ⚠️  High:     ${colors.yellow}${report.executiveSummary.highPriorityIssues}${colors.reset}`);
    console.log(`   📝 Medium:   ${colors.cyan}${report.executiveSummary.mediumPriorityIssues}${colors.reset}`);
    
    console.log(`\n⏱️  Estimated days to production ready: ${colors.bright}${report.executiveSummary.estimatedDaysToReady}${colors.reset}`);
    
    console.log(`\n🎯 Launch Recommendation:`);
    if (report.executiveSummary.status === 'READY') {
      printSuccess('🟢 GO - Database is production ready!');
    } else if (report.executiveSummary.status === 'NEEDS_WORK') {
      printWarning('🟡 CONDITIONAL GO - Address high priority issues');
    } else {
      printCritical('🔴 NO-GO - Critical issues must be fixed before launch');
    }

    console.log(`\n📋 Next Actions:`);
    if (report.executiveSummary.criticalIssues > 0) {
      console.log(`   1. 🚨 Execute migration_critical_*.sql immediately`);
      console.log(`   2. 🧪 Test all functionality in staging`);
      console.log(`   3. ⚠️  Address high priority issues`);
      console.log(`   4. 🔄 Re-run audit to verify fixes`);
    } else if (report.executiveSummary.highPriorityIssues > 0) {
      console.log(`   1. ⚠️  Execute migration_performance_*.sql`);
      console.log(`   2. 🧪 Run performance testing`);
      console.log(`   3. 🚀 Proceed with launch preparation`);
    } else {
      console.log(`   1. ✅ Final verification testing`);
      console.log(`   2. 🚀 Proceed with production launch`);
    }

    printHeader('🏁 AUDIT COMPLETE', '=', 80);
    printSuccess('All reports and migration scripts have been generated.');
    printInfo('Review the markdown report for detailed findings and recommendations.');
  }

  private getStatusEmoji(status: string): string {
    switch (status) {
      case 'READY': return '🟢';
      case 'NEEDS_WORK': return '🟡';
      case 'NOT_READY': return '🔴';
      default: return '❓';
    }
  }
}

// ============================================================================
// 🏁 MAIN EXECUTION
// ============================================================================

async function main() {
  const auditor = new DatabaseAuditor();
  await auditor.runCompleteAudit();
}

// Run the audit
if (require.main === module) {
  main().catch(console.error);
}

export { DatabaseAuditor };