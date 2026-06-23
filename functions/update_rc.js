const admin = require('firebase-admin');

// Initialize the app with a service account, granting admin privileges
admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

async function updateConfig() {
  try {
    const rc = admin.remoteConfig();
    const template = await rc.getTemplate();
    
    template.parameters['min_app_version'] = {
      defaultValue: { value: '1.4.3' },
      valueType: 'STRING'
    };
    
    await rc.publishTemplate(template);
    console.log('Successfully published template!');
  } catch (error) {
    console.error('Error publishing template:', error);
  }
}

updateConfig();
