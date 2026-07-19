exports.handler = async (event, context) => {
  // CORS Preflight
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      },
      body: ''
    };
  }

  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method Not Allowed' })
    };
  }

  try {
    const { number, message, patientId, patientName } = JSON.parse(event.body);
    const apiKey = process.env.FAST2SMS_API_KEY || 'MYPmNuvQ7hsw9324dSBeyUGrapDCKEi08obxjJ5VFqZfgAzc1RIYzXd0aM4UeLJDV2ET5ntuFcosWvgx';

    console.log(`[Netlify Function] Sending SMS to ${number}...`);

    const response = await fetch('https://www.fast2sms.com/dev/bulkV2', {
      method: 'POST',
      headers: {
        'authorization': apiKey,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        route: 'q',
        message: message,
        language: 'english',
        numbers: number
      })
    });

    const status = response.status;
    const responseData = await response.json();
    console.log(`[Netlify Function] Fast2SMS response:`, responseData);

    if (responseData.return === true) {
      try {
        const projectId = "ehr-companion-for-asha";
        const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/sms_delivery_logs`;
        const firestoreBody = {
          fields: {
            patientId: { stringValue: patientId || 'N/A' },
            patientName: { stringValue: patientName || 'N/A' },
            phoneNumber: { stringValue: number },
            message: { stringValue: message },
            messageId: { stringValue: responseData.request_id || 'N/A' },
            deliveryStatus: { stringValue: 'dispatched' },
            timestamp: { stringValue: new Date().toISOString() }
          }
        };

        const fRes = await fetch(firestoreUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(firestoreBody)
        });
        console.log(`[Netlify Function] Firestore logged status: ${fRes.status}`);
      } catch (fsErr) {
        console.error('[Netlify Function] Firestore logging failed:', fsErr);
      }
    }

    return {
      statusCode: status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(responseData)
    };
  } catch (err) {
    console.error('[Netlify Function] Server error:', err);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: err.message })
    };
  }
};
