import React, { useState, useEffect, useRef, useCallback } from 'react';
import { getStoredFamilies, saveFamilies } from '../database/mockData';

// ─── Normal Range Definitions ─────────────────────────────────────────────────
const RANGES = {
  bloodSugar: {
    label: 'Blood Sugar',
    unit: 'mg/dL',
    low: 70,
    highNormal: 99,
    preDiabetic: 125,
    // <70 = Hypoglycemia (Critical), 70-99 = Normal, 100-125 = Pre-diabetic (Warning), >125 = Diabetic (Critical)
    assess: (v, _gender) => {
      const n = parseFloat(v);
      if (isNaN(n)) return null;
      if (n < 70)  return { level: 'Critical', msg: `Hypoglycemia — Blood sugar critically low (${n} mg/dL). Immediate attention required.` };
      if (n > 125) return { level: 'Critical', msg: `High Blood Sugar — Possible Diabetes (${n} mg/dL). Refer to PHC.` };
      if (n > 99)  return { level: 'Warning',  msg: `Pre-diabetic range — Blood sugar elevated (${n} mg/dL). Monitor closely.` };
      return { level: 'Normal', msg: `Blood Sugar normal (${n} mg/dL).` };
    },
  },
  systolic: {
    assess: (v, diastolic) => {
      const s = parseFloat(v), d = parseFloat(diastolic);
      if (isNaN(s)) return null;
      if (s >= 180 || d >= 120) return { level: 'Critical', msg: `Hypertensive Crisis — BP ${s}/${d} mmHg. Emergency referral required.` };
      if (s >= 140 || d >= 90)  return { level: 'Critical', msg: `Stage 2 Hypertension — BP ${s}/${d} mmHg. Refer to PHC.` };
      if (s >= 130 || d >= 80)  return { level: 'Warning',  msg: `Stage 1 Hypertension — BP ${s}/${d} mmHg. Lifestyle advice needed.` };
      if (s < 90  || d < 60)   return { level: 'Warning',  msg: `Low Blood Pressure — BP ${s}/${d} mmHg. Monitor for symptoms.` };
      return { level: 'Normal', msg: `Blood Pressure normal (${s}/${d} mmHg).` };
    },
  },
  haemoglobin: {
    assess: (v, gender) => {
      const n = parseFloat(v);
      if (isNaN(n)) return null;
      const low = gender === 'Male' ? 13.5 : 12.0;
      const severe = 8.0;
      if (n < severe) return { level: 'Critical', msg: `Severe Anaemia — Haemoglobin critically low (${n} g/dL). Urgent referral.` };
      if (n < low)    return { level: 'Warning',  msg: `Anaemia detected — Haemoglobin below normal (${n} g/dL). Iron supplementation recommended.` };
      return { level: 'Normal', msg: `Haemoglobin normal (${n} g/dL).` };
    },
  },
  temperature: {
    assess: (v) => {
      const n = parseFloat(v);
      if (isNaN(n)) return null;
      if (n >= 39.5) return { level: 'Critical', msg: `High Fever — Temperature ${n}°C. Requires immediate attention.` };
      if (n >= 37.5) return { level: 'Warning',  msg: `Fever — Temperature ${n}°C. Monitor and treat.` };
      if (n < 35.0)  return { level: 'Warning',  msg: `Hypothermia — Temperature ${n}°C. Keep patient warm.` };
      return { level: 'Normal', msg: `Temperature normal (${n}°C).` };
    },
  },
  spO2: {
    assess: (v) => {
      const n = parseFloat(v);
      if (isNaN(n)) return null;
      if (n < 90) return { level: 'Critical', msg: `Critical SpO₂ — ${n}%. Oxygen therapy required. Emergency referral.` };
      if (n < 95) return { level: 'Warning',  msg: `Low SpO₂ — ${n}%. Possible respiratory issue. Monitor closely.` };
      return { level: 'Normal', msg: `SpO₂ normal (${n}%).` };
    },
  },
};

function computeAlerts(vitals, gender) {
  const alerts = [];
  const push = (result) => { if (result && result.level !== 'Normal') alerts.push({ type: result.level, message: result.msg }); };
  push(RANGES.bloodSugar.assess(vitals.bloodSugar, gender));
  push(RANGES.systolic.assess(vitals.systolic, vitals.diastolic));
  push(RANGES.haemoglobin.assess(vitals.haemoglobin, gender));
  push(RANGES.temperature.assess(vitals.temperature));
  push(RANGES.spO2.assess(vitals.spO2));
  return alerts;
}

function computeRiskLevel(alerts) {
  if (alerts.some(a => a.type === 'Critical')) return 'Critical';
  if (alerts.some(a => a.type === 'Warning'))  return 'High';
  return 'Normal';
}

const STEPS = ['Patient Details', 'Health Vitals', 'Review & Submit'];
const defaultVitals = { bloodSugar: '', weight: '', systolic: '', diastolic: '', haemoglobin: '', temperature: '', spO2: '' };
const defaultPatient = {
  name: '', age: '', gender: 'Female', phone: '', aadhaar: '', familyName: '', address: '', role: 'Head of Family', photo: null,
  // Pregnancy fields
  pregnancyStatus: 'Not Pregnant', husbandName: '', bloodGroup: '', height: '',
  lmp: '', gravida: '', parity: '', prevDeliveryType: 'Normal'
};

// ─── ANC Utility Functions ────────────────────────────────────────────────────
function computeEDD(lmpDate) {
  if (!lmpDate) return '';
  const d = new Date(lmpDate);
  d.setDate(d.getDate() + 280); // Naegele's rule: LMP + 280 days
  return d.toISOString().split('T')[0];
}

function computeGestationWeeks(lmpDate) {
  if (!lmpDate) return 0;
  const diff = Date.now() - new Date(lmpDate).getTime();
  return Math.max(0, Math.floor(diff / (7 * 24 * 60 * 60 * 1000)));
}

function computeTrimester(weeks) {
  if (weeks <= 12) return '1st';
  if (weeks <= 27) return '2nd';
  return '3rd';
}

function computePregnancyRiskScore(patient, vitals) {
  let score = 0;
  const age = parseInt(patient.age, 10) || 25;
  const sys = parseFloat(vitals.systolic) || 120;
  const hb  = parseFloat(vitals.haemoglobin) || 12;
  const wt  = parseFloat(vitals.weight) || 55;
  const sugar = parseFloat(vitals.bloodSugar) || 90;
  const gravida = parseInt(patient.gravida, 10) || 1;

  // Age risk
  if (age < 18) score += 25;
  else if (age > 35) score += 20;
  else if (age > 30) score += 10;

  // BP risk
  if (sys >= 160) score += 30;
  else if (sys >= 140) score += 20;
  else if (sys >= 130) score += 10;

  // Haemoglobin risk
  if (hb < 7)  score += 30;
  else if (hb < 9) score += 20;
  else if (hb < 10) score += 15;
  else if (hb < 11) score += 5;

  // Blood sugar risk
  if (sugar > 140) score += 20;
  else if (sugar > 126) score += 15;
  else if (sugar > 100) score += 5;

  // BMI risk (if height available)
  const heightM = parseFloat(patient.height) / 100;
  if (heightM > 0) {
    const bmi = wt / (heightM * heightM);
    if (bmi > 35) score += 15;
    else if (bmi > 30) score += 10;
    else if (bmi < 18) score += 10;
  }

  // Previous history risk
  if (patient.prevDeliveryType === 'Caesarean') score += 10;
  if (gravida >= 5) score += 10;
  else if (gravida >= 4) score += 5;

  return Math.min(100, Math.max(0, score));
}

function getPregnancyRiskLabel(score) {
  if (score >= 60) return 'High';
  if (score >= 30) return 'Moderate';
  return 'Low';
}

function generateAncSchedule(lmpDate) {
  if (!lmpDate) return [];
  const lmp = new Date(lmpDate);
  const visits = [
    { visit: 1, label: 'ANC Visit 1 (12 Weeks)', weekTarget: 12, status: 'Scheduled', data: null },
    { visit: 2, label: 'ANC Visit 2 (20 Weeks)', weekTarget: 20, status: 'Scheduled', data: null },
    { visit: 3, label: 'ANC Visit 3 (28 Weeks)', weekTarget: 28, status: 'Scheduled', data: null },
    { visit: 4, label: 'ANC Visit 4 (36 Weeks)', weekTarget: 36, status: 'Scheduled', data: null },
  ];
  visits.forEach(v => {
    const d = new Date(lmp);
    d.setDate(d.getDate() + v.weekTarget * 7);
    v.scheduledDate = d.toISOString().split('T')[0];
    // Mark past dates as overdue if not yet completed
    if (d < new Date()) v.status = 'Overdue';
  });
  return visits;
}

function generateMedicineTracker() {
  return [
    { name: 'Iron & Folic Acid (IFA)', dosage: '1 tablet daily', totalDays: 180, takenDays: 0, status: 'Pending' },
    { name: 'Calcium', dosage: '500mg twice daily', totalDays: 180, takenDays: 0, status: 'Pending' },
    { name: 'Folic Acid', dosage: '5mg daily (1st trimester)', totalDays: 90, takenDays: 0, status: 'Pending' },
    { name: 'TT-1 (Tetanus Toxoid)', dosage: 'Injection', totalDays: 1, takenDays: 0, status: 'Pending' },
    { name: 'TT-2 (Tetanus Toxoid)', dosage: 'Injection (4 weeks after TT-1)', totalDays: 1, takenDays: 0, status: 'Pending' },
    { name: 'Vitamin D', dosage: '1000 IU daily', totalDays: 180, takenDays: 0, status: 'Pending' },
  ];
}

// ─── Registration Component ────────────────────────────────────────────────────
export default function Registration({ onRegisterSuccess }) {
  const [families, setFamilies] = useState([]);
  const [step, setStep] = useState(0);
  const [patient, setPatient] = useState({ ...defaultPatient });
  const [vitals, setVitals] = useState({ ...defaultVitals });
  const [successMsg, setSuccessMsg] = useState('');

  // Camera
  const [cameraOpen, setCameraOpen] = useState(false);
  const [stream, setStream]         = useState(null);
  const videoRef                    = useRef(null);
  const canvasRef                   = useRef(null);

  // Address / Map
  const [addressSuggestions, setAddressSuggestions] = useState([]);
  const [fetchingLocation, setFetchingLocation]     = useState(false);
  const [addressQuery, setAddressQuery]             = useState('');
  const debounceRef = useRef(null);

  useEffect(() => {
    const load = () => setFamilies(getStoredFamilies());
    load();
    window.addEventListener('asha_data_changed', load);
    return () => window.removeEventListener('asha_data_changed', load);
  }, []);

  // Stop camera on unmount
  useEffect(() => {
    return () => { if (stream) stream.getTracks().forEach(t => t.stop()); };
  }, [stream]);

  // ── Camera Helpers ──────────────────────────────────────────────────────────
  const openCamera = async () => {
    try {
      const s = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user' }, audio: false });
      setStream(s);
      setCameraOpen(true);
      setTimeout(() => { if (videoRef.current) videoRef.current.srcObject = s; }, 100);
    } catch {
      alert('Camera access denied or unavailable.');
    }
  };

  const capturePhoto = () => {
    const video  = videoRef.current;
    const canvas = canvasRef.current;
    if (!video || !canvas) return;
    canvas.width  = video.videoWidth;
    canvas.height = video.videoHeight;
    canvas.getContext('2d').drawImage(video, 0, 0);
    const dataUrl = canvas.toDataURL('image/jpeg', 0.8);
    setPatient(p => ({ ...p, photo: dataUrl }));
    stream.getTracks().forEach(t => t.stop());
    setStream(null);
    setCameraOpen(false);
  };

  const closeCamera = () => {
    if (stream) stream.getTracks().forEach(t => t.stop());
    setStream(null);
    setCameraOpen(false);
  };

  // ── GPS → Address ────────────────────────────────────────────────────────────
  const fetchCurrentLocation = () => {
    if (!navigator.geolocation) {
      alert('Geolocation not supported by this browser.');
      return;
    }
    setFetchingLocation(true);
    navigator.geolocation.getCurrentPosition(
      async ({ coords }) => {
        try {
          const res = await fetch(
            `https://nominatim.openstreetmap.org/reverse?lat=${coords.latitude}&lon=${coords.longitude}&format=json`,
            {
              headers: {
                'User-Agent': 'AshaCarePlus/2.0 (ASHA Worker Health Registry App)'
              }
            }
          );
          if (!res.ok) throw new Error('API limit or error');
          const data = await res.json();
          const addr = data.display_name || '';
          setPatient(p => ({ ...p, address: addr }));
          setAddressQuery(addr);
        } catch (err) {
          console.error(err);
          // Fall back gracefully with coordinates if the API is offline/rate-limited
          const fallbackAddr = `Coordinates: ${coords.latitude.toFixed(5)}, ${coords.longitude.toFixed(5)}`;
          setPatient(p => ({ ...p, address: fallbackAddr }));
          setAddressQuery(fallbackAddr);
        }
        setFetchingLocation(false);
      },
      (err) => {
        console.warn('Geolocation error:', err);
        alert('Location access was denied or could not be determined.');
        setFetchingLocation(false);
      }
    );
  };

  // ── Address Autocomplete ─────────────────────────────────────────────────────
  const handleAddressInput = (val) => {
    setAddressQuery(val);
    setPatient(p => ({ ...p, address: val }));
    clearTimeout(debounceRef.current);
    if (val.length < 3) {
      setAddressSuggestions([]);
      return;
    }
    debounceRef.current = setTimeout(async () => {
      try {
        const res = await fetch(
          `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(val)}&format=json&addressdetails=1&limit=5&countrycodes=in`,
          {
            headers: {
              'User-Agent': 'AshaCarePlus/2.0 (ASHA Worker Health Registry App)'
            }
          }
        );
        const data = await res.json();
        setAddressSuggestions(data.map(d => d.display_name));
      } catch (err) {
        console.error(err);
        setAddressSuggestions([]);
      }
    }, 500);
  };

  const selectSuggestion = (addr) => {
    setPatient(p => ({ ...p, address: addr }));
    setAddressQuery(addr);
    setAddressSuggestions([]);
  };

  // ── Form Changes ─────────────────────────────────────────────────────────────
  const setP = (field, val) => setPatient(p => ({ ...p, [field]: val }));
  const setV = (field, val) => setVitals(v => ({ ...v, [field]: val }));

  // ── Live risk preview ─────────────────────────────────────────────────────────
  const liveAlerts = computeAlerts(vitals, patient.gender);
  const liveRisk   = computeRiskLevel(liveAlerts);

  // ── Submit ───────────────────────────────────────────────────────────────────
  const handleSubmit = (e) => {
    e.preventDefault();

    let maxFpNum = 0;
    families.forEach(f => f.members.forEach(m => {
      const n = parseInt(m.id.replace('FP', ''), 10);
      if (!isNaN(n) && n > maxFpNum) maxFpNum = n;
    }));

    const fpId  = `FP${String(maxFpNum + 1).padStart(3, '0')}`;
    const famId = `FAM${String(families.length + 1).padStart(3, '0')}`;

    const alerts   = computeAlerts(vitals, patient.gender);
    const risk     = computeRiskLevel(alerts);

    const vitalNotes = [
      vitals.bloodSugar  && `Blood Sugar: ${vitals.bloodSugar} mg/dL`,
      vitals.weight      && `Weight: ${vitals.weight} kg`,
      vitals.systolic    && `BP: ${vitals.systolic}/${vitals.diastolic} mmHg`,
      vitals.haemoglobin && `Haemoglobin: ${vitals.haemoglobin} g/dL`,
      vitals.temperature && `Temp: ${vitals.temperature}°C`,
      vitals.spO2        && `SpO₂: ${vitals.spO2}%`,
    ].filter(Boolean).join(' | ');

    // ── Auto-generate Pregnancy Record if Pregnant ──────────────────────────
    let pregnancyDetails = null;
    let ancSchedule = null;
    let medicines = null;
    let pregId = null;
    if (patient.pregnancyStatus === 'Pregnant' && patient.lmp) {
      const gestWeeks = computeGestationWeeks(patient.lmp);
      const edd = computeEDD(patient.lmp);
      const trimester = computeTrimester(gestWeeks);
      const riskScore = computePregnancyRiskScore(patient, vitals);
      const riskLabel = getPregnancyRiskLabel(riskScore);

      // Generate pregnancy ID
      let maxPregNum = 0;
      families.forEach(f => f.members.forEach(m => {
        if (m.pregnancyDetails?.pregId) {
          const n = parseInt(m.pregnancyDetails.pregId.replace('PREG-', ''), 10);
          if (!isNaN(n) && n > maxPregNum) maxPregNum = n;
        }
      }));
      pregId = `PREG-${String(maxPregNum + 1).padStart(3, '0')}`;

      ancSchedule = generateAncSchedule(patient.lmp);
      medicines = generateMedicineTracker();

      pregnancyDetails = {
        pregId,
        lmp: patient.lmp,
        edd,
        weeks: gestWeeks,
        trimester,
        riskLevel: riskLabel,
        riskScore,
        visits: 0,
        gravida: parseInt(patient.gravida, 10) || 1,
        parity: parseInt(patient.parity, 10) || 0,
        prevDeliveryType: patient.prevDeliveryType || 'Normal',
        husbandName: patient.husbandName || '',
        bloodGroup: patient.bloodGroup || '',
        height: patient.height || '',
        registeredOn: new Date().toISOString().split('T')[0],
        status: 'Active',
        ancSchedule,
        medicines,
        vitalsHistory: [{
          date: new Date().toISOString().split('T')[0],
          week: gestWeeks,
          weight: vitals.weight || '',
          bp: vitals.systolic ? `${vitals.systolic}/${vitals.diastolic}` : '',
          hb: vitals.haemoglobin || '',
          bloodSugar: vitals.bloodSugar || '',
          notes: 'Initial registration vitals',
        }],
        delivery: null,
        pncSchedule: null,
        highRiskAlerts: [],
      };

      // Generate high-risk alerts
      const age = parseInt(patient.age, 10) || 25;
      if (parseFloat(vitals.haemoglobin) < 10) pregnancyDetails.highRiskAlerts.push('Anaemia detected (HB < 10 g/dL)');
      if (parseFloat(vitals.systolic) > 140) pregnancyDetails.highRiskAlerts.push('Hypertension detected (BP > 140 mmHg)');
      if (age > 35) pregnancyDetails.highRiskAlerts.push('Advanced maternal age (> 35 years)');
      if (age < 18) pregnancyDetails.highRiskAlerts.push('Adolescent pregnancy (< 18 years)');
      if (parseFloat(vitals.bloodSugar) > 126) pregnancyDetails.highRiskAlerts.push('Gestational diabetes risk (Sugar > 126 mg/dL)');
      if (patient.prevDeliveryType === 'Caesarean') pregnancyDetails.highRiskAlerts.push('Previous Caesarean delivery');
    }

    const newMember = {
      id: fpId,
      name: patient.name,
      age: parseInt(patient.age, 10),
      gender: patient.gender,
      phone: patient.phone,
      aadhaar: patient.aadhaar || 'N/A',
      role: patient.role,
      photo: patient.photo || null,
      husbandName: patient.husbandName || '',
      bloodGroup: patient.bloodGroup || '',
      height: patient.height || '',
      riskLevel: risk,
      vitals: {
        bloodSugar: vitals.bloodSugar,
        weight: vitals.weight,
        bp: vitals.systolic ? `${vitals.systolic}/${vitals.diastolic}` : '',
        haemoglobin: vitals.haemoglobin,
        temperature: vitals.temperature,
        spO2: vitals.spO2,
        recordedOn: new Date().toISOString().split('T')[0],
      },
      medicalHistory: vitalNotes ? [{
        date: new Date().toISOString().split('T')[0],
        condition: 'Initial Health Screening',
        notes: vitalNotes,
      }] : [],
      vaccinations: [],
      appointments: [],
      prescriptions: [],
      alerts,
      ...(pregnancyDetails ? { pregnancyDetails } : {}),
    };

    const newFamily = {
      id: famId,
      name: patient.familyName || `${patient.name}'s Family`,
      address: patient.address,
      phone: patient.phone,
      members: [newMember],
    };

    const updated = [...families, newFamily];
    saveFamilies(updated);

    const pregMsg = pregId ? ` | Pregnancy: ${pregId} | EDD: ${pregnancyDetails.edd}` : '';
    setSuccessMsg(`✅ Registered! ID: ${fpId} | Family: ${famId} | Risk: ${risk}${pregMsg}`);
    setPatient({ ...defaultPatient });
    setVitals({ ...defaultVitals });
    setAddressQuery('');
    setStep(0);

    setTimeout(() => {
      setSuccessMsg('');
      if (onRegisterSuccess) onRegisterSuccess(fpId);
    }, 4000);
  };

  // ── Render Helpers ────────────────────────────────────────────────────────────
  const inputCls = 'bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-3.5 text-sm font-semibold text-slate-700 outline-none focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-400 transition-all placeholder-slate-300 w-full';

  const VitalField = ({ label, field, placeholder, unit, icon, color, extra }) => {
    const raw    = vitals[field];
    const result = RANGES[field]?.assess(raw, field === 'systolic' ? vitals.diastolic : patient.gender);
    const badge  = result && result.level !== 'Normal' ? result : null;

    return (
      <div className="flex flex-col gap-1.5">
        <label className={`text-[10px] font-extrabold text-slate-400 uppercase tracking-wider flex items-center gap-1`}>
          <span className={`material-symbols-outlined text-xs ${color}`}>{icon}</span>
          {label} {unit && <span className="text-slate-300">({unit})</span>}
        </label>
        <input
          type="number" step="0.1"
          value={raw}
          onChange={e => setV(field, e.target.value)}
          placeholder={placeholder}
          className={`${inputCls} ${badge ? (badge.level === 'Critical' ? 'border-rose-400 bg-rose-50/50' : 'border-amber-400 bg-amber-50/50') : ''}`}
        />
        {badge && (
          <div className={`flex items-start gap-1.5 text-[10px] font-bold rounded-lg px-2.5 py-1.5 ${
            badge.level === 'Critical' ? 'bg-rose-50 text-rose-700 border border-rose-200' : 'bg-amber-50 text-amber-700 border border-amber-200'
          }`}>
            <span className="material-symbols-outlined text-xs mt-0.5">
              {badge.level === 'Critical' ? 'emergency' : 'warning'}
            </span>
            {badge.msg}
          </div>
        )}
        {extra}
      </div>
    );
  };

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 max-w-2xl mx-auto space-y-6">

      {/* Header */}
      <div className="flex items-center gap-3">
        <span className="material-symbols-outlined text-emerald-700 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>person_add</span>
        <div>
          <h2 className="text-xl font-bold text-slate-800">Register New Patient</h2>
          <p className="text-xs text-slate-400 font-semibold">Complete all steps to enrol a patient with health screening</p>
        </div>
      </div>

      {/* Step Indicator */}
      <div className="flex items-center gap-2">
        {STEPS.map((s, i) => (
          <React.Fragment key={s}>
            <div className="flex items-center gap-2 shrink-0">
              <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-extrabold transition-all ${
                i < step ? 'bg-emerald-700 text-white' :
                i === step ? 'bg-emerald-100 text-emerald-800 ring-2 ring-emerald-500' :
                'bg-slate-100 text-slate-400'
              }`}>
                {i < step ? <span className="material-symbols-outlined text-sm">check</span> : i + 1}
              </div>
              <span className={`text-xs font-bold hidden sm:block ${i === step ? 'text-emerald-700' : 'text-slate-400'}`}>{s}</span>
            </div>
            {i < STEPS.length - 1 && <div className={`flex-1 h-0.5 rounded-full ${i < step ? 'bg-emerald-500' : 'bg-slate-200'}`} />}
          </React.Fragment>
        ))}
      </div>

      {/* Success */}
      {successMsg && (
        <div className="p-3 bg-emerald-50 border border-emerald-200 text-emerald-800 font-bold rounded-xl flex items-center gap-2 text-sm">
          <span className="material-symbols-outlined text-lg">check_circle</span>
          {successMsg}
        </div>
      )}

      {/* ──────────────────────────────── STEP 1: Patient Details ──────────── */}
      {step === 0 && (
        <form onSubmit={e => { e.preventDefault(); setStep(1); }} className="space-y-5">

          {/* Photo Capture */}
          <div className="flex items-center gap-4">
            <div className="w-20 h-20 rounded-2xl bg-slate-100 border-2 border-dashed border-slate-300 flex items-center justify-center overflow-hidden shrink-0">
              {patient.photo
                ? <img src={patient.photo} alt="Patient" className="w-full h-full object-cover" />
                : <span className="material-symbols-outlined text-slate-400 text-3xl">person</span>}
            </div>
            <div className="space-y-2">
              <p className="text-xs font-bold text-slate-600">Patient Photo</p>
              <button type="button" onClick={openCamera}
                className="flex items-center gap-1.5 bg-slate-50 border border-slate-200 text-slate-600 text-xs font-bold px-3 py-2 rounded-xl hover:bg-slate-100 transition-colors">
                <span className="material-symbols-outlined text-sm">camera_alt</span>
                {patient.photo ? 'Retake Photo' : 'Open Camera'}
              </button>
              {patient.photo && (
                <button type="button" onClick={() => setP('photo', null)}
                  className="flex items-center gap-1 text-rose-500 text-xs font-bold hover:underline">
                  <span className="material-symbols-outlined text-xs">delete</span> Remove
                </button>
              )}
            </div>
          </div>

          {/* Camera Modal */}
          {cameraOpen && (
            <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4">
              <div className="bg-white rounded-3xl p-5 space-y-4 w-full max-w-sm shadow-2xl">
                <div className="flex justify-between items-center">
                  <h3 className="font-bold text-slate-800">Capture Photo</h3>
                  <button type="button" onClick={closeCamera}>
                    <span className="material-symbols-outlined text-slate-400">close</span>
                  </button>
                </div>
                <video ref={videoRef} autoPlay playsInline muted
                  className="w-full rounded-2xl bg-black aspect-video object-cover" />
                <canvas ref={canvasRef} className="hidden" />
                <button type="button" onClick={capturePhoto}
                  className="w-full py-3 bg-emerald-700 text-white font-bold rounded-2xl flex items-center justify-center gap-2">
                  <span className="material-symbols-outlined">photo_camera</span> Capture
                </button>
              </div>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Full Name *</label>
              <input required value={patient.name} onChange={e => setP('name', e.target.value)}
                placeholder="e.g. Priya Devi" className={inputCls} />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Age *</label>
              <input required type="number" min="0" max="120" value={patient.age}
                onChange={e => setP('age', e.target.value)} placeholder="Years" className={inputCls} />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Gender *</label>
              <select required value={patient.gender} onChange={e => setP('gender', e.target.value)} className={inputCls}>
                <option>Female</option><option>Male</option><option>Other</option>
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Role in Family</label>
              <select value={patient.role} onChange={e => setP('role', e.target.value)} className={inputCls}>
                <option>Head of Family</option><option>Wife</option><option>Son</option>
                <option>Daughter</option><option>Mother</option><option>Father</option><option>Other</option>
              </select>
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Mobile Number *</label>
              <input required type="tel" value={patient.phone} onChange={e => setP('phone', e.target.value)}
                placeholder="10-digit number" className={inputCls} />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Aadhaar Number</label>
              <input value={patient.aadhaar} onChange={e => setP('aadhaar', e.target.value)}
                placeholder="XXXX-XXXX-XXXX (optional)" className={inputCls} />
            </div>
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Family / Household Name</label>
              <input value={patient.familyName} onChange={e => setP('familyName', e.target.value)}
                placeholder="e.g. Ramasamy Family" className={inputCls} />
            </div>

            {/* Address with GPS + Autocomplete */}
            <div className="flex flex-col gap-1.5 relative">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Household Address *</label>
              <div className="relative">
                <input required value={addressQuery}
                  onChange={e => handleAddressInput(e.target.value)}
                  placeholder="Type address or use GPS"
                  className={`${inputCls} pr-10`} />
                <button type="button" onClick={fetchCurrentLocation}
                  title="Use my current location"
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 text-emerald-600 hover:text-emerald-800">
                  {fetchingLocation
                    ? <span className="material-symbols-outlined text-sm animate-spin">progress_activity</span>
                    : <span className="material-symbols-outlined text-sm">my_location</span>}
                </button>
              </div>
              {addressSuggestions.length > 0 && (
                <div className="absolute top-full left-0 right-0 z-30 bg-white border border-slate-200 rounded-2xl shadow-xl mt-1 overflow-hidden">
                  {addressSuggestions.map((s, i) => (
                    <button key={i} type="button" onClick={() => selectSuggestion(s)}
                      className="w-full text-left px-4 py-2.5 text-xs text-slate-700 hover:bg-emerald-50 font-medium border-b border-slate-50 last:border-0">
                      <span className="material-symbols-outlined text-[10px] text-emerald-500 mr-1">location_on</span>
                      {s}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* ── Pregnancy Status Section ── */}
            {patient.gender === 'Female' && (
              <>
                <div className="col-span-1 md:col-span-2 mt-2">
                  <div className="bg-pink-50/50 border border-pink-100 rounded-2xl p-4 space-y-4">
                    <div className="flex items-center gap-2">
                      <span className="material-symbols-outlined text-pink-500 text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>pregnant_woman</span>
                      <span className="text-[10px] font-extrabold text-pink-600 uppercase tracking-wider">Maternal Health Status</span>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div className="flex flex-col gap-1.5">
                        <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Pregnancy Status *</label>
                        <select value={patient.pregnancyStatus} onChange={e => setP('pregnancyStatus', e.target.value)} className={inputCls}>
                          <option>Not Pregnant</option>
                          <option>Pregnant</option>
                          <option>Postnatal</option>
                        </select>
                      </div>
                      {patient.pregnancyStatus === 'Pregnant' && (
                        <>
                          <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">LMP (Last Menstrual Period) *</label>
                            <input required type="date" value={patient.lmp} onChange={e => setP('lmp', e.target.value)}
                              max={new Date().toISOString().split('T')[0]} className={inputCls} />
                          </div>
                          <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Husband Name</label>
                            <input value={patient.husbandName} onChange={e => setP('husbandName', e.target.value)}
                              placeholder="e.g. Ravi Kumar" className={inputCls} />
                          </div>
                          <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Blood Group</label>
                            <select value={patient.bloodGroup} onChange={e => setP('bloodGroup', e.target.value)} className={inputCls}>
                              <option value="">Select</option>
                              <option>A+</option><option>A-</option><option>B+</option><option>B-</option>
                              <option>AB+</option><option>AB-</option><option>O+</option><option>O-</option>
                            </select>
                          </div>
                          <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Height (cm)</label>
                            <input type="number" min="100" max="220" value={patient.height} onChange={e => setP('height', e.target.value)}
                              placeholder="e.g. 155" className={inputCls} />
                          </div>
                          <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Gravida (Total Pregnancies)</label>
                            <input type="number" min="1" max="15" value={patient.gravida} onChange={e => setP('gravida', e.target.value)}
                              placeholder="e.g. 2" className={inputCls} />
                          </div>
                          <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Parity (Deliveries)</label>
                            <input type="number" min="0" max="15" value={patient.parity} onChange={e => setP('parity', e.target.value)}
                              placeholder="e.g. 1" className={inputCls} />
                          </div>
                          <div className="flex flex-col gap-1.5">
                            <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Previous Delivery Type</label>
                            <select value={patient.prevDeliveryType} onChange={e => setP('prevDeliveryType', e.target.value)} className={inputCls}>
                              <option>Normal</option>
                              <option>Caesarean</option>
                              <option>Assisted</option>
                              <option>First Pregnancy</option>
                            </select>
                          </div>
                        </>
                      )}
                    </div>
                    {patient.pregnancyStatus === 'Pregnant' && patient.lmp && (
                      <div className="grid grid-cols-3 gap-3 pt-3 border-t border-pink-100">
                        <div className="bg-white rounded-xl p-2.5 text-center border border-pink-50">
                          <span className="block text-[9px] font-extrabold text-slate-400 uppercase">EDD</span>
                          <span className="text-sm font-extrabold text-pink-700">{computeEDD(patient.lmp)}</span>
                        </div>
                        <div className="bg-white rounded-xl p-2.5 text-center border border-pink-50">
                          <span className="block text-[9px] font-extrabold text-slate-400 uppercase">Gestation</span>
                          <span className="text-sm font-extrabold text-emerald-700">{computeGestationWeeks(patient.lmp)} Weeks</span>
                        </div>
                        <div className="bg-white rounded-xl p-2.5 text-center border border-pink-50">
                          <span className="block text-[9px] font-extrabold text-slate-400 uppercase">Trimester</span>
                          <span className="text-sm font-extrabold text-blue-700">{computeTrimester(computeGestationWeeks(patient.lmp))}</span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </>
            )}
          </div>

          <button type="submit"
            className="w-full py-3 bg-[#003d29] text-white font-bold rounded-2xl hover:brightness-110 transition-all text-sm flex items-center justify-center gap-2">
            Next — Health Vitals <span className="material-symbols-outlined text-lg">arrow_forward</span>
          </button>
        </form>
      )}

      {/* ──────────────────────────────── STEP 2: Health Vitals ────────────── */}
      {step === 1 && (
        <form onSubmit={e => { e.preventDefault(); setStep(2); }} className="space-y-5">
          <p className="text-xs text-slate-400 font-semibold">
            Recording vitals for <strong className="text-slate-700">{patient.name}</strong>.
            <span className="text-rose-500 ml-1">⚠ Abnormal values will trigger risk alerts automatically.</span>
          </p>

          {/* Live Risk Banner */}
          {liveAlerts.length > 0 && (
            <div className={`rounded-2xl p-4 border space-y-2 ${
              liveRisk === 'Critical' ? 'bg-rose-50 border-rose-200' : 'bg-amber-50 border-amber-200'
            }`}>
              <p className={`text-xs font-extrabold uppercase tracking-wider flex items-center gap-1.5 ${
                liveRisk === 'Critical' ? 'text-rose-700' : 'text-amber-700'
              }`}>
                <span className="material-symbols-outlined text-sm">
                  {liveRisk === 'Critical' ? 'emergency' : 'warning'}
                </span>
                {liveRisk === 'Critical' ? 'Critical Risk Detected' : 'Health Warning Detected'}
              </p>
              {liveAlerts.map((a, i) => (
                <p key={i} className={`text-xs font-semibold ${liveRisk === 'Critical' ? 'text-rose-700' : 'text-amber-700'}`}>
                  • {a.message}
                </p>
              ))}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <VitalField label="Blood Sugar" field="bloodSugar" placeholder="e.g. 95" unit="mg/dL" icon="water_drop" color="text-rose-400" />
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider flex items-center gap-1">
                <span className="material-symbols-outlined text-xs text-blue-400">scale</span> Weight (kg)
              </label>
              <input type="number" step="0.1" value={vitals.weight} onChange={e => setV('weight', e.target.value)}
                placeholder="e.g. 58.5" className={inputCls} />
            </div>
            <VitalField label="BP Systolic" field="systolic" placeholder="e.g. 120" unit="mmHg" icon="monitor_heart" color="text-orange-400" />
            <VitalField label="BP Diastolic" field="diastolic" placeholder="e.g. 80" unit="mmHg" icon="monitor_heart" color="text-orange-400" />
            <VitalField label="Haemoglobin" field="haemoglobin" placeholder="e.g. 12.5" unit="g/dL" icon="bloodtype" color="text-red-400" />
            <VitalField label="Temperature" field="temperature" placeholder="e.g. 36.8" unit="°C" icon="device_thermostat" color="text-yellow-500" />
            <VitalField label="SpO₂" field="spO2" placeholder="e.g. 98" unit="%" icon="pulmonology" color="text-indigo-400" />
          </div>

          <div className="flex gap-3">
            <button type="button" onClick={() => setStep(0)}
              className="flex-1 py-3 border border-slate-200 text-slate-600 font-bold rounded-2xl hover:bg-slate-50 transition-all text-sm flex items-center justify-center gap-2">
              <span className="material-symbols-outlined text-lg">arrow_back</span> Back
            </button>
            <button type="submit"
              className="flex-[2] py-3 bg-[#003d29] text-white font-bold rounded-2xl hover:brightness-110 transition-all text-sm flex items-center justify-center gap-2">
              Review &amp; Submit <span className="material-symbols-outlined text-lg">arrow_forward</span>
            </button>
          </div>
        </form>
      )}

      {/* ──────────────────────────────── STEP 3: Review & Submit ──────────── */}
      {step === 2 && (
        <form onSubmit={handleSubmit} className="space-y-5">
          <p className="text-xs text-slate-400 font-semibold">Please review before submitting.</p>

          {/* Summary Card */}
          <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 space-y-4">
            {/* Patient */}
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 rounded-2xl bg-slate-200 overflow-hidden shrink-0">
                {patient.photo
                  ? <img src={patient.photo} alt="" className="w-full h-full object-cover" />
                  : <div className="w-full h-full flex items-center justify-center">
                      <span className="material-symbols-outlined text-slate-400 text-2xl">person</span>
                    </div>}
              </div>
              <div>
                <p className="font-extrabold text-slate-800">{patient.name}</p>
                <p className="text-xs text-slate-500 font-semibold">{patient.age} yrs • {patient.gender} • {patient.role}</p>
                <p className="text-xs text-slate-400">{patient.phone} {patient.aadhaar ? `| Aadhaar: ${patient.aadhaar}` : ''}</p>
                <p className="text-xs text-slate-400">{patient.address}</p>
              </div>
            </div>

            {/* Vitals summary */}
            {Object.entries(vitals).some(([, v]) => v) && (
              <div className="grid grid-cols-3 gap-2">
                {vitals.bloodSugar   && <div className="bg-white border border-slate-100 rounded-xl p-2 text-center"><p className="text-[9px] font-extrabold text-slate-400 uppercase">Blood Sugar</p><p className="text-sm font-bold text-slate-700">{vitals.bloodSugar} mg/dL</p></div>}
                {vitals.weight       && <div className="bg-white border border-slate-100 rounded-xl p-2 text-center"><p className="text-[9px] font-extrabold text-slate-400 uppercase">Weight</p><p className="text-sm font-bold text-slate-700">{vitals.weight} kg</p></div>}
                {vitals.systolic     && <div className="bg-white border border-slate-100 rounded-xl p-2 text-center"><p className="text-[9px] font-extrabold text-slate-400 uppercase">BP</p><p className="text-sm font-bold text-slate-700">{vitals.systolic}/{vitals.diastolic}</p></div>}
                {vitals.haemoglobin  && <div className="bg-white border border-slate-100 rounded-xl p-2 text-center"><p className="text-[9px] font-extrabold text-slate-400 uppercase">Haemoglobin</p><p className="text-sm font-bold text-slate-700">{vitals.haemoglobin} g/dL</p></div>}
                {vitals.temperature  && <div className="bg-white border border-slate-100 rounded-xl p-2 text-center"><p className="text-[9px] font-extrabold text-slate-400 uppercase">Temp</p><p className="text-sm font-bold text-slate-700">{vitals.temperature}°C</p></div>}
                {vitals.spO2         && <div className="bg-white border border-slate-100 rounded-xl p-2 text-center"><p className="text-[9px] font-extrabold text-slate-400 uppercase">SpO₂</p><p className="text-sm font-bold text-slate-700">{vitals.spO2}%</p></div>}
              </div>
            )}

            {/* Pregnancy Summary */}
            {patient.pregnancyStatus === 'Pregnant' && patient.lmp && (
              <div className="bg-pink-50 border border-pink-200 rounded-xl p-3 space-y-2">
                <p className="text-[10px] font-extrabold text-pink-600 uppercase tracking-wider flex items-center gap-1">
                  <span className="material-symbols-outlined text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>pregnant_woman</span>
                  Pregnancy Auto-Generated
                </p>
                <div className="grid grid-cols-4 gap-2">
                  <div className="text-center">
                    <span className="block text-[8px] font-bold text-slate-400 uppercase">EDD</span>
                    <span className="text-xs font-extrabold text-pink-700">{computeEDD(patient.lmp)}</span>
                  </div>
                  <div className="text-center">
                    <span className="block text-[8px] font-bold text-slate-400 uppercase">Weeks</span>
                    <span className="text-xs font-extrabold text-emerald-700">{computeGestationWeeks(patient.lmp)}</span>
                  </div>
                  <div className="text-center">
                    <span className="block text-[8px] font-bold text-slate-400 uppercase">Trimester</span>
                    <span className="text-xs font-extrabold text-blue-700">{computeTrimester(computeGestationWeeks(patient.lmp))}</span>
                  </div>
                  <div className="text-center">
                    <span className="block text-[8px] font-bold text-slate-400 uppercase">Risk</span>
                    <span className={`text-xs font-extrabold ${
                      computePregnancyRiskScore(patient, vitals) >= 60 ? 'text-rose-700' :
                      computePregnancyRiskScore(patient, vitals) >= 30 ? 'text-amber-700' : 'text-emerald-700'
                    }`}>{computePregnancyRiskScore(patient, vitals)}/100</span>
                  </div>
                </div>
                <p className="text-[10px] text-pink-600 font-semibold">✓ ANC Schedule (4 visits) + Medicine Tracker + Risk Assessment will be auto-created</p>
              </div>
            )}

            {/* Risk */}
            <div className={`flex items-center gap-2 px-3 py-2 rounded-xl border text-xs font-bold ${
              liveRisk === 'Critical' ? 'bg-rose-50 border-rose-200 text-rose-700' :
              liveRisk === 'High'     ? 'bg-amber-50 border-amber-200 text-amber-700' :
              'bg-emerald-50 border-emerald-200 text-emerald-700'
            }`}>
              <span className="material-symbols-outlined text-sm">
                {liveRisk === 'Normal' ? 'check_circle' : 'warning'}
              </span>
              Risk Level: {liveRisk}
              {liveAlerts.length > 0 && ` — ${liveAlerts.length} alert(s) will be saved`}
            </div>
          </div>

          <div className="flex gap-3">
            <button type="button" onClick={() => setStep(1)}
              className="flex-1 py-3 border border-slate-200 text-slate-600 font-bold rounded-2xl hover:bg-slate-50 transition-all text-sm flex items-center justify-center gap-2">
              <span className="material-symbols-outlined text-lg">arrow_back</span> Back
            </button>
            <button type="submit"
              className="flex-[2] py-3 bg-[#003d29] text-white font-bold rounded-2xl hover:brightness-110 transition-all text-sm flex items-center justify-center gap-2">
              <span className="material-symbols-outlined text-lg">how_to_reg</span>
              Confirm &amp; Register Patient
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
