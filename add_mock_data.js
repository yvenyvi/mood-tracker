const admin = require('firebase-admin');

// Ensure you run this with valid credentials or after `firebase login` if it supports it.
// Typically for admin SDK, you'll need a service account key or Application Default Credentials.
// Typically for admin SDK, you'll need Application Default Credentials.
admin.initializeApp({
  projectId: 'emote-3df9d',
});

const db = admin.firestore();

async function addMockData() {
  try {
    const userRef = db.collection('users').doc('mock_user_123');
    const userRef = db.collection('users').doc('mock_user_alex');
    
    console.log("Adding mock user document...");
    await userRef.set({
      displayName: 'Mock User',
      email: 'mock@example.com',
      uid: 'mock_user_123'
      displayName: 'Alex Taylor',
      email: 'alex.taylor@example.com',
      uid: 'mock_user_alex'
    });

    console.log("Adding mock mood entries...");
    const moodsRef = userRef.collection('moods');
    
    await moodsRef.add({
      mood: 'Happy',
      intensity: 8,
      note: 'Feeling great today!',
      emotions: ['Joy', 'Excitement'],
      coping_strategies: ['Exercised'],
      physical_symptoms: ['Energetic'],
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    const now = new Date();
    const oneDay = 24 * 60 * 60 * 1000;

    await moodsRef.add({
      mood: 'Calm',
      intensity: 5,
      note: 'A peaceful afternoon.',
      emotions: ['Relaxed', 'Content'],
      coping_strategies: ['Meditation'],
      physical_symptoms: [],
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
    const mockEntries = [
      {
        mood: 'Joyful',
        intensity: 8,
        note: 'Had a wonderful time hiking with friends today. The weather was perfect!',
        emotions: ['Joy', 'Excitement', 'Gratitude'],
        coping_strategies: ['Exercised', 'Socialized'],
        physical_symptoms: ['Energetic'],
        timestamp: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 1 * oneDay))
      },
      {
        mood: 'Calm',
        intensity: 5,
        note: 'A quiet, productive afternoon reading and listening to music.',
        emotions: ['Relaxed', 'Content'],
        coping_strategies: ['Meditation', 'Reading'],
        physical_symptoms: ['Rested'],
        timestamp: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 2 * oneDay))
      },
      {
        mood: 'Stressed',
        intensity: 7,
        note: 'Felt overwhelmed with the upcoming project deadline at work.',
        emotions: ['Anxiety', 'Overwhelmed'],
        coping_strategies: ['Deep Breathing', 'Took a Walk'],
        physical_symptoms: ['Headache', 'Tense shoulders'],
        timestamp: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 3 * oneDay))
      },
      {
        mood: 'Motivated',
        intensity: 9,
        note: 'Woke up early and finished my entire to-do list by noon!',
        emotions: ['Inspired', 'Confident'],
        coping_strategies: ['Planning', 'Exercised'],
        physical_symptoms: ['Energetic'],
        timestamp: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 4 * oneDay))
      },
      {
        mood: 'Tired',
        intensity: 6,
        note: 'Didn\'t get much sleep last night, feeling a bit sluggish.',
        emotions: ['Exhaustion', 'Apathy'],
        coping_strategies: ['Resting', 'Drank water'],
        physical_symptoms: ['Fatigue'],
        timestamp: admin.firestore.Timestamp.fromDate(new Date(now.getTime() - 5 * oneDay))
      }
    ];

    console.log("Successfully added mock data!");
    for (const entry of mockEntries) {
      await moodsRef.add(entry);
    }

    console.log(`Successfully added ${mockEntries.length} mock data entries for Alex Taylor!`);
  } catch (error) {
    console.error("Error adding mock data: ", error);
  }
}

addMockData();
