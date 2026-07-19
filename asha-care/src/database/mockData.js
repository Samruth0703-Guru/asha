// ─── ASHA CARE+ — Real-time & Persistent Cloud Data Layer ────────────────
// All patient data is cached in localStorage under the key "asha_families"
// and persistently synchronized with Google Cloud Firestore via REST APIs.
//
// DATA_VERSION: purge old local cache when structural modifications occur.
// ───────────────────────────────────────────────────────────────────────────────

const DATA_VERSION = "v3.1-persistent";
const VERSION_KEY  = "asha_data_version";
const FIRESTORE_PROJECT = "ehr-companion-for-asha";

// ─── Downward Cloud Sync (Download all registered data from Firestore) ────────
export const syncFromFirestore = async () => {
  try {
    console.log('[Firestore Sync] Downloading persistent database records...');
    const url = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT}/databases/(default)/documents/families`;
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`Failed to fetch cloud records: ${response.status}`);
    }
    const data = await response.json();
    if (data.documents && data.documents.length > 0) {
      const families = data.documents.map(doc => {
        const fields = doc.fields;
        return {
          id: fields.id?.stringValue || '',
          name: fields.name?.stringValue || '',
          address: fields.address?.stringValue || '',
          phone: fields.phone?.stringValue || '',
          members: JSON.parse(fields.members?.stringValue || '[]')
        };
      });
      
      localStorage.setItem("asha_families", JSON.stringify(families));
      localStorage.setItem(VERSION_KEY, DATA_VERSION);
      // Notify stats lists of update
      window.dispatchEvent(new CustomEvent('asha_data_changed', { detail: { timestamp: Date.now() } }));
      console.log('[Firestore Sync] Persistent cloud download completed successfully.');
    }
  } catch (err) {
    console.error('[Firestore Sync] Cloud download failed (offline or unconfigured):', err);
  }
};

// ─── Read locally cached records for instant display ──────────────────────────
export const getStoredFamilies = () => {
  const storedVersion = localStorage.getItem(VERSION_KEY);
  if (storedVersion !== DATA_VERSION) {
    // Purge outdated structures
    localStorage.removeItem("asha_families");
    localStorage.setItem(VERSION_KEY, DATA_VERSION);
    return [];
  }

  const data = localStorage.getItem("asha_families");
  if (!data) return [];
  try {
    return JSON.parse(data);
  } catch (e) {
    return [];
  }
};

// ─── Upward Cloud Sync (Save locally and push to Cloud Firestore) ─────────────
export const saveFamilies = async (families) => {
  // Inject lastUpdated timestamps for members
  const updatedFamilies = families.map(f => ({
    ...f,
    members: f.members.map(m => ({
      ...m,
      lastUpdated: m.lastUpdated || Date.now(),
      pregnancyDetails: m.pregnancyDetails ? {
        ...m.pregnancyDetails,
        lastUpdated: m.pregnancyDetails.lastUpdated || Date.now()
      } : null
    }))
  }));

  // 1. Instantly save locally for UI responsiveness
  localStorage.setItem("asha_families", JSON.stringify(updatedFamilies));
  localStorage.setItem(VERSION_KEY, DATA_VERSION);
  window.dispatchEvent(new CustomEvent('asha_data_changed', { detail: { timestamp: Date.now() } }));

  // 2. Asynchronously upload all families to Cloud Firestore
  for (const fam of updatedFamilies) {
    if (!navigator.onLine) {
      console.log(`[Firestore Sync] Device offline. Queueing family ${fam.id} update.`);
      window.dispatchEvent(new CustomEvent('asha_queue_sync', {
        detail: { type: 'saveFamily', payload: { familyId: fam.id, familyData: fam } }
      }));
      continue;
    }

    try {
      const url = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT}/databases/(default)/documents/families/${fam.id}`;
      const body = {
        fields: {
          id: { stringValue: fam.id },
          name: { stringValue: fam.name },
          address: { stringValue: fam.address || '' },
          phone: { stringValue: fam.phone || '' },
          members: { stringValue: JSON.stringify(fam.members) }
        }
      };
      
      const response = await fetch(url, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
      });

      if (!response.ok) throw new Error(`Fetch failed with status ${response.status}`);
      console.log(`[Firestore Sync] Family ${fam.id} synchronized permanently in Firestore.`);
    } catch (err) {
      console.error(`[Firestore Sync] Failed uploading family ${fam.id} to Firestore. Queueing locally:`, err);
      window.dispatchEvent(new CustomEvent('asha_queue_sync', {
        detail: { type: 'saveFamily', payload: { familyId: fam.id, familyData: fam } }
      }));
    }
  }
};
export const initialFamilies = [];
