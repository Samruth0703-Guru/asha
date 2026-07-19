import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function SmsPanel({ preselectedPatientId, preselectedTemplate, clearPreselected }) {
  const [families, setFamilies] = useState([]);
  const [selectedPatientId, setSelectedPatientId] = useState('');
  const [selectedPatient, setSelectedPatient] = useState(null);
  
  // Fields for dynamic variables
  const [phoneNumber, setPhoneNumber] = useState('');
  const [vaccinationDate, setVaccinationDate] = useState(
    new Date(Date.now() + 86400000).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
  );
  const [clinicName, setClinicName] = useState('Thuraiyur PHC');
  const [doctorName, setDoctorName] = useState('Dr. Rajesh');
  const [villageName, setVillageName] = useState('Thuraiyur');

  // SMS Template selection
  const [selectedTemplate, setSelectedTemplate] = useState('vaccine_tomorrow');
  const [messageContent, setMessageContent] = useState('');
  
  // Sending status
  const [isSending, setIsSending] = useState(false);
  const [statusMessage, setStatusMessage] = useState('');
  const [responseDetails, setResponseDetails] = useState(null);
  const [debugLogs, setDebugLogs] = useState([]);

  // Offline queue state
  const [offlineQueue, setOfflineQueue] = useState([]);

  // Load patients and offline queue
  const loadData = () => {
    const list = getStoredFamilies();
    setFamilies(list);
    
    const queued = JSON.parse(localStorage.getItem('offline_sms_queue') || '[]');
    setOfflineQueue(queued);
  };

  useEffect(() => {
    loadData();

    // Listen for online status to sync
    const handleOnline = () => {
      console.log('Device returned online. Syncing offline SMS queue...');
      syncOfflineQueue();
    };
    window.addEventListener('online', handleOnline);
    return () => window.removeEventListener('online', handleOnline);
  }, []);

  // Flattened patient list
  const allPatients = [];
  families.forEach(fam => {
    fam.members.forEach(m => {
      allPatients.push({ ...m, familyId: fam.id, familyName: fam.name, phone: m.phone || fam.phone || '', village: fam.village || 'Thuraiyur' });
    });
  });

  // Handle patient selection & preselected inputs
  useEffect(() => {
    if (allPatients.length > 0) {
      if (preselectedPatientId) {
        const patient = allPatients.find(p => p.id === preselectedPatientId);
        if (patient) {
          setSelectedPatientId(patient.id);
          setSelectedPatient(patient);
          setPhoneNumber(patient.phone || '');
          setVillageName(patient.village || 'Thuraiyur');
        }
        if (preselectedTemplate) {
          setSelectedTemplate(preselectedTemplate);
        }
        if (clearPreselected) clearPreselected();
      } else if (!selectedPatientId) {
        const first = allPatients[0];
        setSelectedPatientId(first.id);
        setSelectedPatient(first);
        setPhoneNumber(first.phone || '');
        setVillageName(first.village || 'Thuraiyur');
      }
    }
  }, [families, preselectedPatientId, preselectedTemplate]);

  const handlePatientChange = (e) => {
    const pId = e.target.value;
    setSelectedPatientId(pId);
    const patient = allPatients.find(p => p.id === pId);
    if (patient) {
      setSelectedPatient(patient);
      setPhoneNumber(patient.phone || '');
      setVillageName(patient.village || 'Thuraiyur');
    }
  };

  // Generate dynamic message content based on selected template and variables
  useEffect(() => {
    const name = selectedPatient ? selectedPatient.name : 'Patient';
    const id = selectedPatient ? selectedPatient.id : 'N/A';

    let templateText = "";
    if (selectedTemplate === 'vaccine_tomorrow') {
      templateText = `Hello ${name},\n\nReminder:\nTomorrow is your Vaccination Day.\n\nPlease visit your nearest ${clinicName} between 9:00 AM and 4:00 PM.\n\nThank you.\nASHA CARE+`;
    } else if (selectedTemplate === 'general_due') {
      templateText = `Hello ${name} (ID: ${id}),\nYour vaccination is scheduled on ${vaccinationDate} at ${clinicName} under supervision of ${doctorName} in ${villageName}. Please visit the clinic.`;
    } else if (selectedTemplate === 'anc_alert') {
      templateText = `Hello ${name},\n\nReminder:\nTomorrow is your ANC Checkup.\n\nPlease visit your nearest Primary Health Centre.\nCarry your Mother & Child Protection Card.\n\nTime: 9 AM - 4 PM\n\nRegards,\nASHA CARE+`;
    } else {
      templateText = messageContent;
    }
    setMessageContent(templateText);
  }, [selectedTemplate, selectedPatient, vaccinationDate, clinicName, doctorName, villageName]);

  // Log debugger messages
  const addDebugLog = (msg) => {
    setDebugLogs(prev => [`[${new Date().toLocaleTimeString()}] ${msg}`, ...prev]);
  };

  // Real SMS dispatcher function
  const dispatchSMS = async (payload) => {
    addDebugLog(`API Request: POST /api/send-sms`);
    addDebugLog(`Request Body: ${JSON.stringify(payload)}`);

    try {
      const response = await fetch('/api/send-sms', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const statusCode = response.status;
      addDebugLog(`HTTP Status Code: ${statusCode}`);

      const data = await response.json();
      addDebugLog(`API Response: ${JSON.stringify(data)}`);

      if (response.ok && data.return === true) {
        return { success: true, data };
      } else {
        // Map exact failure reasons returned by Fast2SMS or middleware
        let reason = data.message || (data.errors_keys && data.errors_keys.join(', ')) || 'Unknown API Error';
        if (statusCode === 401 || reason.toLowerCase().includes('api key') || reason.toLowerCase().includes('unauthorized')) {
          reason = 'Invalid API Key / Unauthorized';
        } else if (reason.toLowerCase().includes('100 inr') || reason.toLowerCase().includes('transaction of 100')) {
          reason = '100 INR Transaction Required - You need to complete one transaction of 100 INR or more in your Fast2SMS account before utilizing the Developer API.';
        } else if (reason.toLowerCase().includes('spam')) {
          reason = 'Spam Filter Triggered - Fast2SMS blocks multiple messages sent to the same mobile number within a short timeframe (1-5 mins) to prevent flooding. Please wait a few minutes before retrying.';
        } else if (reason.toLowerCase().includes('balance') || reason.toLowerCase().includes('credit')) {
          reason = 'Insufficient Balance';
        } else if (reason.toLowerCase().includes('route')) {
          reason = 'Invalid Route';
        } else if (reason.toLowerCase().includes('number') || reason.toLowerCase().includes('phone')) {
          reason = 'Invalid Mobile Number';
        } else if (reason.toLowerCase().includes('quota') || reason.toLowerCase().includes('limit')) {
          reason = 'Quota Exceeded';
        } else if (statusCode === 408) {
          reason = 'Network Timeout';
        } else if (statusCode === 400) {
          reason = 'Bad Request';
        }
        return { success: false, reason };
      }
    } catch (err) {
      addDebugLog(`Network Error: ${err.message}`);
      return { success: false, reason: 'Network Timeout / Unreachable Server' };
    }
  };

  // Main send handler
  const handleSendReminderSMS = async (e) => {
    if (e) e.preventDefault();
    if (!phoneNumber.trim()) {
      alert("Please enter a valid mobile number.");
      return;
    }

    const payload = {
      number: phoneNumber.trim(),
      message: messageContent,
      patientId: selectedPatient ? selectedPatient.id : 'N/A',
      patientName: selectedPatient ? selectedPatient.name : 'N/A'
    };

    setIsSending(true);
    setStatusMessage('');
    setResponseDetails(null);

    // If device is offline, queue locally
    if (!navigator.onLine) {
      addDebugLog(`Device offline detected. Queueing SMS locally.`);
      queueOfflineSMS(payload);
      setIsSending(false);
      return;
    }

    const result = await dispatchSMS(payload);
    setIsSending(false);

    if (result.success) {
      setStatusMessage('success');
      setResponseDetails({
        messageId: result.data.request_id || 'N/A',
        status: result.data.message?.[0] || 'Dispatched',
        timestamp: new Date().toLocaleTimeString('en-IN')
      });
    } else {
      setStatusMessage('error');
      setResponseDetails({
        reason: result.reason
      });
    }
  };

  // Local Offline Queue Helpers
  const queueOfflineSMS = (payload) => {
    const queuedItem = {
      id: Date.now().toString(),
      payload,
      timestamp: new Date().toLocaleString()
    };
    const updated = [queuedItem, ...offlineQueue];
    localStorage.setItem('offline_sms_queue', JSON.stringify(updated));
    setOfflineQueue(updated);
    setStatusMessage('queued');
    
    // Dispatch to global offline sync engine
    window.dispatchEvent(new CustomEvent('asha_queue_sync', {
      detail: { type: 'sendSMS', payload: payload }
    }));
  };

  const syncOfflineQueue = async () => {
    const queued = JSON.parse(localStorage.getItem('offline_sms_queue') || '[]');
    if (queued.length === 0) return;

    addDebugLog(`Syncing ${queued.length} offline queued SMS messages...`);
    const remaining = [];

    for (const item of queued) {
      addDebugLog(`Retrying queued SMS for ${item.payload.patientName}...`);
      const result = await dispatchSMS(item.payload);
      if (!result.success) {
        addDebugLog(`Failed to sync item ${item.id}: ${result.reason}. Retaining in queue.`);
        remaining.push(item);
      } else {
        addDebugLog(`Successfully synced item ${item.id}`);
      }
    }

    localStorage.setItem('offline_sms_queue', JSON.stringify(remaining));
    setOfflineQueue(remaining);
  };

  return (
    <div className="space-y-6 max-w-5xl">
      
      {/* Offline Alert Indicator */}
      {offlineQueue.length > 0 && (
        <div className="bg-amber-50 border border-amber-200 text-amber-800 p-4 rounded-2xl flex items-center justify-between shadow-sm animate-pulse">
          <div className="flex items-center gap-2 text-xs font-bold">
            <span className="material-symbols-outlined text-lg">offline_bolt</span>
            <span>{offlineQueue.length} Pending Offline SMS Reminders in Queue</span>
          </div>
          <button 
            onClick={syncOfflineQueue}
            className="px-3 py-1 bg-amber-600 text-white rounded-lg text-[10px] font-extrabold hover:bg-amber-700 transition-colors"
          >
            Retry Sync Now
          </button>
        </div>
      )}

      {/* Main Grid Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Form and Template configs */}
        <div className="lg:col-span-2 bg-white p-6 rounded-3xl border border-slate-100 space-y-5 h-fit shadow-sm">
          <div>
            <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
              <span className="material-symbols-outlined text-emerald-700 text-2xl">sms</span>
              SMS Reminder &amp; Alerts Dispatcher
            </h2>
            <p className="text-xs text-slate-400 font-semibold mt-0.5">
              Dispatch dynamic vaccination reminders via Fast2SMS and record delivery logs.
            </p>
          </div>

          <form onSubmit={handleSendReminderSMS} className="space-y-4">
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Select Patient */}
              <div className="space-y-2">
                <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Select Patient</label>
                <select
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-750 outline-none focus:bg-white"
                  value={selectedPatientId}
                  onChange={handlePatientChange}
                >
                  {allPatients.map(p => (
                    <option key={p.id} value={p.id}>{p.name} ({p.id})</option>
                  ))}
                </select>
              </div>

              {/* Mobile Number */}
              <div className="space-y-2">
                <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Required Mobile Number</label>
                <input
                  type="tel"
                  value={phoneNumber}
                  onChange={e => setPhoneNumber(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-750 outline-none focus:bg-white"
                  placeholder="e.g. 9876543210"
                />
              </div>
            </div>

            {/* Dynamic Template Variables */}
            <div className="bg-slate-50 p-4 rounded-2xl border border-slate-100 space-y-3">
              <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Dynamic Template Variables</span>
              
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div className="space-y-1">
                  <label className="text-[9px] font-bold text-slate-500">Vaccination Date</label>
                  <input 
                    type="text" 
                    value={vaccinationDate} 
                    onChange={e => setVaccinationDate(e.target.value)}
                    className="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-[10px] font-bold text-slate-700 outline-none"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-[9px] font-bold text-slate-500">Clinic Name</label>
                  <input 
                    type="text" 
                    value={clinicName} 
                    onChange={e => setClinicName(e.target.value)}
                    className="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-[10px] font-bold text-slate-700 outline-none"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-[9px] font-bold text-slate-500">Doctor Name</label>
                  <input 
                    type="text" 
                    value={doctorName} 
                    onChange={e => setDoctorName(e.target.value)}
                    className="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-[10px] font-bold text-slate-700 outline-none"
                  />
                </div>
                <div className="space-y-1">
                  <label className="text-[9px] font-bold text-slate-500">Village Name</label>
                  <input 
                    type="text" 
                    value={villageName} 
                    onChange={e => setVillageName(e.target.value)}
                    className="w-full bg-white border border-slate-200 rounded-lg px-2.5 py-1.5 text-[10px] font-bold text-slate-700 outline-none"
                  />
                </div>
              </div>
            </div>

            {/* Template Selector */}
            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">SMS Alert Template</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-750 outline-none focus:bg-white"
                value={selectedTemplate}
                onChange={e => setSelectedTemplate(e.target.value)}
              >
                <option value="vaccine_tomorrow">Vaccine Tomorrow Reminder (Standard Template)</option>
                <option value="general_due">General Vaccination Scheduled Alert</option>
                <option value="anc_alert">Maternal Antenatal Checkup Notice</option>
                <option value="custom">Custom Message Content</option>
              </select>
            </div>

            {/* Message Area */}
            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Message Content</label>
              <textarea
                rows="6"
                value={messageContent}
                onChange={e => {
                  setMessageContent(e.target.value);
                  if (selectedTemplate !== 'custom') setSelectedTemplate('custom');
                }}
                className="w-full bg-slate-50 border border-slate-200 rounded-2xl p-4 text-xs font-semibold text-slate-700 placeholder-slate-400 outline-none focus:bg-white transition-all resize-none font-sans"
              />
            </div>

            {/* Submit */}
            <div className="flex justify-end pt-2">
              <button
                type="submit"
                disabled={isSending}
                className="px-6 py-2.5 bg-[#003d29] hover:brightness-110 text-white font-bold rounded-xl text-xs shadow-md transition-all active:scale-95 flex items-center gap-1.5 disabled:opacity-50"
              >
                <span className="material-symbols-outlined text-sm">{isSending ? 'hourglass_empty' : 'send'}</span>
                {isSending ? 'Sending Real SMS...' : 'Send Reminder SMS'}
              </button>
            </div>

          </form>
        </div>

        {/* Status Responses & Debug Panel */}
        <div className="lg:col-span-1 space-y-6">
          
          {/* Success / Failure status card */}
          <div className="bg-white p-5 rounded-3xl border border-slate-100 shadow-sm space-y-4">
            <h3 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">Delivery Status</h3>

            {statusMessage === 'success' && (
              <div className="space-y-3 bg-emerald-50 border border-emerald-100 p-4 rounded-2xl">
                <span className="text-sm font-black text-emerald-800 flex items-center gap-1">
                  ✅ SMS Sent Successfully
                </span>
                <div className="text-[10px] font-bold text-emerald-700 space-y-1">
                  <p>Message ID: <span className="font-mono">{responseDetails?.messageId}</span></p>
                  <p>Status: {responseDetails?.status}</p>
                  <p>Timestamp: {responseDetails?.timestamp}</p>
                </div>
              </div>
            )}

            {statusMessage === 'error' && (
              <div className="space-y-3 bg-rose-50 border border-rose-100 p-4 rounded-2xl">
                <span className="text-sm font-black text-rose-800 flex items-center gap-1">
                  ❌ Delivery Failed
                </span>
                <p className="text-[10px] font-extrabold text-rose-700 uppercase">Reason:</p>
                <p className="text-xs font-bold text-rose-800">{responseDetails?.reason}</p>
                
                <button
                  onClick={handleSendReminderSMS}
                  className="mt-2 w-full py-1.5 bg-rose-600 hover:bg-rose-700 text-white font-extrabold rounded-lg text-[10px] flex items-center justify-center gap-1 transition-all active:scale-95"
                >
                  <span className="material-symbols-outlined text-xs">replay</span> Retry Sending
                </button>
              </div>
            )}

            {statusMessage === 'queued' && (
              <div className="bg-amber-50 border border-amber-100 p-4 rounded-2xl text-xs font-bold text-amber-800 flex items-center gap-2">
                <span className="material-symbols-outlined">schedule</span>
                Queued Locally (Device Offline)
              </div>
            )}

            {!statusMessage && (
              <p className="text-xs text-slate-400 font-semibold italic text-center py-6">No SMS sent in this session yet.</p>
            )}
          </div>

          {/* Debug Console Panel */}
          <div className="bg-slate-900 text-slate-300 p-5 rounded-3xl shadow-sm space-y-3 font-mono text-[11px] h-[340px] flex flex-col overflow-hidden">
            <div className="flex justify-between items-center border-b border-slate-800 pb-2">
              <span className="text-[9px] font-black text-slate-400 uppercase tracking-widest">Debug Console Logs</span>
              <button 
                onClick={() => setDebugLogs([])}
                className="text-[9px] font-black text-emerald-500 hover:text-emerald-400 uppercase"
              >
                Clear
              </button>
            </div>
            
            <div className="flex-1 overflow-y-auto space-y-1.5 custom-scrollbar select-text">
              {debugLogs.map((log, idx) => (
                <div key={idx} className="leading-relaxed break-all whitespace-pre-wrap">{log}</div>
              ))}
              {debugLogs.length === 0 && (
                <span className="text-slate-650 italic text-[10px]">Console output will show here...</span>
              )}
            </div>
          </div>

        </div>

      </div>

    </div>
  );
}
