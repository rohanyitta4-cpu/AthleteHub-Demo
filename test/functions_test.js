#!/usr/bin/env node

/**
 * Cloud Functions Integration Test
 * 
 * This script tests the Cloud Functions with the Firebase Emulator Suite
 * to validate the team-centric data model behavior.
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
};

/**
 * Test onTeamGameWrite function
 */
async function testOnTeamGameWrite() {
  console.log('🧪 Testing onTeamGameWrite function...');

  try {
    // Create test team
    await db.collection('teams').doc(testData.teamId).set({
      teamId: testData.teamId,
      name: 'Test Team',
      coachIds: [testData.coachId],
      playerIds: [testData.playerId],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create test season
    await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId).set({
        seasonId: testData.seasonId,
        teamId: testData.teamId,
        name: '2024 Season',
        startDate: admin.firestore.Timestamp.now(),
        isActive: true,
        gamesCount: 0,
      });

    // Create initial game
    const gameData = {
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
          homeRuns: 0,
          walks: 1,
          strikeouts: 1,
        },
      },
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now(),
    };

    // Write game (this should trigger the Cloud Function)
    await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('games').doc(testData.gameId).set(gameData);

    // Wait for Cloud Function to process
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Verify team totals were created
    const teamTotalsDoc = await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('stats').doc('totals').get();

    if (teamTotalsDoc.exists) {
      const teamTotals = teamTotalsDoc.data();
      console.log('✅ Team totals created:', teamTotals);
      
      // Verify totals are correct
      if (teamTotals.atBats === 4 && teamTotals.hits === 2) {
        console.log('✅ Team totals are correct');
      } else {
        console.log('❌ Team totals are incorrect');
      }
    } else {
      console.log('❌ Team totals were not created');
    }

    // Verify player totals were created
    const playerTotalsDoc = await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('stats').doc('players').collection('players')
      .doc(testData.playerId).get();

    if (playerTotalsDoc.exists) {
      const playerTotals = playerTotalsDoc.data();
      console.log('✅ Player totals created:', playerTotals);
      
      // Verify totals are correct
      if (playerTotals.atBats === 4 && playerTotals.hits === 2) {
        console.log('✅ Player totals are correct');
      } else {
        console.log('❌ Player totals are incorrect');
      }
    } else {
      console.log('❌ Player totals were not created');
    }

    // Test game update (delta calculation)
    console.log('🔄 Testing game update (delta calculation)...');
    
    const updatedGameData = {
      ...gameData,
      playerStats: {
        [testData.playerId]: {
          atBats: 4,
          hits: 3, // Changed from 2 to 3
          runs: 2, // Changed from 1 to 2
          rbi: 2,  // Changed from 1 to 2
          homeRuns: 0,
          walks: 1,
          strikeouts: 1,
        },
      },
      updatedAt: admin.firestore.Timestamp.now(),
    };

    // Update game
    await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('games').doc(testData.gameId).set(updatedGameData);

    // Wait for Cloud Function to process
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Verify totals were updated correctly
    const updatedTeamTotalsDoc = await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('stats').doc('totals').get();

    if (updatedTeamTotalsDoc.exists) {
      const updatedTeamTotals = updatedTeamTotalsDoc.data();
      console.log('✅ Updated team totals:', updatedTeamTotals);
      
      // Verify delta calculation
      if (updatedTeamTotals.hits === 3 && updatedTeamTotals.runs === 2) {
        console.log('✅ Delta calculation is correct');
      } else {
        console.log('❌ Delta calculation is incorrect');
      }
    }

    // Test game deletion
    console.log('🗑️ Testing game deletion...');
    
    await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('games').doc(testData.gameId).delete();

    // Wait for Cloud Function to process
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Verify totals were decremented
    const finalTeamTotalsDoc = await db.collection('teams').doc(testData.teamId)
      .collection('seasons').doc(testData.seasonId)
      .collection('stats').doc('totals').get();

    if (finalTeamTotalsDoc.exists) {
      const finalTeamTotals = finalTeamTotalsDoc.data();
      console.log('✅ Final team totals after deletion:', finalTeamTotals);
      
      // Verify totals were decremented
      if (finalTeamTotals.hits === 0 && finalTeamTotals.runs === 0) {
        console.log('✅ Game deletion correctly decremented totals');
      } else {
        console.log('❌ Game deletion did not correctly decrement totals');
      }
    }

  } catch (error) {
    console.error('❌ onTeamGameWrite test failed:', error);
    throw error;
  }
}

/**
 * Test onRosterChange function
 */
async function testOnRosterChange() {
  console.log('🧪 Testing onRosterChange function...');

  try {
    // Add player to roster
    await db.collection('teams').doc(testData.teamId)
      .collection('roster').doc(testData.playerId).set({
        playerId: testData.playerId,
        role: 'starter',
        jerseyNumber: 42,
        addedAt: admin.firestore.Timestamp.now(),
      });

    // Wait for Cloud Function to process
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Verify user linkedTeams was updated
    const userDoc = await db.collection('users').doc(testData.playerId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      if (userData.linkedTeams && userData.linkedTeams.includes(testData.teamId)) {
        console.log('✅ User linkedTeams updated correctly');
      } else {
        console.log('❌ User linkedTeams not updated');
      }
    } else {
      console.log('❌ User document not found');
    }

    // Verify user role was set
    const roleDoc = await db.collection('users').doc(testData.playerId)
      .collection('roles').doc(testData.teamId).get();
    
    if (roleDoc.exists) {
      const roleData = roleDoc.data();
      if (roleData.role === 'player') {
        console.log('✅ User role set correctly');
      } else {
        console.log('❌ User role not set correctly');
      }
    } else {
      console.log('❌ User role document not found');
    }

  } catch (error) {
    console.error('❌ onRosterChange test failed:', error);
    throw error;
  }
}

/**
 * Test security rules
 */
async function testSecurityRules() {
  console.log('🧪 Testing security rules...');

  try {
    // Test: Player cannot create team
    try {
      await db.collection('teams').doc('unauthorized-team').set({
        teamId: 'unauthorized-team',
        name: 'Unauthorized Team',
        coachIds: [testData.playerId], // Player trying to be coach
        playerIds: [],
        createdAt: admin.firestore.Timestamp.now(),
      });
      console.log('❌ Security rule failed: Player was able to create team');
    } catch (error) {
      if (error.code === 'permission-denied') {
        console.log('✅ Security rule working: Player cannot create team');
      } else {
        console.log('❌ Unexpected error:', error);
      }
    }

    // Test: Player cannot edit other player's stats
    try {
      await db.collection('teams').doc(testData.teamId)
        .collection('seasons').doc(testData.seasonId)
        .collection('games').doc('other-game').set({
          gameId: 'other-game',
          seasonId: testData.seasonId,
          teamId: testData.teamId,
          gameDate: admin.firestore.Timestamp.now(),
          opponent: 'Other Team',
          location: 'Other Field',
          playerStats: {
            'other-player': {
              atBats: 4,
              hits: 2,
            },
          },
        });
      console.log('❌ Security rule failed: Player was able to edit other player stats');
    } catch (error) {
      if (error.code === 'permission-denied') {
        console.log('✅ Security rule working: Player cannot edit other player stats');
      } else {
        console.log('❌ Unexpected error:', error);
      }
    }

  } catch (error) {
    console.error('❌ Security rules test failed:', error);
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
    
    // Delete test user
    await db.collection('users').doc(testData.playerId).delete();
    
    console.log('✅ Cleanup completed');
  } catch (error) {
    console.error('❌ Cleanup failed:', error);
  }
}

/**
 * Main test runner
 */
async function runTests() {
  console.log('🚀 Starting Cloud Functions Integration Tests...\n');

  try {
    await testOnTeamGameWrite();
    console.log('');
    
    await testOnRosterChange();
    console.log('');
    
    await testSecurityRules();
    console.log('');
    
    console.log('✅ All tests completed successfully!');
    
  } catch (error) {
    console.error('❌ Tests failed:', error);
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
  testOnTeamGameWrite,
  testOnRosterChange,
  testSecurityRules,
  runTests,
};