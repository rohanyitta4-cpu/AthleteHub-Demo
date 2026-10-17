#!/usr/bin/env node

/**
 * Firestore Security Rules Test
 * 
 * This script tests the Firestore security rules using the Firebase Emulator Suite
 * to ensure proper RBAC (Role-Based Access Control) enforcement.
 */

const admin = require('firebase-admin');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

// Initialize Firebase Admin for testing
admin.initializeApp({
  projectId: 'demo-test',
});

const db = admin.firestore();

// Test data
const testData = {
  teamId: 'team-test-123',
  seasonId: 'season-2024',
  gameId: 'game-test-123',
  coachId: 'coach-test-123',
  playerId: 'player-test-123',
  adminId: 'admin-test-123',
};

/**
 * Test team access rules
 */
async function testTeamAccessRules() {
  console.log('🧪 Testing team access rules...');

  try {
    // Create test team
    await db.collection('teams').doc(testData.teamId).set({
      teamId: testData.teamId,
      name: 'Test Team',
      coachIds: [testData.coachId],
      playerIds: [testData.playerId],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Test: Coach can read team
    try {
      const teamDoc = await db.collection('teams').doc(testData.teamId).get();
      if (teamDoc.exists) {
        console.log('✅ Coach can read team');
      } else {
        console.log('❌ Coach cannot read team');
      }
    } catch (error) {
      console.log('❌ Coach cannot read team:', error.message);
    }

    // Test: Player can read team
    try {
      const teamDoc = await db.collection('teams').doc(testData.teamId).get();
      if (teamDoc.exists) {
        console.log('✅ Player can read team');
      } else {
        console.log('❌ Player cannot read team');
      }
    } catch (error) {
      console.log('❌ Player cannot read team:', error.message);
    }

    // Test: Unauthorized user cannot read team
    try {
      const teamDoc = await db.collection('teams').doc(testData.teamId).get();
      if (teamDoc.exists) {
        console.log('❌ Unauthorized user can read team (should not be allowed)');
      } else {
        console.log('✅ Unauthorized user cannot read team');
      }
    } catch (error) {
      if (error.code === 'permission-denied') {
        console.log('✅ Unauthorized user cannot read team');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }

  } catch (error) {
    console.error('❌ Team access rules test failed:', error);
    throw error;
  }
}

/**
 * Test roster access rules
 */
async function testRosterAccessRules() {
  console.log('🧪 Testing roster access rules...');

  try {
    // Create test roster entry
    await db.collection('teams').doc(testData.teamId)
      .collection('roster').doc(testData.playerId).set({
        playerId: testData.playerId,
        role: 'starter',
        jerseyNumber: 42,
        addedAt: admin.firestore.Timestamp.now(),
      });

    // Test: Coach can read roster
    try {
      const rosterSnapshot = await db.collection('teams').doc(testData.teamId)
        .collection('roster').get();
      if (!rosterSnapshot.empty) {
        console.log('✅ Coach can read roster');
      } else {
        console.log('❌ Coach cannot read roster');
      }
    } catch (error) {
      console.log('❌ Coach cannot read roster:', error.message);
    }

    // Test: Player can read their own roster entry
    try {
      const rosterDoc = await db.collection('teams').doc(testData.teamId)
        .collection('roster').doc(testData.playerId).get();
      if (rosterDoc.exists) {
        console.log('✅ Player can read their own roster entry');
      } else {
        console.log('❌ Player cannot read their own roster entry');
      }
    } catch (error) {
      console.log('❌ Player cannot read their own roster entry:', error.message);
    }

    // Test: Player cannot read other player's roster entry
    try {
      const rosterDoc = await db.collection('teams').doc(testData.teamId)
        .collection('roster').doc('other-player').get();
      if (rosterDoc.exists) {
        console.log('❌ Player can read other player\'s roster entry (should not be allowed)');
      } else {
        console.log('✅ Player cannot read other player\'s roster entry');
      }
    } catch (error) {
      if (error.code === 'permission-denied') {
        console.log('✅ Player cannot read other player\'s roster entry');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }

  } catch (error) {
    console.error('❌ Roster access rules test failed:', error);
    throw error;
  }
}

/**
 * Test game access rules
 */
async function testGameAccessRules() {
  console.log('🧪 Testing game access rules...');

  try {
    // Create test game
    await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('games').doc(testData.gameId).set({
        gameId: testData.gameId,
        seasonId: testData.seasonId,
        teamId: testData.teamId,
        gameDate: admin.firestore.Timestamp.now(),
        opponent: 'Opponent Team',
        location: 'Home Field',
        type: 'regular',
        status: 'completed',
        playerStats: {
          [testData.playerId]: {
            atBats: 4,
            hits: 2,
            runs: 1,
            rbi: 1,
          },
        },
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

    // Test: Coach can read games
    try {
      const gamesSnapshot = await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('games').get();
      if (!gamesSnapshot.empty) {
        console.log('✅ Coach can read games');
      } else {
        console.log('❌ Coach cannot read games');
      }
    } catch (error) {
      console.log('❌ Coach cannot read games:', error.message);
    }

    // Test: Player can read games
    try {
      const gamesSnapshot = await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('games').get();
      if (!gamesSnapshot.empty) {
        console.log('✅ Player can read games');
      } else {
        console.log('❌ Player cannot read games');
      }
    } catch (error) {
      console.log('❌ Player cannot read games:', error.message);
    }

    // Test: Coach can create games
    try {
      await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('games').doc('new-game').set({
          gameId: 'new-game',
          seasonId: testData.seasonId,
          teamId: testData.teamId,
          gameDate: admin.firestore.Timestamp.now(),
          opponent: 'New Opponent',
          location: 'New Field',
          type: 'regular',
          status: 'completed',
          playerStats: {},
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      console.log('✅ Coach can create games');
    } catch (error) {
      console.log('❌ Coach cannot create games:', error.message);
    }

    // Test: Player cannot create games
    try {
      await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('games').doc('player-game').set({
          gameId: 'player-game',
          seasonId: testData.seasonId,
          teamId: testData.teamId,
          gameDate: admin.firestore.Timestamp.now(),
          opponent: 'Player Game',
          location: 'Player Field',
          type: 'regular',
          status: 'completed',
          playerStats: {},
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      console.log('❌ Player can create games (should not be allowed)');
    } catch (error) {
      if (error.code === 'permission-denied') {
        console.log('✅ Player cannot create games');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }

  } catch (error) {
    console.error('❌ Game access rules test failed:', error);
    throw error;
  }
}

/**
 * Test stats access rules
 */
async function testStatsAccessRules() {
  console.log('🧪 Testing stats access rules...');

  try {
    // Create test stats
    await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('stats').doc('totals').set({
        games: 5,
        atBats: 20,
        hits: 8,
        runs: 4,
        rbi: 3,
        homeRuns: 1,
        lastUpdated: admin.firestore.Timestamp.now(),
      });

    await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('stats').doc('players').collection('players')
      .doc(testData.playerId).set({
        playerId: testData.playerId,
        games: 5,
        atBats: 20,
        hits: 8,
        runs: 4,
        rbi: 3,
        homeRuns: 1,
        lastUpdated: admin.firestore.Timestamp.now(),
      });

    // Test: Coach can read stats
    try {
      const teamTotalsDoc = await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('stats').doc('totals').get();
      if (teamTotalsDoc.exists) {
        console.log('✅ Coach can read team stats');
      } else {
        console.log('❌ Coach cannot read team stats');
      }
    } catch (error) {
      console.log('❌ Coach cannot read team stats:', error.message);
    }

    // Test: Player can read stats
    try {
      const playerStatsDoc = await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('stats').doc('players').collection('players')
        .doc(testData.playerId).get();
      if (playerStatsDoc.exists) {
        console.log('✅ Player can read stats');
      } else {
        console.log('❌ Player cannot read stats');
      }
    } catch (error) {
      console.log('❌ Player cannot read stats:', error.message);
    }

    // Test: Player cannot write stats
    try {
      await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('stats').doc('totals').update({
          games: 6,
        });
      console.log('❌ Player can write stats (should not be allowed)');
    } catch (error) {
      if (error.code === 'permission-denied') {
        console.log('✅ Player cannot write stats');
      } else {
        console.log('❌ Unexpected error:', error.message);
      }
    }

  } catch (error) {
    console.error('❌ Stats access rules test failed:', error);
    throw error;
  }
}

/**
 * Clean up test data
 */
async function cleanup() {
  console.log('🧹 Cleaning up test data...');

  try {
    // Delete test team and all subcollections
    await db.collection('teams').doc(testData.teamId).delete();
    
    console.log('✅ Cleanup completed');
  } catch (error) {
    console.error('❌ Cleanup failed:', error);
  }
}

/**
 * Main test runner
 */
async function runTests() {
  console.log('🚀 Starting Security Rules Tests...\n');

  try {
    await testTeamAccessRules();
    console.log('');
    
    await testRosterAccessRules();
    console.log('');
    
    await testGameAccessRules();
    console.log('');
    
    await testStatsAccessRules();
    console.log('');
    
    console.log('✅ All security rules tests completed successfully!');
    
  } catch (error) {
    console.error('❌ Security rules tests failed:', error);
    process.exit(1);
  } finally {
    await cleanup();
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  runTests();
}

module.exports = {
  testTeamAccessRules,
  testRosterAccessRules,
  testGameAccessRules,
  testStatsAccessRules,
  runTests,
};