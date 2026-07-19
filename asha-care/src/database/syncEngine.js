// ─── ASHA CARE+ Offline Sync Engine ──────────────────────────────────────────
// Handles network status detection, local caching, request queueing,
// and background replay with timestamp-based conflict resolution.
// ─────────────────────────────────────────────────────────────────────────────

import { getStoredFamilies, saveFamilies } from './mockData';

let syncStatus = navigator.onLine ? 'synced' : 'offline'; // 'online' | 'offline' | 'syncing' | 'synced'
const listeners = new Set();

export const getSyncStatus = () => syncStatus;

export const getPendingQueue = () => {
  try {
    return JSON.parse(localStorage.getItem('pending_sync_queue') || '[]');
  } catch (e) {
    return [];
  }
};

const savePendingQueue = (queue) => {
  localStorage.setItem('pending_sync_queue', JSON.stringify(queue));
  window.dispatchEvent(new CustomEvent('asha_sync_status_changed', { detail: { status: syncStatus, pending: queue.length } }));
};

export const getPendingCount = () => getPendingQueue().length;

export const addSyncStatusListener = (cb) => {
  listeners.add(cb);
  cb(syncStatus, getPendingCount());
  return () => listeners.delete(cb);
};

const notifyListeners = () => {
  const count = getPendingCount();
  listeners.forEach(cb => cb(syncStatus, count));
  window.dispatchEvent(new CustomEvent('asha_sync_status_changed', { detail: { status: syncStatus, pending: count } }));
};

export const updateSyncStatus = (newStatus) => {
  if (syncStatus !== newStatus) {
    syncStatus = newStatus;
    notifyListeners();
  }
};

// Queue an action to be executed when online
export const queueSyncItem = (item) => {
  const queue = getPendingQueue();
  const newItem = {
    id: Date.now().toString() + Math.random().toString(36).substring(2, 5),
    timestamp: Date.now(),
    ...item
  };
  queue.push(newItem);
  savePendingQueue(queue);
  
  // Show notification
  showToastNotification('✅ Saved Offline Successfully', 'info');
  
  if (navigator.onLine) {
    triggerSync();
  }
};

// Custom toast notification system
export const showToastNotification = (message, type = 'info') => {
  const event = new CustomEvent('asha_toast_notification', { detail: { message, type } });
  window.dispatchEvent(event);
};

// Conflict Resolution: Compares local and remote family records.
// Overwrites if remote is newer, or uploads if local is newer.
const resolveFamilyConflict = async (famId, localFam) => {
  const FIRESTORE_PROJECT = "ehr-companion-for-asha";
  const url = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT}/databases/(default)/documents/families/${famId}`;
  
  try {
    const response = await fetch(url);
    if (response.status === 404) {
      // Doesn't exist on remote yet, upload it
      return 'upload';
    }
    if (!response.ok) return 'skip';

    const doc = await response.json();
    const remoteMembers = JSON.parse(doc.fields.members?.stringValue || '[]');
    
    // Find highest lastUpdated timestamp on remote and local
    const getNewestTime = (members) => {
      let newest = 0;
      members.forEach(m => {
        const t = m.lastUpdated || 0;
        if (t > newest) newest = t;
        if (m.pregnancyDetails?.lastUpdated > newest) newest = m.pregnancyDetails.lastUpdated;
      });
      return newest;
    };

    const localTime = getNewestTime(localFam.members);
    const remoteTime = getNewestTime(remoteMembers);

    if (remoteTime > localTime) {
      // Remote is newer, update local storage
      const families = getStoredFamilies();
      const updated = families.map(f => {
        if (f.id === famId) {
          return {
            ...f,
            name: doc.fields.name?.stringValue || f.name,
            address: doc.fields.address?.stringValue || f.address,
            phone: doc.fields.phone?.stringValue || f.phone,
            members: remoteMembers
          };
        }
        return f;
      });
      localStorage.setItem("asha_families", JSON.stringify(updated));
      window.dispatchEvent(new CustomEvent('asha_data_changed', { detail: { timestamp: Date.now() } }));
      return 'overwritten';
    }
    return 'upload';
  } catch (err) {
    console.error('[Sync Engine] Error during conflict check:', err);
    return 'upload'; // Fallback to upload
  }
};

// Process the queue when connection is active
export const triggerSync = async () => {
  if (!navigator.onLine || getPendingCount() === 0 || syncStatus === 'syncing') {
    return;
  }

  updateSyncStatus('syncing');
  showToastNotification('🔄 Synchronizing Data...', 'info');

  const queue = getPendingQueue();
  const remaining = [];
  const FIRESTORE_PROJECT = "ehr-companion-for-asha";

  for (const item of queue) {
    try {
      if (item.type === 'saveFamily') {
        const { familyId, familyData } = item.payload;
        
        // Conflict resolution step
        const resolution = await resolveFamilyConflict(familyId, familyData);
        if (resolution === 'overwritten') {
          console.log(`[Sync Engine] Conflict resolved: overwritten local family ${familyId} with newer remote version`);
          continue;
        }

        const url = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT}/databases/(default)/documents/families/${familyId}`;
        const body = {
          fields: {
            id: { stringValue: familyId },
            name: { stringValue: familyData.name },
            address: { stringValue: familyData.address || '' },
            phone: { stringValue: familyData.phone || '' },
            members: { stringValue: JSON.stringify(familyData.members) }
          }
        };

        const res = await fetch(url, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });

        if (!res.ok) throw new Error(`Sync failed with status: ${res.status}`);
        console.log(`[Sync Engine] Successfully synced Family ${familyId}`);

      } else if (item.type === 'sendSMS') {
        const isLocal = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
        const endpoint = isLocal ? '/api/send-sms' : '/.netlify/functions/send-sms';
        const res = await fetch(endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(item.payload)
        });
        
        // Fast2SMS integration
        if (!res.ok) {
          // If proxy is missing, send directly to Fast2SMS API
          const fast2SmsKey = 'MYPmNuvQ7hsw9324dSBeyUGrapDCKEi08obxjJ5VFqZfgAzc1RIYzXd0aM4UeLJDV2ET5ntuFcosWvgx';
          const fRes = await fetch('https://www.fast2sms.com/dev/bulkV2', {
            method: 'POST',
            headers: {
              'authorization': fast2SmsKey,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              route: 'q',
              message: item.payload.message,
              language: 'english',
              numbers: item.payload.number
            })
          });
          const fData = await fRes.json();
          if (!fRes.ok || fData.return !== true) {
            throw new Error(fData.message || 'Fast2SMS direct API failed');
          }
        }
        console.log(`[Sync Engine] Successfully synced SMS reminder`);

      } else if (item.type === 'runAIChat') {
        const { messageId, prompt } = item.payload;
        
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${import.meta.env?.VITE_GEMINI_KEY || ''}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }]
          })
        });

        if (!response.ok) throw new Error('AI Chat API failed');
        const data = await response.json();
        const aiResponseText = data.candidates?.[0]?.content?.parts?.[0]?.text || 'No response generated';

        window.dispatchEvent(new CustomEvent('asha_ai_chat_completed', {
          detail: { messageId, response: aiResponseText }
        }));
        console.log(`[Sync Engine] Successfully completed queued AI Chat response for ${messageId}`);

      } else if (item.type === 'runAIAnalysis') {
        // Re-run the queued Gemini AI analysis
        const { patientId, prompt, historyItem } = item.payload;
        // Locate matching patient in local store
        const families = getStoredFamilies();
        let targetMember = null;
        let targetFamily = null;
        
        families.forEach(f => f.members.forEach(m => {
          if (m.id === patientId) {
            targetMember = m;
            targetFamily = f;
          }
        }));

        if (targetMember && targetFamily) {
          // Send request to Gemini API
          const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${import.meta.env?.VITE_GEMINI_KEY || ''}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [{ parts: [{ text: prompt }] }]
            })
          });
          
          if (!response.ok) throw new Error('AI analysis API failed');
          
          const data = await response.json();
          const aiResponseText = data.candidates?.[0]?.content?.parts?.[0]?.text || 'No response generated';

          // Update patient record medical history
          const updatedHistory = (targetMember.medicalHistory || []).map(h => {
            if (h.date === historyItem.date && h.condition === historyItem.condition) {
              return { ...h, notes: `AI Recommended Actions:\n${aiResponseText}` };
            }
            return h;
          });

          targetMember.medicalHistory = updatedHistory;
          targetMember.lastUpdated = Date.now();
          
          // Save and push changes
          const updated = families.map(f => {
            if (f.id === targetFamily.id) {
              return {
                ...f,
                members: f.members.map(m => m.id === patientId ? targetMember : m)
              };
            }
            return f;
          });
          
          // Directly save local and let mockData handle standard cloud push
          saveFamilies(updated);
        }
      }
    } catch (err) {
      console.error('[Sync Engine] Failed syncing item:', item, err);
      remaining.push(item); // Retain in queue for next auto-retry
    }
  }

  savePendingQueue(remaining);

  if (remaining.length === 0) {
    updateSyncStatus('synced');
    showToastNotification('☁️ All Data Successfully Synced', 'success');
  } else {
    updateSyncStatus('offline');
  }
};

// Monitor online state changes
window.addEventListener('online', () => {
  updateSyncStatus('synced');
  triggerSync();
});

window.addEventListener('offline', () => {
  updateSyncStatus('offline');
  showToastNotification('📴 Offline Mode Enabled', 'warning');
});

// Periodic background synchronizer check (replays every 15 seconds if online)
setInterval(() => {
  if (navigator.onLine && getPendingCount() > 0 && syncStatus !== 'syncing') {
    triggerSync();
  }
}, 15000);

window.addEventListener('asha_queue_sync', (e) => {
  queueSyncItem(e.detail);
});
