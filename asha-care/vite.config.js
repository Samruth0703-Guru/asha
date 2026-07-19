import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import fs from 'fs'
import path from 'path'

// Helper to read FAST2SMS_API_KEY from .env
function getApiKey() {
  try {
    const envPath = path.resolve(__dirname, '../.env');
    if (fs.existsSync(envPath)) {
      const content = fs.readFileSync(envPath, 'utf-8');
      const match = content.match(/FAST2SMS_API_KEY\s*=\s*([^\n\r]+)/);
      if (match) {
        return match[1].trim();
      }
    }
  } catch (e) {
    console.error('Error reading API key:', e);
  }
  return '';
}

export default defineConfig({
  plugins: [
    react(),
    {
      name: 'sms-proxy',
      configureServer(server) {
        server.middlewares.use('/api/send-sms', async (req, res, next) => {
          if (req.method !== 'POST') {
            res.statusCode = 405;
            res.end(JSON.stringify({ error: 'Method Not Allowed' }));
            return;
          }

          let body = '';
          req.on('data', chunk => {
            body += chunk;
          });

          req.on('end', async () => {
            res.setHeader('Content-Type', 'application/json');
            try {
              const { number, message, patientId, patientName } = JSON.parse(body);
              const apiKey = getApiKey();

              if (!apiKey) {
                res.statusCode = 401;
                res.end(JSON.stringify({ 
                  return: false, 
                  message: 'Invalid API Key - FAST2SMS_API_KEY not configured in .env' 
                }));
                return;
              }

              console.log(`[SMS PROXY] Sending real SMS to ${number}...`);

              const fast2smsResponse = await fetch('https://www.fast2sms.com/dev/bulkV2', {
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

              const status = fast2smsResponse.status;
              const responseData = await fast2smsResponse.json();

              console.log(`[SMS PROXY] Fast2SMS Status: ${status}`, responseData);

              // Save the delivery log into Firestore via REST API if success
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

                  const fResponse = await fetch(firestoreUrl, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(firestoreBody)
                  });
                  console.log(`[SMS PROXY] Firestore Log Status: ${fResponse.status}`);
                } catch (fsErr) {
                  console.error('[SMS PROXY] Firestore logging failed:', fsErr);
                }
              }

              res.statusCode = status;
              res.end(JSON.stringify(responseData));
            } catch (err) {
              console.error('[SMS PROXY] Server error:', err);
              res.statusCode = 500;
              res.end(JSON.stringify({ 
                return: false, 
                message: err.message || 'Internal Server Error' 
              }));
            }
          });
        });
      }
    }
  ]
})
