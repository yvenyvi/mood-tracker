import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, setDoc, collection, addDoc, Timestamp } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyBSo4l_JgMraHQOa446B9AefmYUXFWAmoU',
  appId: '1:307923968626:web:693fc3b0e558301ab198eb',
  projectId: 'emote-3df9d',
  authDomain: 'emote-3df9d.firebaseapp.com'
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function run() {
  try {
    console.log("Signing in...");
    const userCredential = await signInWithEmailAndPassword(auth, 'uylancejr@gmail.com', 'Password1!');
    const uid = userCredential.user.uid;
    console.log("Signed in successfully. UID:", uid);

    const userRef = doc(db, 'users', uid);
    
    console.log("Updating user profile document...");
    await setDoc(userRef, {
      displayName: 'Lance Uy',
      email: 'uylancejr@gmail.com',
      uid: uid
    }, { merge: true });

    console.log("Adding mock mood entries...");
    const moodsRef = collection(userRef, 'moods');
    
    const now = new Date();
    const oneDay = 24 * 60 * 60 * 1000;

    const mockEntries = [
      {
        mood: 'Joyful',
        intensity: 8,
        note: 'Had a wonderful time hiking with friends today. The weather was perfect!',
        emotions: ['Joy', 'Excitement', 'Gratitude'],
        coping_strategies: ['Exercised', 'Socialized'],
        physical_symptoms: ['Energetic'],
        timestamp: Timestamp.fromDate(new Date(now.getTime() - 1 * oneDay))
      },
      {
        mood: 'Calm',
        intensity: 5,
        note: 'A quiet, productive afternoon reading and listening to music.',
        emotions: ['Relaxed', 'Content'],
        coping_strategies: ['Meditation', 'Reading'],
        physical_symptoms: ['Rested'],
        timestamp: Timestamp.fromDate(new Date(now.getTime() - 2 * oneDay))
      },
      {
        mood: 'Stressed',
        intensity: 7,
        note: 'Felt overwhelmed with the upcoming project deadline at work.',
        emotions: ['Anxiety', 'Overwhelmed'],
        coping_strategies: ['Deep Breathing', 'Took a Walk'],
        physical_symptoms: ['Headache', 'Tense shoulders'],
        timestamp: Timestamp.fromDate(new Date(now.getTime() - 3 * oneDay))
      },
      {
        mood: 'Motivated',
        intensity: 9,
        note: 'Woke up early and finished my entire to-do list by noon!',
        emotions: ['Inspired', 'Confident'],
        coping_strategies: ['Planning', 'Exercised'],
        physical_symptoms: ['Energetic'],
        timestamp: Timestamp.fromDate(new Date(now.getTime() - 4 * oneDay))
      },
      {
        mood: 'Tired',
        intensity: 6,
        note: 'Did not get much sleep last night, feeling a bit sluggish.',
        emotions: ['Exhaustion', 'Apathy'],
        coping_strategies: ['Resting', 'Drank water'],
        physical_symptoms: ['Fatigue'],
        timestamp: Timestamp.fromDate(new Date(now.getTime() - 5 * oneDay))
      }
    ];

    for (const entry of mockEntries) {
      await addDoc(moodsRef, entry);
    }

    console.log(`Successfully added ${mockEntries.length} mock data entries for ${uid}!`);
    process.exit(0);
  } catch (error) {
    console.error("Error:", error);
    process.exit(1);
  }
}

run();
