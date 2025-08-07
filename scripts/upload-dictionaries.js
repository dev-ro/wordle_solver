#!/usr/bin/env node

/**
 * Script to upload dictionary files to Firebase Storage
 * This can be run locally or in CI/CD pipelines
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'wordle-solver-kyle',
    storageBucket: 'wordle-solver-kyle.appspot.com'
  });
}

const bucket = admin.storage().bucket();

async function uploadDictionaries() {
  const dictionariesDir = path.join(__dirname, '..', 'assets', 'words');
  
  try {
    console.log('📁 Reading dictionary files from:', dictionariesDir);
    
    const files = fs.readdirSync(dictionariesDir)
      .filter(file => file.endsWith('.json'));
    
    if (files.length === 0) {
      console.log('⚠️ No dictionary files found');
      return;
    }
    
    console.log(`📚 Found ${files.length} dictionary files:`, files);
    
    for (const file of files) {
      const localPath = path.join(dictionariesDir, file);
      const remotePath = `dictionaries/${file}`;
      
      console.log(`⬆️ Uploading ${file}...`);
      
      // Validate JSON before upload
      const content = fs.readFileSync(localPath, 'utf8');
      try {
        const parsed = JSON.parse(content);
        if (!Array.isArray(parsed)) {
          throw new Error('Dictionary must be an array of words');
        }
        console.log(`✅ ${file} is valid JSON with ${parsed.length} words`);
      } catch (error) {
        console.error(`❌ ${file} is invalid:`, error.message);
        continue;
      }
      
      // Upload to Firebase Storage
      await bucket.upload(localPath, {
        destination: remotePath,
        metadata: {
          contentType: 'application/json',
          metadata: {
            uploadedAt: new Date().toISOString(),
            source: 'automated-upload'
          }
        }
      });
      
      console.log(`✅ Uploaded ${file} to ${remotePath}`);
    }
    
    console.log('🎉 All dictionaries uploaded successfully!');
    
    // List files in the dictionaries folder
    console.log('\n📋 Files in Cloud Storage:');
    const [storageFiles] = await bucket.getFiles({
      prefix: 'dictionaries/'
    });
    
    storageFiles.forEach(file => {
      console.log(`  - ${file.name}`);
    });
    
  } catch (error) {
    console.error('❌ Upload failed:', error);
    process.exit(1);
  }
}

// Run the upload
uploadDictionaries()
  .then(() => {
    console.log('✅ Dictionary upload completed');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Dictionary upload failed:', error);
    process.exit(1);
  });
