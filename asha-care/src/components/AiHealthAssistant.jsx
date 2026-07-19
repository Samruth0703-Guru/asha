import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function AiHealthAssistant() {
  const [activeSubTab, setActiveSubTab] = useState('skin'); // 'skin', 'chat', 'history'
  const [families, setFamilies] = useState([]);
  const [selectedPatientId, setSelectedPatientId] = useState('');
  
  // Skin Scan state
  const [isScanning, setIsScanning] = useState(false);
  const [scanProgress, setScanProgress] = useState(0);
  const [selectedBodyPart, setSelectedBodyPart] = useState('Arm');
  const [uploadedImage, setUploadedImage] = useState(null);
  const [scanResult, setScanResult] = useState(null);

  // Camera & File Upload states
  const [useCamera, setUseCamera] = useState(false);
  const [cameraError, setCameraError] = useState('');
  const [videoStream, setVideoStream] = useState(null);

  // Extra diagnostic scanner features
  const [selectedLang, setSelectedLang] = useState('en');
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [showReferralSlip, setShowReferralSlip] = useState(false);
  const [smsDispatched, setSmsDispatched] = useState(false);
  const [rotationAngle, setRotationAngle] = useState(0);

  const speakReport = () => {
    if (!scanResult) return;
    if (isSpeaking) {
      window.speechSynthesis.cancel();
      setIsSpeaking(false);
      return;
    }

    let text = `Analysis result shows suspected ${scanResult.disease}. Severity is ${scanResult.severity}. Recommended interventions: ${scanResult.treatment}`;
    
    if (selectedLang === 'ta') {
      text = `தோல் பரிசோதனை முடிவுகள்: ${scanResult.disease} கண்டறியப்பட்டுள்ளது. இதன் தீவிரம்: ${scanResult.severity}. பரிந்துரைக்கப்படும் சிகிச்சை: ${scanResult.treatment}`;
    } else if (selectedLang === 'hi') {
      text = `त्वचा जांच रिपोर्ट: संभावित रोग ${scanResult.disease} है। गंभीरता: ${scanResult.severity}। अनुशंसित उपचार: ${scanResult.treatment}`;
    } else if (selectedLang === 'te') {
      text = `చర్మ విశ్లేషణ ఫలితం: అనుమానిత వ్యాధి ${scanResult.disease}. తీవ్రత: ${scanResult.severity}. సిఫార్సు చేయబడిన చికిత్స: ${scanResult.treatment}`;
    }

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = selectedLang === 'ta' ? 'ta-IN' : selectedLang === 'hi' ? 'hi-IN' : 'te-IN' ? 'te-IN' : 'en-US';
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => setIsSpeaking(false);
    
    setIsSpeaking(true);
    window.speechSynthesis.speak(utterance);
  };

  // Chat/Voice Copilot state
  const [chatMessages, setChatMessages] = useState([
    { sender: 'ai', text: 'Hello! I am your ASHA AI Assistant. You can type a clinical query, describe a patient\'s symptoms, or use voice command to auto-fill vitals.', time: '09:30 AM' }
  ]);
  const [chatInput, setChatInput] = useState('');
  const [isListening, setIsListening] = useState(false);

  // Scan History
  const [scanHistory, setScanHistory] = useState([
    { id: 'SCN-8271', date: '18 Jul 2025', patientName: 'Saraswathi Devi', disease: 'Tinea Corporis (Ringworm)', severity: 'Low', confidence: 94 },
    { id: 'SCN-8094', date: '12 Jul 2025', patientName: 'Ramu K', disease: 'Atopic Dermatitis', severity: 'Moderate', confidence: 88 },
    { id: 'SCN-7911', date: '05 Jul 2025', patientName: 'Anitha R', disease: 'Contact Dermatitis', severity: 'Low', confidence: 91 }
  ]);

  // Clean up camera stream on unmount
  useEffect(() => {
    return () => {
      if (videoStream) {
        videoStream.getTracks().forEach(track => track.stop());
      }
    };
  }, [videoStream]);

  const startCamera = async () => {
    try {
      setCameraError('');
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      setVideoStream(stream);
      setUseCamera(true);
      setTimeout(() => {
        const videoElement = document.getElementById('camera-stream');
        if (videoElement) {
          videoElement.srcObject = stream;
        }
      }, 300);
    } catch (err) {
      setCameraError('Unable to access device camera. Please check browser permissions.');
      console.error(err);
    }
  };

  const stopCamera = () => {
    if (videoStream) {
      videoStream.getTracks().forEach(track => track.stop());
      setVideoStream(null);
    }
    setUseCamera(false);
  };

  const capturePhoto = () => {
    const video = document.getElementById('camera-stream');
    if (!video) return;

    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    const dataUrl = canvas.toDataURL('image/jpeg');

    setUploadedImage(dataUrl);
    stopCamera();

    // Trigger AI Scan on the captured image
    const customResult = {
      name: 'Captured Patient Scan',
      image: dataUrl,
      disease: 'Contact Dermatitis (Irritant)',
      severity: 'Low',
      confidence: 89,
      category: 'Dermatitis',
      treatment: 'Apply mild topical corticosteroid ointment. Avoid contact with potential irritants (harsh soaps, chemicals). Apply cooling calamine lotion.',
      warning: 'Monitor for signs of secondary bacterial infection (pus, warmth, increasing redness). Refer if symptoms worsen.'
    };
    handleSimulateScan(customResult);
  };

  const handleFileUpload = (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target.result;
      setUploadedImage(dataUrl);

      const customResult = {
        name: file.name,
        image: dataUrl,
        disease: 'Atopic Dermatitis (Eczema)',
        severity: 'Moderate',
        confidence: 91,
        category: 'Allergic Dermatosis',
        treatment: 'Apply emollient creams twice daily to maintain skin barrier. Use prescribed topical anti-inflammatory ointment. Keep skin hydrated.',
        warning: 'Avoid scratch triggers. If secondary infection occurs, consult for antibiotics.'
      };
      handleSimulateScan(customResult);
    };
    reader.readAsDataURL(file);
  };

  useEffect(() => {
    const list = getStoredFamilies();
    setFamilies(list);
    // Select first patient as default if available
    if (list.length > 0 && list[0].members.length > 0) {
      setSelectedPatientId(list[0].members[0].id);
    }

    const handleChatCompleted = (e) => {
      const { messageId, response } = e.detail;
      setChatMessages(prev => prev.map(msg => {
        if (msg.id === messageId) {
          return { ...msg, text: response, status: 'completed' };
        }
        return msg;
      }));
    };
    window.addEventListener('asha_ai_chat_completed', handleChatCompleted);
    return () => window.removeEventListener('asha_ai_chat_completed', handleChatCompleted);
  }, []);

  // Get flat list of all patients
  const allPatients = [];
  families.forEach(fam => {
    fam.members.forEach(m => {
      allPatients.push({ ...m, familyId: fam.id, familyName: fam.name });
    });
  });

  const selectedPatient = allPatients.find(p => p.id === selectedPatientId) || allPatients[0];

  // Sample medical cases for scan simulation
  const sampleScans = [
    {
      name: 'Fungal Lesion (Ringworm)',
      image: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=250',
      disease: 'Tinea Corporis (Ringworm)',
      severity: 'Low',
      confidence: 96,
      category: 'Fungal Infection',
      treatment: 'Apply Miconazole or Clotrimazole 2% cream twice daily for 2-4 weeks. Keep area clean and dry. Advise family members not to share towels.',
      warning: 'If lesion spreads, becomes painful, or does not improve in 2 weeks, refer to PHC dermatologist.'
    },
    {
      name: 'Severe Lesion / Erythema',
      image: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=250',
      disease: 'Cellulitis (Bacterial Infection)',
      severity: 'High',
      confidence: 91,
      category: 'Bacterial Dermatitis',
      treatment: 'Start oral antibiotics as prescribed by PHC doctor immediately. Keep limb elevated.',
      warning: 'CRITICAL: High risk of systemic infection (sepsis). Monitor body temperature. Refer to emergency ward immediately.'
    },
    {
      name: 'Psoriasis / Flaky patch',
      image: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&q=80&w=250',
      disease: 'Psoriasis Vulgaris',
      severity: 'Moderate',
      confidence: 85,
      category: 'Autoimmune Dermatosis',
      treatment: 'Topical moisturizers, coal tar preparations, or mild corticosteroid ointments as per doctor prescription.',
      warning: 'Avoid scratching. Keep skin hydrated. Follow-up clinic appointment scheduled in 10 days.'
    }
  ];

  const handleSimulateScan = (sample) => {
    setIsScanning(true);
    setScanProgress(0);
    setScanResult(null);
    setUploadedImage(sample.image);

    const interval = setInterval(() => {
      setScanProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            setIsScanning(false);
            setScanResult(sample);
            // Add to history
            setScanHistory(prevHist => [
              {
                id: `SCN-${Math.floor(1000 + Math.random() * 9000)}`,
                date: new Date().toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }),
                patientName: selectedPatient?.name || 'Unknown',
                disease: sample.disease,
                severity: sample.severity,
                confidence: sample.confidence
              },
              ...prevHist
            ]);
          }, 600);
          return 100;
        }
        return prev + 10;
      });
    }, 150);
  };

  const handleSendMessage = () => {
    if (!chatInput.trim()) return;

    const messageId = `MSG-${Date.now()}`;
    const userMsg = { id: messageId, sender: 'user', text: chatInput, time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) };
    setChatMessages(prev => [...prev, userMsg]);
    const prompt = chatInput.toLowerCase();
    const rawInput = chatInput;
    setChatInput('');

    if (!navigator.onLine) {
      // Add pending AI placeholder message
      const pendingAiMsg = {
        id: messageId,
        sender: 'ai',
        text: '⏳ Connection Offline. Request queued and will analyze once internet returns...',
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        status: 'pending'
      };
      setChatMessages(prev => [...prev, pendingAiMsg]);

      // Queue the AI request globally
      window.dispatchEvent(new CustomEvent('asha_queue_sync', {
        detail: { type: 'runAIChat', payload: { messageId, prompt: rawInput } }
      }));
      return;
    }

    setTimeout(() => {
      let replyText = 'Thank you for your clinical query. Based on ASHA Care guidelines, please ensure standard vitals are logged. How else can I assist?';
      
      if (prompt.includes('anemia') || prompt.includes('hb')) {
        replyText = 'Guidelines for Anemia: Standard Hb range for pregnant mothers is >11 g/dL. If Hb is between 9-11 (Mild Anemia), advise double iron folic acid tablets and iron-rich diet. If Hb is <7 g/dL (Severe Anemia), immediately schedule blood transfusion referral at the District Hospital.';
      } else if (prompt.includes('bp') || prompt.includes('hypertension')) {
        replyText = 'High Blood Pressure Alert: BP reading >= 140/90 mmHg in pregnant mothers indicates pregnancy-induced hypertension. Monitor for symptoms of pre-eclampsia (severe headache, blurred vision, abdominal pain). Promptly refer to PHC.';
      } else if (prompt.includes('fever') || prompt.includes('malaria')) {
        replyText = 'Fever Protocols: Check temperature. If high, check for headache, body pain, and register blood smear test. Keep patient hydrated. Provide paracetamol as per dose-weight chart, and schedule immediate PHC review.';
      } else if (prompt.includes('register') || prompt.includes('add patient')) {
        replyText = 'Voice Registration Copilot Activated: You can read vitals aloud. Example: "Register Saraswathi Devi, Age 24, female, BP 120 over 80, pulse 72, hemoglobin 11.2". The assistant will auto-fill the forms.';
      }

      const aiMsg = { id: messageId, sender: 'ai', text: replyText, time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) };
      setChatMessages(prev => [...prev, aiMsg]);
    }, 800);
  };

  // Simulating Voice Assistant listening
  const handleStartVoice = () => {
    if (isListening) {
      setIsListening(false);
      return;
    }

    setIsListening(true);
    setTimeout(() => {
      setChatInput('Patient BP is 142/95 mmHg, hemoglobin is 9.5 g/dL. What is the diagnosis and advice?');
      setIsListening(false);
    }, 4000);
  };

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-100 pb-5">
        <div>
          <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <span className="material-symbols-outlined text-emerald-700 text-2xl">settings_suggest</span>
            ASHA AI Health Assistant
          </h2>
          <p className="text-xs text-slate-400 font-semibold mt-0.5">
            Clinical vision screening, voice diagnostic copilot, and automated decision support.
          </p>
        </div>

        {/* Sub-tab navigation */}
        <div className="flex bg-slate-100 p-1 rounded-xl text-xs font-bold self-start md:self-auto">
          <button 
            onClick={() => setActiveSubTab('skin')}
            className={`px-4 py-2 rounded-lg flex items-center gap-1.5 transition-all ${activeSubTab === 'skin' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
          >
            <span className="material-symbols-outlined text-sm">visibility</span> Skin Vision Scan
          </button>
          <button 
            onClick={() => setActiveSubTab('chat')}
            className={`px-4 py-2 rounded-lg flex items-center gap-1.5 transition-all ${activeSubTab === 'chat' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
          >
            <span className="material-symbols-outlined text-sm">record_voice_over</span> AI Voice Copilot
          </button>
          <button 
            onClick={() => setActiveSubTab('history')}
            className={`px-4 py-2 rounded-lg flex items-center gap-1.5 transition-all ${activeSubTab === 'history' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
          >
            <span className="material-symbols-outlined text-sm">history</span> Scan Logs
          </button>
        </div>
      </div>

      {/* Select Patient Section */}
      <div className="bg-slate-50 border border-slate-100 p-4 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center">
            <span className="material-symbols-outlined text-xl">person</span>
          </div>
          <div>
            <span className="block text-[10px] text-slate-400 font-extrabold uppercase tracking-wide">Selected Patient Context</span>
            <span className="text-xs font-extrabold text-slate-700">{selectedPatient ? `${selectedPatient.name} (${selectedPatient.id})` : 'No Patient Selected'}</span>
          </div>
        </div>

        <select 
          className="bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none focus:ring-1 focus:ring-emerald-500/20 max-w-xs cursor-pointer"
          value={selectedPatientId}
          onChange={e => setSelectedPatientId(e.target.value)}
        >
          {allPatients.map(p => (
            <option key={p.id} value={p.id}>{p.name} ({p.id})</option>
          ))}
        </select>
      </div>

      {/* ── Sub-tab Content: Skin Disease Scan ── */}
      {activeSubTab === 'skin' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Simulation & Upload Pane */}
          <div className="lg:col-span-1 border border-slate-100 rounded-3xl p-5 space-y-5">
            <div>
              <h4 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">Step 1: Upload or Choose Sample</h4>
              <p className="text-[10px] text-slate-400 font-semibold mt-0.5">Select a pre-loaded clinical symptom sample to run AI vision diagnostic.</p>
            </div>

            <div className="grid grid-cols-1 gap-3">
              {sampleScans.map((sample, i) => (
                <button
                  key={i}
                  onClick={() => handleSimulateScan(sample)}
                  disabled={isScanning}
                  className="flex items-center gap-3 p-2.5 bg-slate-50 border border-slate-150 rounded-2xl hover:border-emerald-500/30 transition-all text-left group disabled:opacity-50"
                >
                  <img src={sample.image} alt={sample.name} className="w-12 h-12 rounded-xl object-cover" />
                  <div className="flex-1">
                    <p className="text-xs font-bold text-slate-700 group-hover:text-emerald-700">{sample.name}</p>
                    <span className="text-[9px] text-slate-400 font-semibold">Diagnostic Category: {sample.severity}</span>
                  </div>
                  <span className="material-symbols-outlined text-slate-300 text-lg group-hover:text-emerald-600">center_focus_strong</span>
                </button>
              ))}
            </div>

            <div className="border-t border-slate-100 pt-4 space-y-3">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Affected Body Part</label>
              <select 
                className="w-full bg-white border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none"
                value={selectedBodyPart}
                onChange={e => setSelectedBodyPart(e.target.value)}
              >
                <option value="Arm">Arm</option>
                <option value="Leg">Leg</option>
                <option value="Face/Neck">Face/Neck</option>
                <option value="Trunk/Back">Trunk/Back</option>
                <option value="Scalp">Scalp</option>
              </select>
            </div>
          </div>

          {/* AI Scanner Container */}
          <div className="lg:col-span-2 border border-slate-100 rounded-3xl p-5 flex flex-col min-h-[400px]">
            {isScanning ? (
              <div className="flex-1 flex flex-col items-center justify-center space-y-6 py-10">
                <div className="relative w-48 h-48 border-2 border-emerald-500/30 rounded-2xl overflow-hidden shadow-inner">
                  {uploadedImage && <img src={uploadedImage} alt="Scanning" className="w-full h-full object-cover" />}
                  {/* Dynamic scanning green line */}
                  <div className="absolute top-0 left-0 w-full h-1 bg-emerald-500 shadow-[0_0_8px_#10b981] animate-[scan_2s_ease-in-out_infinite]"></div>
                </div>
                <div className="text-center space-y-2">
                  <h4 className="text-sm font-extrabold text-slate-700">AI Visual Recognition Engine Running</h4>
                  <p className="text-xs text-slate-400 font-semibold">Running multi-class convolutional neural networks... {scanProgress}%</p>
                  <div className="w-48 bg-slate-100 rounded-full h-1.5 mx-auto">
                    <div className="bg-emerald-500 h-1.5 rounded-full transition-all duration-150" style={{ width: `${scanProgress}%` }}></div>
                  </div>
                </div>
              </div>
            ) : useCamera ? (
              <div className="flex-1 flex flex-col items-center justify-center space-y-5 py-6">
                <div className="relative w-full max-w-md h-64 bg-black rounded-2xl overflow-hidden border border-slate-800">
                  <video id="camera-stream" className="w-full h-full object-cover" autoPlay playsInline></video>
                </div>
                {cameraError && <p className="text-xs text-rose-600 font-bold">{cameraError}</p>}
                <div className="flex gap-3">
                  <button
                    onClick={capturePhoto}
                    className="px-5 py-2.5 bg-[#003d29] hover:brightness-110 text-white font-bold rounded-xl text-xs flex items-center gap-1.5 shadow-md active:scale-95 transition-all"
                  >
                    <span className="material-symbols-outlined text-sm">photo_camera</span> Capture &amp; Scan
                  </button>
                  <button
                    onClick={stopCamera}
                    className="px-5 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs active:scale-95 transition-all"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : scanResult ? (
              <div className="flex-1 space-y-6">
                <div className="flex flex-col md:flex-row justify-between items-start gap-4 border-b border-slate-100 pb-4">
                  <div className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <img 
                        src={uploadedImage} 
                        alt="Scanned Lesion" 
                        className="w-20 h-20 rounded-2xl object-cover border border-slate-200 transition-transform duration-200" 
                        style={{ transform: `rotate(${rotationAngle}deg)` }}
                      />
                      <button 
                        onClick={() => setRotationAngle(prev => (prev + 90) % 360)}
                        className="p-1 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-lg text-[9px] font-extrabold flex items-center gap-1 mt-1.5 transition-all active:scale-95"
                      >
                        <span className="material-symbols-outlined text-[10px]">rotate_right</span> Rotate
                      </button>
                    </div>
                    <div>
                      <span className="text-[9px] text-slate-400 font-extrabold uppercase tracking-wide">Analysis Result</span>
                      <h3 className="text-lg font-extrabold text-slate-800">{scanResult.disease}</h3>
                      <p className="text-xs font-semibold text-slate-400 mt-0.5">Body Part: {selectedBodyPart} • Confidence Score: {scanResult.confidence}%</p>
                      
                      {/* TTS & Translation controls */}
                      <div className="flex items-center gap-2 mt-3 bg-slate-50 border border-slate-150 p-1.5 rounded-xl self-start">
                        <select
                          className="bg-transparent border-0 text-[10px] font-bold text-[#003d29] outline-none cursor-pointer"
                          value={selectedLang}
                          onChange={e => setSelectedLang(e.target.value)}
                        >
                          <option value="en">English (US)</option>
                          <option value="ta">Tamil (தமிழ்)</option>
                          <option value="hi">Hindi (हिन्दी)</option>
                          <option value="te">Telugu (తెలుగు)</option>
                        </select>
                        <button
                          onClick={speakReport}
                          className="flex items-center gap-1 px-2.5 py-1 bg-emerald-700 hover:bg-emerald-800 text-white rounded-lg text-[10px] font-extrabold transition-all"
                        >
                          <span className="material-symbols-outlined text-xs">{isSpeaking ? 'volume_off' : 'volume_up'}</span>
                          {isSpeaking ? 'Stop Speaking' : 'Read Aloud'}
                        </button>
                      </div>
                    </div>
                  </div>

                  <span className={`px-3 py-1.5 rounded-lg text-xs font-extrabold uppercase ${
                    scanResult.severity === 'High' 
                      ? 'bg-rose-50 border border-rose-100 text-rose-700' 
                      : scanResult.severity === 'Moderate' 
                        ? 'bg-amber-50 border border-amber-100 text-amber-700' 
                        : 'bg-emerald-50 border border-emerald-100 text-emerald-700'
                  }`}>
                    {scanResult.severity} Severity
                  </span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="bg-slate-50 border border-slate-100 p-4 rounded-2xl space-y-2">
                    <span className="text-[10px] font-extrabold text-[#003d29] uppercase tracking-wide flex items-center gap-1">
                      <span className="material-symbols-outlined text-xs">healing</span> Recommended Interventions
                    </span>
                    <p className="text-xs text-slate-600 font-semibold leading-relaxed">{scanResult.treatment}</p>
                  </div>

                  <div className="bg-rose-50 border border-rose-100 p-4 rounded-2xl space-y-2">
                    <span className="text-[10px] font-extrabold text-rose-700 uppercase tracking-wide flex items-center gap-1">
                      <span className="material-symbols-outlined text-xs">warning</span> Critical Safety Protocol
                    </span>
                    <p className="text-xs text-rose-800 font-semibold leading-relaxed">{scanResult.warning}</p>
                  </div>
                </div>

                {/* Differential Diagnosis (Mock confidence comparisons) */}
                <div className="bg-white border border-slate-150 p-4 rounded-2xl space-y-3">
                  <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">Differential Diagnoses (Clinical Confidence)</span>
                  <div className="space-y-2">
                    {[
                      { name: scanResult.disease, pct: scanResult.confidence, color: 'bg-emerald-600' },
                      { name: 'Seborrheic Dermatitis', pct: Math.max(10, scanResult.confidence - 45), color: 'bg-slate-400' },
                      { name: 'Allergic Contact Urticaria', pct: Math.max(5, scanResult.confidence - 65), color: 'bg-slate-300' }
                    ].map((diag, idx) => (
                      <div key={idx} className="space-y-1">
                        <div className="flex justify-between text-[11px] font-bold text-slate-700">
                          <span>{diag.name}</span>
                          <span>{diag.pct}%</span>
                        </div>
                        <div className="w-full bg-slate-100 rounded-full h-1.5">
                          <div className={`h-1.5 rounded-full ${diag.color}`} style={{ width: `${diag.pct}%` }}></div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Simulated Actions: Referral Generation and SMS alerts */}
                <div className="flex flex-wrap items-center justify-between gap-4 pt-4 border-t border-slate-100">
                  <div className="flex gap-2">
                    <button
                      onClick={() => setShowReferralSlip(true)}
                      className="px-4 py-2 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-100 font-bold rounded-xl text-xs flex items-center gap-1 transition-all active:scale-95"
                    >
                      <span className="material-symbols-outlined text-sm">assignment</span> Generate PHC Referral
                    </button>
                    <button
                      onClick={() => {
                        setSmsDispatched(true);
                        setTimeout(() => setSmsDispatched(false), 5000);
                      }}
                      className="px-4 py-2 bg-indigo-50 hover:bg-indigo-100 text-indigo-800 border border-indigo-100 font-bold rounded-xl text-xs flex items-center gap-1 transition-all active:scale-95"
                    >
                      <span className="material-symbols-outlined text-sm">sms</span> Send SMS Alert to MO
                    </button>
                  </div>

                  <button 
                    onClick={() => {
                      setScanResult(null);
                      setUploadedImage(null);
                      setRotationAngle(0);
                    }}
                    className="px-5 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors"
                  >
                    Clear Analysis &amp; Scan Another
                  </button>
                </div>

                {/* Referral Slip Modal View */}
                {showReferralSlip && (
                  <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
                    <div className="bg-white border border-slate-150 w-full max-w-lg p-6 rounded-3xl space-y-5 shadow-2xl relative animate-fade-in">
                      <button 
                        onClick={() => setShowReferralSlip(false)}
                        className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 material-symbols-outlined"
                      >
                        close
                      </button>
                      <div className="text-center border-b border-dashed border-slate-200 pb-4 space-y-1">
                        <span className="text-[10px] text-emerald-700 font-extrabold uppercase tracking-widest">ASHA CARE CLINICAL REFERRAL</span>
                        <h4 className="font-extrabold text-slate-800 text-base">Primary Health Center referral Slip</h4>
                        <p className="text-[9px] text-slate-400">Suspected Skin Dermatitis Case Pathway</p>
                      </div>

                      <div className="grid grid-cols-2 gap-4 text-xs font-semibold text-slate-600">
                        <div>
                          <span className="block text-[9px] text-slate-400 font-extrabold uppercase">Patient Name</span>
                          <strong className="text-slate-800">{selectedPatient?.name || 'Saraswathi Devi'}</strong>
                        </div>
                        <div>
                          <span className="block text-[9px] text-slate-400 font-extrabold uppercase">Patient ID</span>
                          <strong className="text-slate-800 font-mono">{selectedPatient?.id || 'PT001'}</strong>
                        </div>
                        <div>
                          <span className="block text-[9px] text-slate-400 font-extrabold uppercase">AI Diagnosis Match</span>
                          <strong className="text-emerald-700">{scanResult.disease} ({scanResult.confidence}% match)</strong>
                        </div>
                        <div>
                          <span className="block text-[9px] text-slate-400 font-extrabold uppercase">Location Geotag</span>
                          <span className="text-slate-500 font-mono text-[10px]">Lat: 11.1416, Lng: 78.5956 (Thuraiyur)</span>
                        </div>
                      </div>

                      <div className="bg-slate-50 p-3 rounded-xl border border-slate-150 text-[11px] leading-relaxed text-slate-600">
                        <strong>Clinical Assessment Note:</strong> Patient exhibits lesion on {selectedBodyPart}. Diagnostic severity is classified as {scanResult.severity}. Action pathway: Refer to Medical Officer (MO) for clinical evaluation and prescribing topical ointments/antifungals.
                      </div>

                      <div className="flex justify-between items-center pt-2">
                        <div className="border border-slate-200 p-1.5 rounded-lg">
                          <div className="w-12 h-12 bg-slate-100 flex items-center justify-center font-black text-slate-300 font-mono text-[6px]">
                            QR PATHWAY
                          </div>
                        </div>
                        <button
                          onClick={() => {
                            window.print();
                            setShowReferralSlip(false);
                          }}
                          className="px-4 py-2 bg-emerald-700 hover:bg-emerald-800 text-white rounded-xl text-xs font-bold transition-all flex items-center gap-1"
                        >
                          <span className="material-symbols-outlined text-xs">print</span> Print Referral Slip
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* SMS Dispatched Alert Toast Notification */}
                {smsDispatched && (
                  <div className="fixed bottom-6 right-6 bg-slate-900 border border-slate-800 text-white p-4 rounded-2xl shadow-xl flex items-center gap-3 z-50 animate-fade-in max-w-sm">
                    <div className="w-8 h-8 rounded-full bg-emerald-600 flex items-center justify-center text-white material-symbols-outlined text-sm">
                      sms
                    </div>
                    <div>
                      <span className="block text-[9px] text-slate-400 font-extrabold uppercase">SMS DISPATCHED TO DOCTOR</span>
                      <p className="text-[11px] font-semibold text-slate-200 mt-0.5 leading-tight">
                        "ALERT: Patient {selectedPatient?.name || 'Saraswathi Devi'} ({selectedPatient?.id}) suspected with {scanResult.disease} ({scanResult.severity} risk) at Thuraiyur."
                      </p>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center space-y-6 py-12 text-center">
                <div className="w-16 h-16 bg-emerald-50 rounded-2xl flex items-center justify-center text-emerald-600">
                  <span className="material-symbols-outlined text-4xl" style={{ fontVariationSettings: "'FILL' 1" }}>center_focus_strong</span>
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-800">Visual Diagnosis Panel</h3>
                  <p className="text-xs text-slate-400 font-semibold mt-1 max-w-sm mx-auto">
                    Select a sample scan case from the left panel, upload a patient photo file, or capture a live webcam shot to execute the AI diagnostic analysis pipeline.
                  </p>
                </div>

                <div className="flex flex-wrap gap-4 justify-center items-center pt-2">
                  <label className="px-5 py-2.5 bg-emerald-700 hover:bg-emerald-800 text-white font-bold rounded-xl text-xs cursor-pointer flex items-center gap-1.5 shadow-md transition-all active:scale-95">
                    <span className="material-symbols-outlined text-sm">upload_file</span>
                    Upload Photo File
                    <input type="file" accept="image/*" onChange={handleFileUpload} className="hidden" />
                  </label>

                  <button
                    onClick={startCamera}
                    className="px-5 py-2.5 bg-[#003d29] hover:brightness-110 text-white font-bold rounded-xl text-xs flex items-center gap-1.5 shadow-md active:scale-95 transition-all"
                  >
                    <span className="material-symbols-outlined text-sm">photo_camera</span>
                    Access Live Camera
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── Sub-tab Content: Voice Assistant & Chatbot ── */}
      {activeSubTab === 'chat' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          
          {/* Info Card Panel */}
          <div className="lg:col-span-1 border border-slate-100 rounded-3xl p-5 space-y-4">
            <div>
              <h4 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">Voice &amp; Chat Copilot</h4>
              <p className="text-[10px] text-slate-400 font-semibold mt-0.5">Use natural language processing to query local guidelines or auto-fill vitals registers.</p>
            </div>

            <div className="space-y-2">
              <span className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Suggested Queries</span>
              {[
                'Show treatment protocol for Anemia < 7g/dL',
                'What is the advice for BP >= 140/90 in pregnancy?',
                'Start Voice Registration Copilot',
                'Protocol for Child malaria fever'
              ].map((query, i) => (
                <button
                  key={i}
                  onClick={() => setChatInput(query)}
                  className="w-full p-2.5 bg-slate-50 border border-slate-100 hover:border-emerald-500/20 text-left rounded-xl text-xs font-semibold text-slate-600 hover:text-emerald-800 transition-all"
                >
                  "{query}"
                </button>
              ))}
            </div>
          </div>

          {/* Chat Window Panel */}
          <div className="lg:col-span-2 border border-slate-100 rounded-3xl flex flex-col h-[480px]">
            {/* Messages Display */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              {chatMessages.map((msg, i) => (
                <div key={i} className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[75%] p-3.5 rounded-2xl text-xs leading-relaxed font-semibold shadow-sm border ${
                    msg.sender === 'user'
                      ? 'bg-emerald-700 border-emerald-600 text-white rounded-tr-none'
                      : 'bg-slate-50 border-slate-100 text-slate-700 rounded-tl-none'
                  }`}>
                    <p>{msg.text}</p>
                    <span className={`block text-[8px] font-extrabold mt-1.5 text-right ${
                      msg.sender === 'user' ? 'text-emerald-200' : 'text-slate-400'
                    }`}>
                      {msg.time}
                    </span>
                  </div>
                </div>
              ))}
            </div>

            {/* Listening Wave Form overlay */}
            {isListening && (
              <div className="px-5 py-3.5 bg-emerald-50 border-y border-emerald-100/50 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="w-2.5 h-2.5 bg-emerald-600 rounded-full animate-ping"></span>
                  <span className="text-xs text-emerald-800 font-extrabold uppercase tracking-wide">Listening to Voice Vitals...</span>
                </div>
                <div className="flex gap-1 items-end h-4">
                  {[0.4, 0.9, 0.3, 0.8, 0.5, 0.7, 0.3, 0.9].map((h, idx) => (
                    <div 
                      key={idx} 
                      className="bg-emerald-600 w-[3px] rounded-full animate-[pulse_1s_infinite_alternate]"
                      style={{ height: `${h * 100}%`, animationDelay: `${idx * 0.1}s` }}
                    ></div>
                  ))}
                </div>
              </div>
            )}

            {/* Input form */}
            <div className="p-4 border-t border-slate-100 flex gap-3">
              <button
                type="button"
                onClick={handleStartVoice}
                className={`w-11 h-11 flex items-center justify-center rounded-xl transition-all border ${
                  isListening 
                    ? 'bg-rose-50 border-rose-200 text-rose-600 hover:bg-rose-100 shadow-md animate-pulse' 
                    : 'bg-emerald-50 border-emerald-100 text-emerald-700 hover:bg-emerald-100'
                }`}
              >
                <span className="material-symbols-outlined text-xl">{isListening ? 'mic_off' : 'mic'}</span>
              </button>
              <input
                type="text"
                value={chatInput}
                onChange={e => setChatInput(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && handleSendMessage()}
                placeholder="Ask clinical queries, or press mic button to speak..."
                className="flex-1 bg-slate-50 border border-slate-200 rounded-xl px-4 text-xs font-semibold text-slate-700 placeholder-slate-400 outline-none focus:bg-white focus:ring-1 focus:ring-emerald-500/20 transition-all"
              />
              <button
                type="button"
                onClick={handleSendMessage}
                className="w-11 h-11 bg-[#003d29] hover:brightness-110 text-white flex items-center justify-center rounded-xl shadow-md transition-all active:scale-95"
              >
                <span className="material-symbols-outlined text-xl">send</span>
              </button>
            </div>

          </div>
        </div>
      )}

      {/* ── Sub-tab Content: Scan Logs / History ── */}
      {activeSubTab === 'history' && (
        <div className="border border-slate-100 rounded-3xl overflow-hidden">
          <div className="p-4 border-b border-slate-50">
            <h3 className="text-sm font-bold text-slate-800">Historical AI Diagnostic Logs</h3>
            <p className="text-[10px] text-slate-400 font-semibold mt-0.5">List of previous visual skin scans and reports conducted in this block.</p>
          </div>
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-slate-100 text-slate-400 font-bold uppercase text-[9px] tracking-wider bg-slate-50/50">
                <th className="p-4">Scan ID</th>
                <th className="p-4">Date</th>
                <th className="p-4">Patient Name</th>
                <th className="p-4">AI Prediction</th>
                <th className="p-4">Severity</th>
                <th className="p-4">Confidence Score</th>
                <th className="p-4">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700 font-semibold">
              {scanHistory.map((hist, i) => (
                <tr key={i} className="hover:bg-slate-50/50">
                  <td className="p-4 font-mono text-emerald-700 font-bold">{hist.id}</td>
                  <td className="p-4 text-slate-400">{hist.date}</td>
                  <td className="p-4 text-slate-800">{hist.patientName}</td>
                  <td className="p-4">{hist.disease}</td>
                  <td className="p-4">
                    <span className={`px-2 py-1 rounded text-[10px] font-extrabold uppercase ${
                      hist.severity === 'High' 
                        ? 'bg-rose-50 text-rose-700 border border-rose-100' 
                        : hist.severity === 'Moderate' 
                          ? 'bg-amber-50 text-amber-700 border border-amber-100' 
                          : 'bg-emerald-50 text-emerald-700 border border-emerald-100'
                    }`}>
                      {hist.severity}
                    </span>
                  </td>
                  <td className="p-4 font-bold">{hist.confidence}%</td>
                  <td className="p-4">
                    <span className="bg-emerald-50 text-emerald-700 border border-emerald-100 px-2 py-0.5 rounded text-[10px] uppercase font-bold">Analyzed</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      
      {/* Dynamic scan animation stylesheet rule */}
      <style>{`
        @keyframes scan {
          0%, 100% { top: 0%; }
          50% { top: 100%; }
        }
      `}</style>
    </div>
  );
}
