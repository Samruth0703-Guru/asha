import React, { useState, useEffect, useMemo } from 'react';
import { getStoredFamilies, saveFamilies } from '../database/mockData';

// ─── ANC Utility Functions (shared) ──────────────────────────────────────────
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

function daysUntil(dateStr) {
  if (!dateStr) return 999;
  const d = new Date(dateStr);
  const now = new Date();
  now.setHours(0,0,0,0);
  d.setHours(0,0,0,0);
  return Math.ceil((d - now) / (1000 * 60 * 60 * 24));
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}

function getBabyGrowthDesc(weeks) {
  if (weeks <= 4) return { size: 'Poppy seed', length: '< 1 mm', desc: 'Cells are dividing rapidly to form the embryo.' };
  if (weeks <= 8) return { size: 'Raspberry', length: '~16 mm', desc: 'Heart is beating, tiny limbs forming.' };
  if (weeks <= 12) return { size: 'Lime', length: '~5 cm', desc: 'All organs formed, fingers & toes visible.' };
  if (weeks <= 16) return { size: 'Avocado', length: '~12 cm', desc: 'Baby can make facial expressions, bones hardening.' };
  if (weeks <= 20) return { size: 'Banana', length: '~25 cm', desc: 'Baby kicks are felt, vernix coating forms.' };
  if (weeks <= 24) return { size: 'Corn', length: '~30 cm', desc: 'Lungs developing, baby responds to sound.' };
  if (weeks <= 28) return { size: 'Eggplant', length: '~37 cm', desc: 'Eyes can open, rapid brain development.' };
  if (weeks <= 32) return { size: 'Squash', length: '~42 cm', desc: 'Baby practices breathing, gaining weight fast.' };
  if (weeks <= 36) return { size: 'Honeydew', length: '~47 cm', desc: 'Baby is almost full size, head may engage.' };
  return { size: 'Watermelon', length: '~50 cm', desc: 'Full term! Baby ready for delivery.' };
}

// ─── SVG Mini Chart Component ────────────────────────────────────────────────
function MiniLineChart({ data, color, label, unit }) {
  if (!data || data.length < 2) return (
    <div className="text-center py-4 text-[10px] text-slate-400 italic">Not enough data for chart</div>
  );
  const values = data.map(d => parseFloat(d.value)).filter(v => !isNaN(v));
  if (values.length < 2) return null;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = max - min || 1;
  const W = 240, H = 80, PAD = 10;
  const points = values.map((v, i) => ({
    x: PAD + (i / (values.length - 1)) * (W - 2 * PAD),
    y: PAD + (1 - (v - min) / range) * (H - 2 * PAD),
  }));
  const pathD = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ');
  return (
    <div className="space-y-1">
      <p className="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider">{label}</p>
      <svg viewBox={`0 0 ${W} ${H}`} className="w-full h-20" preserveAspectRatio="none">
        <defs>
          <linearGradient id={`grad-${label.replace(/\s/g,'')}`} x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stopColor={color} stopOpacity="0.3" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={`${pathD} L ${points[points.length-1].x} ${H} L ${points[0].x} ${H} Z`} fill={`url(#grad-${label.replace(/\s/g,'')})`} />
        <path d={pathD} fill="none" stroke={color} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
        {points.map((p, i) => (
          <g key={i}>
            <circle cx={p.x} cy={p.y} r="3.5" fill="white" stroke={color} strokeWidth="2" />
            <text x={p.x} y={p.y - 8} textAnchor="middle" className="text-[7px]" fill={color} fontWeight="700">
              {values[i]}{unit}
            </text>
          </g>
        ))}
      </svg>
      <div className="flex justify-between text-[8px] text-slate-400 font-semibold px-2">
        {data.map((d, i) => <span key={i}>{d.label}</span>)}
      </div>
    </div>
  );
}

// ─── Circular Risk Gauge ─────────────────────────────────────────────────────
function RiskGauge({ score, size = 64 }) {
  const r = (size - 8) / 2;
  const circ = 2 * Math.PI * r;
  const pct = Math.min(100, Math.max(0, score)) / 100;
  const offset = circ * (1 - pct);
  const color = score >= 60 ? '#ef4444' : score >= 30 ? '#f59e0b' : '#10b981';
  const label = score >= 60 ? 'HIGH' : score >= 30 ? 'MODERATE' : 'LOW';
  return (
    <div className="flex flex-col items-center gap-0.5 relative" style={{ width: size, height: size + 16 }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#f1f5f9" strokeWidth="6" />
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth="6"
          strokeDasharray={circ} strokeDashoffset={offset}
          strokeLinecap="round" style={{ transition: 'stroke-dashoffset 1s ease' }} />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center" style={{ height: size }}>
        <span className="text-sm font-extrabold" style={{ color }}>{score}</span>
        <span className="text-[7px] font-bold text-slate-400">/100</span>
      </div>
      <span className="text-[8px] font-extrabold tracking-wider" style={{ color }}>{label}</span>
    </div>
  );
}

// ─── Record ANC Visit Modal ──────────────────────────────────────────────────
function AncVisitModal({ preg, visitIdx, onSave, onClose }) {
  const [form, setForm] = useState({
    weight: '', systolic: '', diastolic: '', haemoglobin: '',
    fetalHeartRate: '', fundalHeight: '', urineAlbumin: 'Nil',
    medicine: '', doctor: '', notes: '', status: 'Completed'
  });
  const setF = (k, v) => setForm(f => ({ ...f, [k]: v }));
  const inputCls = "w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 outline-none focus:ring-1 focus:ring-emerald-500/30 transition-all";

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(visitIdx, {
      ...form,
      bp: form.systolic ? `${form.systolic}/${form.diastolic}` : '',
      date: new Date().toISOString().split('T')[0],
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
      <div className="bg-white rounded-3xl shadow-2xl border border-slate-100 w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <div className="p-6 space-y-4">
          <div className="flex justify-between items-center">
            <div>
              <h3 className="text-lg font-extrabold text-slate-800">Record ANC Visit {visitIdx + 1}</h3>
              <p className="text-xs text-slate-400 font-semibold">
                {preg.name} &middot; {preg.pregnancyDetails?.pregId} &middot; Week {computeGestationWeeks(preg.pregnancyDetails?.lmp)}
              </p>
            </div>
            <button onClick={onClose} className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center hover:bg-slate-200">
              <span className="material-symbols-outlined text-sm text-slate-500">close</span>
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">Weight (kg)</label>
                <input type="number" step="0.1" value={form.weight} onChange={e => setF('weight', e.target.value)} className={inputCls} placeholder="e.g. 58.5" />
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">BP Systolic</label>
                <input type="number" value={form.systolic} onChange={e => setF('systolic', e.target.value)} className={inputCls} placeholder="e.g. 120" />
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">BP Diastolic</label>
                <input type="number" value={form.diastolic} onChange={e => setF('diastolic', e.target.value)} className={inputCls} placeholder="e.g. 80" />
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">Haemoglobin (g/dL)</label>
                <input type="number" step="0.1" value={form.haemoglobin} onChange={e => setF('haemoglobin', e.target.value)} className={inputCls} placeholder="e.g. 11.5" />
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">Fetal Heart Rate</label>
                <input type="number" value={form.fetalHeartRate} onChange={e => setF('fetalHeartRate', e.target.value)} className={inputCls} placeholder="e.g. 140 bpm" />
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">Fundal Height (cm)</label>
                <input type="number" step="0.1" value={form.fundalHeight} onChange={e => setF('fundalHeight', e.target.value)} className={inputCls} placeholder="e.g. 28" />
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">Urine Albumin</label>
                <select value={form.urineAlbumin} onChange={e => setF('urineAlbumin', e.target.value)} className={inputCls}>
                  <option>Nil</option><option>Trace</option><option>+1</option><option>+2</option><option>+3</option>
                </select>
              </div>
              <div className="flex flex-col gap-1">
                <label className="text-[9px] font-extrabold text-slate-400 uppercase">Doctor Name</label>
                <input value={form.doctor} onChange={e => setF('doctor', e.target.value)} className={inputCls} placeholder="e.g. Dr. Rajesh" />
              </div>
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-[9px] font-extrabold text-slate-400 uppercase">Medicine Dispensed</label>
              <input value={form.medicine} onChange={e => setF('medicine', e.target.value)} className={inputCls} placeholder="e.g. IFA, Calcium, TT-1" />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-[9px] font-extrabold text-slate-400 uppercase">Notes</label>
              <textarea value={form.notes} onChange={e => setF('notes', e.target.value)} className={`${inputCls} min-h-[60px] resize-none`}
                placeholder="Clinical observations, advice given..." />
            </div>
            <div className="flex gap-3">
              <button type="button" onClick={onClose}
                className="flex-1 py-2.5 border border-slate-200 text-slate-600 font-bold rounded-2xl hover:bg-slate-50 text-xs">
                Cancel
              </button>
              <button type="submit"
                className="flex-[2] py-2.5 bg-[#003d29] text-white font-bold rounded-2xl hover:brightness-110 text-xs flex items-center justify-center gap-2">
                <span className="material-symbols-outlined text-sm">save</span>
                Save ANC Visit
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
export default function Pregnancies({ onSendSmsClick }) {
  const [families, setFamilies] = useState([]);
  const [selectedPreg, setSelectedPreg] = useState(null);
  const [ancModal, setAncModal] = useState(null);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    const load = () => setFamilies(getStoredFamilies());
    load();
    window.addEventListener('asha_data_changed', load);
    window.addEventListener('storage', load);
    return () => {
      window.removeEventListener('asha_data_changed', load);
      window.removeEventListener('storage', load);
    };
  }, []);

  // ── Build pregnant mothers list ───────────────────────────────────────────
  const pregList = useMemo(() => {
    const list = [];
    families.forEach(fam => {
      fam.members.forEach(m => {
        if (m.pregnancyDetails) {
          const lmp = m.pregnancyDetails.lmp;
          const weeks = lmp ? computeGestationWeeks(lmp) : (m.pregnancyDetails.weeks || 0);
          const trimester = computeTrimester(weeks);
          list.push({
            ...m,
            address: fam.address,
            familyName: fam.name,
            familyId: fam.id,
            pregnancyDetails: { ...m.pregnancyDetails, weeks, trimester },
          });
        }
      });
    });
    return list;
  }, [families]);

  // ── KPI Calculations ──────────────────────────────────────────────────────
  const kpi = useMemo(() => {
    const today = new Date().toISOString().split('T')[0];
    const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];
    let highRisk = 0, ancDueToday = 0, ancDueTomorrow = 0, missedAnc = 0;
    let expectedThisMonth = 0, ttPending = 0, ironPending = 0;

    pregList.forEach(p => {
      const pd = p.pregnancyDetails;
      if (pd.riskLevel === 'High') highRisk++;
      const schedule = pd.ancSchedule || [];
      schedule.forEach(v => {
        if (v.status === 'Completed') return;
        if (v.scheduledDate === today) ancDueToday++;
        else if (v.scheduledDate === tomorrow) ancDueTomorrow++;
        else if (v.scheduledDate < today && v.status !== 'Completed') missedAnc++;
      });
      if (pd.edd) {
        const eddMonth = pd.edd.substring(0, 7);
        const thisMonth = today.substring(0, 7);
        if (eddMonth === thisMonth) expectedThisMonth++;
      }
      const meds = pd.medicines || [];
      if (meds.filter(m => m.name.includes('TT') && m.status === 'Pending').length > 0) ttPending++;
      if (meds.filter(m => m.name.includes('Iron') && m.status === 'Pending').length > 0) ironPending++;
    });

    return { total: pregList.length, highRisk, ancDueToday, ancDueTomorrow, missedAnc, expectedThisMonth, ttPending, ironPending };
  }, [pregList]);

  // ── Save ANC Visit ────────────────────────────────────────────────────────
  const handleSaveAncVisit = (visitIdx, visitData) => {
    const preg = ancModal.preg;
    const updatedFamilies = families.map(fam => ({
      ...fam,
      members: fam.members.map(m => {
        if (m.id !== preg.id || !m.pregnancyDetails) return m;
        const pd = { ...m.pregnancyDetails };
        const schedule = [...(pd.ancSchedule || [])];
        if (schedule[visitIdx]) {
          schedule[visitIdx] = { ...schedule[visitIdx], status: 'Completed', data: visitData };
        }
        pd.ancSchedule = schedule;
        pd.visits = (pd.visits || 0) + 1;
        const history = [...(pd.vitalsHistory || [])];
        history.push({
          date: visitData.date, week: computeGestationWeeks(pd.lmp),
          weight: visitData.weight, bp: visitData.bp, hb: visitData.haemoglobin,
          bloodSugar: '', fetalHeartRate: visitData.fetalHeartRate,
          fundalHeight: visitData.fundalHeight, notes: visitData.notes,
        });
        pd.vitalsHistory = history;
        return { ...m, pregnancyDetails: pd };
      })
    }));
    saveFamilies(updatedFamilies);
    setAncModal(null);
  };

  const selectedPatient = selectedPreg ? pregList.find(p => p.id === selectedPreg) : null;

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDER
  // ═══════════════════════════════════════════════════════════════════════════
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-xl font-extrabold text-slate-800 flex items-center gap-2">
              <span className="material-symbols-outlined text-pink-500" style={{ fontVariationSettings: "'FILL' 1" }}>pregnant_woman</span>
              Maternal Health Intelligence (ANC 2.0)
            </h2>
            <p className="text-xs text-slate-400 font-semibold mt-0.5">
              AI-Powered Antenatal Care Monitoring &middot; Risk Assessment &middot; Smart Scheduling
            </p>
          </div>
          {selectedPreg && (
            <button onClick={() => { setSelectedPreg(null); setActiveTab('overview'); }}
              className="flex items-center gap-2 px-4 py-2 bg-slate-100 text-slate-700 rounded-xl text-xs font-bold hover:bg-slate-200 transition-all">
              <span className="material-symbols-outlined text-sm">arrow_back</span>
              Back to All Mothers
            </button>
          )}
        </div>
      </div>

      {/* KPI Cards */}
      {!selectedPreg && (
        <section className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'Total Pregnant', value: kpi.total, icon: 'pregnant_woman', iconColor: 'text-pink-500', bgColor: 'bg-pink-50' },
            { label: 'High Risk', value: kpi.highRisk, icon: 'warning', iconColor: 'text-rose-500', bgColor: 'bg-rose-50' },
            { label: 'ANC Due Today', value: kpi.ancDueToday, icon: 'event', iconColor: 'text-blue-500', bgColor: 'bg-blue-50' },
            { label: 'Missed ANC', value: kpi.missedAnc, icon: 'event_busy', iconColor: 'text-amber-500', bgColor: 'bg-amber-50' },
            { label: 'Due Tomorrow', value: kpi.ancDueTomorrow, icon: 'schedule', iconColor: 'text-indigo-500', bgColor: 'bg-indigo-50' },
            { label: 'Deliveries This Month', value: kpi.expectedThisMonth, icon: 'child_friendly', iconColor: 'text-emerald-500', bgColor: 'bg-emerald-50' },
            { label: 'TT Pending', value: kpi.ttPending, icon: 'vaccines', iconColor: 'text-orange-500', bgColor: 'bg-orange-50' },
            { label: 'Iron Pending', value: kpi.ironPending, icon: 'medication', iconColor: 'text-red-400', bgColor: 'bg-red-50' },
          ].map((card, i) => (
            <div key={i} className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 hover:-translate-y-0.5 transition-transform">
              <div className="flex items-center gap-3">
                <div className={`w-10 h-10 rounded-xl ${card.bgColor} ${card.iconColor} flex items-center justify-center`}>
                  <span className="material-symbols-outlined text-lg" style={{ fontVariationSettings: "'FILL' 1" }}>{card.icon}</span>
                </div>
                <div>
                  <span className="text-lg font-extrabold text-slate-800 leading-none block">{card.value}</span>
                  <span className="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider">{card.label}</span>
                </div>
              </div>
            </div>
          ))}
        </section>
      )}

      {/* Patient Cards Grid */}
      {!selectedPreg && (
        <section className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {pregList.map(preg => {
            const pd = preg.pregnancyDetails;
            const score = pd.riskScore || 0;
            const schedule = pd.ancSchedule || [];
            const completedVisits = schedule.filter(v => v.status === 'Completed').length;
            const eddDays = daysUntil(pd.edd);
            const medicines = pd.medicines || [];
            const completedMeds = medicines.filter(m => m.status === 'Completed').length;

            return (
              <div key={preg.id} className="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden hover:shadow-md transition-shadow">
                {pd.riskLevel === 'High' && (
                  <div className="bg-rose-500 text-white px-4 py-2 text-[10px] font-extrabold flex items-center gap-1.5 animate-pulse">
                    <span className="material-symbols-outlined text-sm">emergency</span>
                    HIGH RISK PREGNANCY — PRIORITY MONITORING REQUIRED
                  </div>
                )}
                <div className="p-5 space-y-4">
                  <div className="flex justify-between items-start">
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 rounded-2xl bg-pink-50 flex items-center justify-center overflow-hidden shrink-0">
                        {preg.photo ? (
                          <img src={preg.photo} alt="" className="w-full h-full object-cover" />
                        ) : (
                          <span className="material-symbols-outlined text-pink-400 text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>person</span>
                        )}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="text-sm font-extrabold text-slate-800">{preg.name}</h3>
                          <span className="text-[8px] font-bold text-slate-400 bg-slate-50 px-1.5 py-0.5 rounded">{pd.pregId || preg.id}</span>
                        </div>
                        <p className="text-[10px] text-slate-400 font-semibold">
                          {preg.age} yrs &middot; G{pd.gravida || '?'}P{pd.parity || '?'} &middot; {pd.bloodGroup || '—'} &middot; {preg.familyName}
                        </p>
                        {pd.husbandName && <p className="text-[10px] text-slate-400 font-semibold">H/o {pd.husbandName}</p>}
                      </div>
                    </div>
                    <RiskGauge score={score} size={56} />
                  </div>

                  <div className="grid grid-cols-4 gap-2">
                    <div className="bg-pink-50/60 rounded-xl p-2 text-center border border-pink-50">
                      <span className="block text-[8px] font-bold text-slate-400 uppercase">Gestation</span>
                      <span className="text-sm font-extrabold text-pink-700">{pd.weeks}w</span>
                    </div>
                    <div className="bg-blue-50/60 rounded-xl p-2 text-center border border-blue-50">
                      <span className="block text-[8px] font-bold text-slate-400 uppercase">Trimester</span>
                      <span className="text-sm font-extrabold text-blue-700">{pd.trimester}</span>
                    </div>
                    <div className="bg-emerald-50/60 rounded-xl p-2 text-center border border-emerald-50">
                      <span className="block text-[8px] font-bold text-slate-400 uppercase">EDD</span>
                      <span className="text-[10px] font-extrabold text-emerald-700">{formatDate(pd.edd)}</span>
                    </div>
                    <div className={`rounded-xl p-2 text-center border ${eddDays <= 7 ? 'bg-rose-50/60 border-rose-50' : eddDays <= 30 ? 'bg-amber-50/60 border-amber-50' : 'bg-slate-50/60 border-slate-50'}`}>
                      <span className="block text-[8px] font-bold text-slate-400 uppercase">Countdown</span>
                      <span className={`text-sm font-extrabold ${eddDays <= 7 ? 'text-rose-700' : eddDays <= 30 ? 'text-amber-700' : 'text-slate-700'}`}>{eddDays > 0 ? `${eddDays}d` : 'Due!'}</span>
                    </div>
                  </div>

                  {/* ANC Timeline */}
                  <div>
                    <p className="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider mb-2">ANC Visit Schedule</p>
                    <div className="flex items-center gap-1">
                      {schedule.map((v, i) => (
                        <div key={i} className="flex-1 flex flex-col items-center gap-1">
                          <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-extrabold ${
                            v.status === 'Completed' ? 'bg-emerald-500 text-white' :
                            v.status === 'Overdue' ? 'bg-rose-500 text-white animate-pulse' :
                            'bg-slate-100 text-slate-400 border border-slate-200'
                          }`}>{v.status === 'Completed' ? '\u2713' : v.visit}</div>
                          <span className="text-[7px] font-bold text-slate-400 text-center">{v.scheduledDate?.substring(5) || '—'}</span>
                        </div>
                      ))}
                      {schedule.length === 0 && <span className="text-[10px] text-slate-400 italic">No ANC schedule generated</span>}
                    </div>
                  </div>

                  {/* Medicine Progress */}
                  <div>
                    <div className="flex justify-between items-center mb-1">
                      <p className="text-[9px] font-extrabold text-slate-400 uppercase tracking-wider">Medicine Compliance</p>
                      <span className="text-[9px] font-bold text-emerald-600">{completedMeds}/{medicines.length}</span>
                    </div>
                    <div className="w-full h-1.5 bg-slate-100 rounded-full overflow-hidden">
                      <div className="h-full bg-emerald-500 rounded-full transition-all" style={{ width: `${medicines.length > 0 ? (completedMeds / medicines.length) * 100 : 0}%` }} />
                    </div>
                  </div>

                  {/* High Risk Alerts */}
                  {(pd.highRiskAlerts || []).length > 0 && (
                    <div className="bg-rose-50 border border-rose-100 rounded-xl p-2.5 space-y-1">
                      {pd.highRiskAlerts.map((a, i) => (
                        <p key={i} className="text-[10px] text-rose-700 font-bold flex items-center gap-1">
                          <span className="material-symbols-outlined text-xs">warning</span> {a}
                        </p>
                      ))}
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="flex gap-2 font-sans">
                    <button onClick={() => { setSelectedPreg(preg.id); setActiveTab('overview'); }}
                      className="flex-1 py-2 bg-[#003d29] text-white rounded-xl text-[10px] font-bold hover:brightness-110 flex items-center justify-center gap-1">
                      <span className="material-symbols-outlined text-sm">visibility</span> View Profile
                    </button>
                    <button onClick={() => {
                      const nextVisit = schedule.findIndex(v => v.status !== 'Completed');
                      if (nextVisit >= 0) setAncModal({ preg, visitIdx: nextVisit });
                    }}
                      className="flex-1 py-2 bg-pink-50 text-pink-700 rounded-xl text-[10px] font-bold hover:bg-pink-100 flex items-center justify-center gap-1 border border-pink-100">
                      <span className="material-symbols-outlined text-sm">edit_note</span> Record Visit
                    </button>
                    <button onClick={() => onSendSmsClick && onSendSmsClick(preg.id)}
                      title="Send ANC SMS Reminder"
                      className="px-3 py-2 bg-emerald-50 text-emerald-800 rounded-xl text-[10px] font-bold hover:bg-emerald-100 flex items-center justify-center gap-1 border border-emerald-100">
                      <span className="material-symbols-outlined text-sm">sms</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })}

          {pregList.length === 0 && (
            <div className="col-span-2 bg-white p-10 rounded-3xl border border-slate-100 shadow-sm text-center space-y-3">
              <span className="material-symbols-outlined text-5xl text-pink-200" style={{ fontVariationSettings: "'FILL' 1" }}>pregnant_woman</span>
              <p className="text-slate-400 text-sm font-semibold">No pregnant mothers registered yet.</p>
              <p className="text-slate-300 text-xs">Register a patient with &quot;Pregnant&quot; status to see ANC monitoring here.</p>
            </div>
          )}
        </section>
      )}

      {/* ═══════ EXPANDED PATIENT VIEW ═══════ */}
      {selectedPatient && (() => {
        const pd = selectedPatient.pregnancyDetails;
        const score = pd.riskScore || 0;
        const schedule = pd.ancSchedule || [];
        const medicines = pd.medicines || [];
        const vitalsHistory = pd.vitalsHistory || [];
        const eddDays = daysUntil(pd.edd);
        const babyGrowth = getBabyGrowthDesc(pd.weeks);

        const weightData = vitalsHistory.filter(v => v.weight).map(v => ({ label: `W${v.week}`, value: v.weight }));
        const hbData = vitalsHistory.filter(v => v.hb).map(v => ({ label: `W${v.week}`, value: v.hb }));
        const bpData = vitalsHistory.filter(v => v.bp).map(v => ({ label: `W${v.week}`, value: v.bp.split('/')[0] }));

        return (
          <div className="space-y-6">
            {/* Patient Profile Card */}
            <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-6">
              <div className="flex items-start gap-5">
                <div className="w-20 h-20 rounded-2xl bg-pink-50 flex items-center justify-center overflow-hidden shrink-0">
                  {selectedPatient.photo ? (
                    <img src={selectedPatient.photo} alt="" className="w-full h-full object-cover" />
                  ) : (
                    <span className="material-symbols-outlined text-pink-300 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>person</span>
                  )}
                </div>
                <div className="flex-1">
                  <div className="flex justify-between items-start">
                    <div>
                      <h3 className="text-lg font-extrabold text-slate-800">{selectedPatient.name}</h3>
                      <p className="text-xs text-slate-400 font-semibold">
                        {pd.pregId} &middot; {selectedPatient.age} yrs &middot; G{pd.gravida}P{pd.parity} &middot; {pd.bloodGroup || '—'}
                        {pd.husbandName ? ` \u00B7 H/o ${pd.husbandName}` : ''}
                      </p>
                      <p className="text-xs text-slate-400 font-semibold">{'\uD83D\uDCDE'} {selectedPatient.phone} &middot; {selectedPatient.address || selectedPatient.familyName}</p>
                    </div>
                    <RiskGauge score={score} size={72} />
                  </div>
                  <div className="grid grid-cols-6 gap-2 mt-4">
                    {[
                      { label: 'Gestation', value: `${pd.weeks} weeks`, color: 'text-pink-700' },
                      { label: 'Trimester', value: pd.trimester, color: 'text-blue-700' },
                      { label: 'EDD', value: formatDate(pd.edd), color: 'text-emerald-700' },
                      { label: 'Countdown', value: eddDays > 0 ? `${eddDays} days` : 'Due!', color: eddDays <= 7 ? 'text-rose-700' : 'text-slate-700' },
                      { label: 'Visits', value: `${pd.visits || 0} / 4`, color: 'text-indigo-700' },
                      { label: 'LMP', value: formatDate(pd.lmp), color: 'text-slate-600' },
                    ].map((s, i) => (
                      <div key={i} className="bg-slate-50 rounded-xl p-2 text-center border border-slate-100">
                        <span className="block text-[8px] font-bold text-slate-400 uppercase">{s.label}</span>
                        <span className={`text-[11px] font-extrabold ${s.color}`}>{s.value}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              {(pd.highRiskAlerts || []).length > 0 && (
                <div className="bg-rose-50 border border-rose-200 rounded-xl p-3 mt-4 space-y-1">
                  <p className="text-[10px] font-extrabold text-rose-700 uppercase tracking-wider flex items-center gap-1">
                    <span className="material-symbols-outlined text-sm">emergency</span> High Risk Alerts
                  </p>
                  {pd.highRiskAlerts.map((a, i) => <p key={i} className="text-xs text-rose-600 font-semibold">{'\u2022'} {a}</p>)}
                </div>
              )}
            </div>

            {/* Tab Navigation */}
            <div className="flex bg-white rounded-2xl p-1.5 shadow-sm border border-slate-100 gap-1">
              {[
                { id: 'overview', label: 'Overview', icon: 'dashboard' },
                { id: 'timeline', label: 'ANC Timeline', icon: 'timeline' },
                { id: 'medicines', label: 'Medicines', icon: 'medication' },
                { id: 'delivery', label: 'Delivery & PNC', icon: 'child_friendly' },
              ].map(tab => (
                <button key={tab.id} onClick={() => setActiveTab(tab.id)}
                  className={`flex-1 py-2.5 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition-all ${
                    activeTab === tab.id ? 'bg-[#003d29] text-white shadow-md' : 'text-slate-500 hover:bg-slate-50'
                  }`}>
                  <span className="material-symbols-outlined text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>{tab.icon}</span>
                  {tab.label}
                </button>
              ))}
            </div>

            {/* OVERVIEW TAB */}
            {activeTab === 'overview' && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-5 space-y-3">
                  <div className="flex items-center gap-2">
                    <span className="material-symbols-outlined text-pink-400" style={{ fontVariationSettings: "'FILL' 1" }}>child_care</span>
                    <span className="text-sm font-extrabold text-slate-800">Baby Growth — Week {pd.weeks}</span>
                  </div>
                  <div className="bg-pink-50/50 rounded-xl p-4 border border-pink-50 text-center space-y-2">
                    <p className="text-2xl">{'\uD83C\uDF7C'}</p>
                    <p className="text-xs font-extrabold text-pink-700">Size: {babyGrowth.size}</p>
                    <p className="text-[10px] text-pink-600 font-semibold">Length: {babyGrowth.length}</p>
                    <p className="text-[10px] text-slate-500 font-semibold">{babyGrowth.desc}</p>
                  </div>
                  <div className={`rounded-xl p-3 text-center border ${eddDays <= 14 ? 'bg-rose-50 border-rose-100' : 'bg-emerald-50 border-emerald-100'}`}>
                    <span className="block text-[9px] font-extrabold text-slate-400 uppercase">Expected Delivery</span>
                    <span className={`text-xl font-extrabold ${eddDays <= 14 ? 'text-rose-700' : 'text-emerald-700'}`}>
                      {eddDays > 0 ? `${eddDays} Days` : '\uD83C\uDF89 Due Today!'}
                    </span>
                    <span className="block text-[10px] text-slate-400 font-semibold">{formatDate(pd.edd)}</span>
                  </div>
                </div>
                <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-5 space-y-4">
                  <span className="text-sm font-extrabold text-slate-800 flex items-center gap-2">
                    <span className="material-symbols-outlined text-blue-400" style={{ fontVariationSettings: "'FILL' 1" }}>monitoring</span>
                    Vitals Trend
                  </span>
                  <MiniLineChart data={weightData} color="#ec4899" label="Weight Progress" unit="kg" />
                  <MiniLineChart data={hbData} color="#ef4444" label="Haemoglobin Trend" unit="g/dL" />
                  <MiniLineChart data={bpData} color="#f59e0b" label="BP Systolic Trend" unit="mmHg" />
                </div>
                <div className="lg:col-span-2 bg-white rounded-3xl shadow-sm border border-slate-100 p-5">
                  <div className="flex gap-3">
                    <button className="flex-1 py-3 bg-rose-500 text-white rounded-xl text-xs font-bold hover:bg-rose-600 flex items-center justify-center gap-2 transition-all">
                      <span className="material-symbols-outlined text-lg">emergency</span> Emergency SOS
                    </button>
                    <a href="https://www.google.com/maps/search/primary+health+centre+near+me" target="_blank" rel="noopener noreferrer"
                      className="flex-1 py-3 bg-blue-500 text-white rounded-xl text-xs font-bold hover:bg-blue-600 flex items-center justify-center gap-2 transition-all">
                      <span className="material-symbols-outlined text-lg">local_hospital</span> Nearby PHC Map
                    </a>
                    <button onClick={() => {
                      const nextVisit = schedule.findIndex(v => v.status !== 'Completed');
                      if (nextVisit >= 0) setAncModal({ preg: selectedPatient, visitIdx: nextVisit });
                    }}
                      className="flex-1 py-3 bg-[#003d29] text-white rounded-xl text-xs font-bold hover:brightness-110 flex items-center justify-center gap-2 transition-all">
                      <span className="material-symbols-outlined text-lg">edit_note</span> Record ANC Visit
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* TIMELINE TAB */}
            {activeTab === 'timeline' && (
              <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-6 space-y-6">
                <h3 className="text-sm font-extrabold text-slate-800 flex items-center gap-2">
                  <span className="material-symbols-outlined text-indigo-400" style={{ fontVariationSettings: "'FILL' 1" }}>timeline</span>
                  ANC Visit Timeline
                </h3>
                {schedule.map((v, i) => (
                  <div key={i} className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-extrabold shrink-0 ${
                        v.status === 'Completed' ? 'bg-emerald-500 text-white' :
                        v.status === 'Overdue' ? 'bg-rose-500 text-white' : 'bg-slate-200 text-slate-500'
                      }`}>{v.status === 'Completed' ? '\u2713' : v.visit}</div>
                      {i < schedule.length - 1 && <div className={`w-0.5 flex-1 min-h-[40px] ${v.status === 'Completed' ? 'bg-emerald-200' : 'bg-slate-200'}`} />}
                    </div>
                    <div className={`flex-1 p-4 rounded-2xl border mb-2 ${
                      v.status === 'Completed' ? 'bg-emerald-50/50 border-emerald-100' :
                      v.status === 'Overdue' ? 'bg-rose-50/50 border-rose-100' : 'bg-slate-50/50 border-slate-100'
                    }`}>
                      <div className="flex justify-between items-start">
                        <div>
                          <p className="text-xs font-extrabold text-slate-800">{v.label}</p>
                          <p className="text-[10px] text-slate-400 font-semibold">Scheduled: {formatDate(v.scheduledDate)}</p>
                        </div>
                        <span className={`text-[9px] font-extrabold px-2 py-0.5 rounded-md ${
                          v.status === 'Completed' ? 'bg-emerald-100 text-emerald-700' :
                          v.status === 'Overdue' ? 'bg-rose-100 text-rose-700' : 'bg-slate-100 text-slate-500'
                        }`}>{v.status}</span>
                      </div>
                      {v.data && (
                        <div className="grid grid-cols-4 gap-2 mt-3">
                          {v.data.weight && <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">Weight</span><span className="text-[11px] font-extrabold text-slate-700">{v.data.weight} kg</span></div>}
                          {v.data.bp && <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">BP</span><span className="text-[11px] font-extrabold text-slate-700">{v.data.bp}</span></div>}
                          {v.data.haemoglobin && <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">HB</span><span className="text-[11px] font-extrabold text-slate-700">{v.data.haemoglobin} g/dL</span></div>}
                          {v.data.fetalHeartRate && <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">FHR</span><span className="text-[11px] font-extrabold text-slate-700">{v.data.fetalHeartRate} bpm</span></div>}
                          {v.data.doctor && <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">Doctor</span><span className="text-[11px] font-bold text-slate-600">{v.data.doctor}</span></div>}
                          {v.data.notes && <div className="col-span-3"><span className="block text-[8px] text-slate-400 font-bold uppercase">Notes</span><span className="text-[10px] text-slate-600 font-semibold">{v.data.notes}</span></div>}
                        </div>
                      )}
                      {v.status !== 'Completed' && (
                        <button onClick={() => setAncModal({ preg: selectedPatient, visitIdx: i })}
                          className="mt-3 w-full py-2 bg-[#003d29] text-white rounded-xl text-[10px] font-bold hover:brightness-110 flex items-center justify-center gap-1">
                          <span className="material-symbols-outlined text-sm">edit_note</span> Record This Visit
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* MEDICINES TAB */}
            {activeTab === 'medicines' && (
              <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-6 space-y-4">
                <h3 className="text-sm font-extrabold text-slate-800 flex items-center gap-2">
                  <span className="material-symbols-outlined text-orange-400" style={{ fontVariationSettings: "'FILL' 1" }}>medication</span>
                  Medicine & Supplement Tracker
                </h3>
                <div className="space-y-3">
                  {medicines.map((med, i) => {
                    const pct = med.totalDays > 0 ? Math.min(100, (med.takenDays / med.totalDays) * 100) : 0;
                    return (
                      <div key={i} className="bg-slate-50 rounded-2xl p-4 border border-slate-100 space-y-2">
                        <div className="flex justify-between items-start">
                          <div>
                            <p className="text-xs font-extrabold text-slate-800">{med.name}</p>
                            <p className="text-[10px] text-slate-400 font-semibold">{med.dosage}</p>
                          </div>
                          <span className={`text-[9px] font-extrabold px-2.5 py-1 rounded-lg border ${
                            med.status === 'Completed' ? 'bg-emerald-50 border-emerald-100 text-emerald-700' : 'bg-amber-50 border-amber-100 text-amber-700'
                          }`}>{med.status}</span>
                        </div>
                        <div className="flex items-center gap-3">
                          <div className="flex-1 h-2 bg-slate-200 rounded-full overflow-hidden">
                            <div className={`h-full rounded-full transition-all ${med.status === 'Completed' ? 'bg-emerald-500' : 'bg-amber-500'}`} style={{ width: `${pct}%` }} />
                          </div>
                          <span className="text-[10px] font-bold text-slate-500">{med.takenDays}/{med.totalDays}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* DELIVERY & PNC TAB */}
            {activeTab === 'delivery' && (
              <div className="space-y-6">
                <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-6 space-y-4">
                  <h3 className="text-sm font-extrabold text-slate-800 flex items-center gap-2">
                    <span className="material-symbols-outlined text-emerald-400" style={{ fontVariationSettings: "'FILL' 1" }}>child_friendly</span>
                    Delivery Tracker
                  </h3>
                  {pd.delivery ? (
                    <div className="bg-emerald-50 rounded-2xl p-4 border border-emerald-100 space-y-3">
                      <p className="text-xs font-extrabold text-emerald-800">{'\u2713'} Delivery Recorded</p>
                      <div className="grid grid-cols-3 gap-3">
                        <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">Date</span><span className="text-xs font-bold text-slate-700">{formatDate(pd.delivery.date)}</span></div>
                        <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">Type</span><span className="text-xs font-bold text-slate-700">{pd.delivery.type}</span></div>
                        <div className="text-center"><span className="block text-[8px] text-slate-400 font-bold uppercase">Baby Weight</span><span className="text-xs font-bold text-slate-700">{pd.delivery.babyWeight} kg</span></div>
                      </div>
                    </div>
                  ) : (
                    <div className="bg-amber-50/50 rounded-2xl p-4 border border-amber-100 text-center space-y-2">
                      <span className="material-symbols-outlined text-3xl text-amber-300">pending</span>
                      <p className="text-xs text-amber-600 font-semibold">Delivery not yet recorded &middot; EDD: {formatDate(pd.edd)} ({eddDays > 0 ? `${eddDays} days away` : 'Due'})</p>
                    </div>
                  )}
                </div>
                <div className="bg-white rounded-3xl shadow-sm border border-slate-100 p-6 space-y-4">
                  <h3 className="text-sm font-extrabold text-slate-800 flex items-center gap-2">
                    <span className="material-symbols-outlined text-purple-400" style={{ fontVariationSettings: "'FILL' 1" }}>health_and_safety</span>
                    Postnatal Care (PNC) Schedule
                  </h3>
                  {pd.pncSchedule ? (
                    <div className="space-y-2">
                      {pd.pncSchedule.map((pnc, i) => (
                        <div key={i} className={`flex items-center gap-3 p-3 rounded-xl border ${pnc.status === 'Completed' ? 'bg-emerald-50 border-emerald-100' : 'bg-slate-50 border-slate-100'}`}>
                          <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-extrabold ${pnc.status === 'Completed' ? 'bg-emerald-500 text-white' : 'bg-slate-200 text-slate-500'}`}>{pnc.status === 'Completed' ? '\u2713' : i + 1}</div>
                          <div className="flex-1">
                            <p className="text-xs font-bold text-slate-700">{pnc.label}</p>
                            <p className="text-[10px] text-slate-400 font-semibold">{formatDate(pnc.date)}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="bg-slate-50 rounded-2xl p-4 border border-slate-100 text-center space-y-2">
                      <span className="material-symbols-outlined text-3xl text-slate-300">event_note</span>
                      <p className="text-xs text-slate-400 font-semibold">PNC schedule will be auto-generated after delivery is recorded.</p>
                      <p className="text-[10px] text-slate-400">Includes: Day 1, Day 3, Day 7, and 6-Week visits</p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        );
      })()}

      {/* ANC Visit Recording Modal */}
      {ancModal && (
        <AncVisitModal
          preg={ancModal.preg}
          visitIdx={ancModal.visitIdx}
          onSave={handleSaveAncVisit}
          onClose={() => setAncModal(null)}
        />
      )}
    </div>
  );
}
