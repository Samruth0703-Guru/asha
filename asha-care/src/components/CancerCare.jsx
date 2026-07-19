import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function CancerCare() {
  const [families, setFamilies] = useState([]);
  const [currentRole, setCurrentRole] = useState('ASHA Worker'); // ASHA Worker, Nurse, Doctor, Administrator
  const [activeTab, setActiveTab] = useState('dashboard'); // 'dashboard', 'screenings', 'register_screening', 'referrals', 'treatment', 'audit_logs'
  const [selectedPatientId, setSelectedPatientId] = useState('');

  // Stats State
  const [stats, setStats] = useState({
    totalScreened: 58,
    highRisk: 12,
    underTreatment: 9,
    completedTreatment: 4,
    missedFollowUps: 3,
    pendingReferrals: 2
  });

  // Screening Registry state
  const [screenings, setScreenings] = useState([
    { id: 'PT001', name: 'Saraswathi Devi', age: 34, gender: 'Female', oral: 'Negative', breast: 'Negative', cervical: 'Negative', riskLevel: 'Low Risk', status: 'Screened' },
    { id: 'PT002', name: 'Rani K', age: 48, gender: 'Female', oral: 'Leukoplakia', breast: 'Lump Detected', cervical: 'VIA Positive', riskLevel: 'High Risk', status: 'Referred' },
    { id: 'PT003', name: 'Muthu Krishnan', age: 52, gender: 'Male', oral: 'Ulcer (Non-healing)', breast: 'N/A', cervical: 'N/A', riskLevel: 'Critical Risk', status: 'Under Treatment' },
    { id: 'PT004', name: 'Meenakshi Sundaram', age: 41, gender: 'Female', oral: 'Negative', breast: 'Pain/Tenderness', cervical: 'VIA Negative', riskLevel: 'Medium Risk', status: 'Follow-up Scheduled' }
  ]);

  // Form states for new screening
  const [oralFinding, setOralFinding] = useState('Negative');
  const [breastFinding, setBreastFinding] = useState('Negative');
  const [cervicalFinding, setCervicalFinding] = useState('Negative');
  const [referralHospital, setReferralHospital] = useState('District PHC');
  const [urgency, setUrgency] = useState('Routine');

  // Treatment Follow-ups state
  const [treatments, setTreatments] = useState([
    { id: 'TRT-102', patientName: 'Muthu Krishnan', regimen: 'Chemotherapy Cycle 3', status: 'Under Treatment', compliance: 'High', nextVisit: '24 Jul 2025' },
    { id: 'TRT-105', patientName: 'Rani K', regimen: 'Biopsy Evaluation', status: 'Pending Results', compliance: 'Medium', nextVisit: '20 Jul 2025' }
  ]);

  // Security Audit Logs mimicking the Flutter version
  const [auditLogs, setAuditLogs] = useState([
    { timestamp: '19 Jul 2026, 07:44 AM', user: 'LAKSHMI_001', role: 'ASHA Worker', action: 'ROLE_SWITCH', details: 'Swapped tester role profile to: ASHA Worker' },
    { timestamp: '19 Jul 2026, 06:12 AM', user: 'DR_RAJESH_002', role: 'Doctor', action: 'REFERRAL_ISSUE', details: 'Issued emergency referral for Rani K to General Hospital' },
    { timestamp: '18 Jul 2026, 04:30 PM', user: 'NURSE_DEVI', role: 'Nurse', action: 'SCREENING_SUBMIT', details: 'Submitted breast exam screening results for Meenakshi Sundaram' }
  ]);

  useEffect(() => {
    const list = getStoredFamilies();
    setFamilies(list);
    if (list.length > 0 && list[0].members.length > 0) {
      setSelectedPatientId(list[0].members[0].id);
    }
  }, []);

  const allPatients = [];
  families.forEach(fam => {
    fam.members.forEach(m => {
      if (m.age >= 30) {
        allPatients.push({ ...m, familyId: fam.id, familyName: fam.name });
      }
    });
  });

  const selectedPatient = allPatients.find(p => p.id === selectedPatientId) || allPatients[0];

  const logAuditAction = (action, details) => {
    const newLog = {
      timestamp: new Date().toLocaleString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
      user: currentRole === 'Doctor' ? 'DR_RAJESH_002' : currentRole === 'Nurse' ? 'NURSE_DEVI' : 'LAKSHMI_001',
      role: currentRole,
      action,
      details
    };
    setAuditLogs(prev => [newLog, ...prev]);
  };

  const handleRegisterScreening = (e) => {
    e.preventDefault();
    if (!selectedPatient) return;

    let computedRisk = 'Low Risk';
    if (oralFinding !== 'Negative' || breastFinding === 'Lump Detected' || cervicalFinding === 'VIA Positive') {
      computedRisk = 'High Risk';
    } else if (breastFinding !== 'Negative' || cervicalFinding !== 'Negative') {
      computedRisk = 'Medium Risk';
    }

    const newScreening = {
      id: selectedPatient.id,
      name: selectedPatient.name,
      age: selectedPatient.age,
      gender: selectedPatient.gender,
      oral: oralFinding,
      breast: breastFinding,
      cervical: cervicalFinding,
      riskLevel: computedRisk,
      status: computedRisk === 'High Risk' ? 'Referred' : 'Screened'
    };

    setScreenings(prev => [newScreening, ...prev]);
    setStats(prev => ({
      ...prev,
      totalScreened: prev.totalScreened + 1,
      highRisk: computedRisk === 'High Risk' ? prev.highRisk + 1 : prev.highRisk,
      pendingReferrals: computedRisk === 'High Risk' ? prev.pendingReferrals + 1 : prev.pendingReferrals
    }));

    logAuditAction('SCREENING_SUBMIT', `Submitted new cancer screening for patient ${selectedPatient.name}. Risk Assessment: ${computedRisk}`);
    setActiveTab('screenings');

    // Reset Form
    setOralFinding('Negative');
    setBreastFinding('Negative');
    setCervicalFinding('Negative');
  };

  const handleIssueReferral = (patientId, name) => {
    setStats(prev => ({ ...prev, pendingReferrals: prev.pendingReferrals - 1, underTreatment: prev.underTreatment + 1 }));
    setScreenings(prev => prev.map(s => s.id === patientId ? { ...s, status: 'Under Treatment' } : s));
    
    // Add to ongoing treatments list
    const newTrt = {
      id: `TRT-${Math.floor(100 + Math.random() * 900)}`,
      patientName: name,
      regimen: `Evaluation at ${referralHospital}`,
      status: 'Under Treatment',
      compliance: 'High',
      nextVisit: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
    };
    setTreatments(prev => [newTrt, ...prev]);

    logAuditAction('REFERRAL_ISSUE', `Authorized clinical referral for ${name} to ${referralHospital} with urgency: ${urgency}`);
    alert(`Referral successfully dispatched for ${name} to ${referralHospital}`);
  };

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      
      {/* Top Header section with Secure Role Switcher */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-100 pb-5">
        <div>
          <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <span className="material-symbols-outlined text-emerald-700 text-2xl">shield_moon</span>
            ASHA Care+ Oncology Portal
          </h2>
          <p className="text-xs text-slate-400 font-semibold mt-0.5">
            Non-Communicable Diseases (NCD) screening, referral pathways, and treatment tracking.
          </p>
        </div>

        <div className="flex items-center gap-3">
          {/* Secure Role Switcher Widget resembling the Flutter version */}
          <div className="flex items-center bg-slate-50 border border-slate-200 px-3 py-1.5 rounded-xl gap-2">
            <span className="material-symbols-outlined text-slate-400 text-sm">vpn_key</span>
            <span className="text-[10px] text-slate-400 font-extrabold uppercase tracking-wide">Test Profile:</span>
            <select
              className="bg-transparent border-0 text-xs font-bold text-[#003d29] outline-none cursor-pointer"
              value={currentRole}
              onChange={(e) => {
                setCurrentRole(e.target.value);
                logAuditAction('ROLE_SWITCH', `Swapped tester role profile to: ${e.target.value}`);
              }}
            >
              <option value="ASHA Worker">ASHA Worker</option>
              <option value="Nurse">Nurse</option>
              <option value="Doctor">PHC Doctor</option>
              <option value="Administrator">Administrator</option>
            </select>
          </div>
        </div>
      </div>

      {/* Stats Counter Row */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {[
          { label: 'Total Screened', count: stats.totalScreened, color: 'text-blue-700', bg: 'bg-blue-50 border-blue-100' },
          { label: 'High Risk Cases', count: stats.highRisk, color: 'text-rose-700', bg: 'bg-rose-50 border-rose-100' },
          { label: 'Under Treatment', count: stats.underTreatment, color: 'text-emerald-700', bg: 'bg-emerald-50 border-emerald-100' },
          { label: 'Completed Care', count: stats.completedTreatment, color: 'text-teal-700', bg: 'bg-teal-50 border-teal-100' },
          { label: 'Missed Follow-Ups', count: stats.missedFollowUps, color: 'text-amber-700', bg: 'bg-amber-50 border-amber-100' },
          { label: 'Pending Referrals', count: stats.pendingReferrals, color: 'text-indigo-700', bg: 'bg-indigo-50 border-indigo-100' },
        ].map((item, idx) => (
          <div key={idx} className={`p-4 rounded-2xl border ${item.bg}`}>
            <span className="block text-[9px] text-slate-400 font-bold uppercase tracking-wider">{item.label}</span>
            <strong className={`text-xl font-black ${item.color} mt-1 block`}>{item.count}</strong>
          </div>
        ))}
      </div>

      {/* Navigation Sub-Tabs */}
      <div className="flex border-b border-slate-100 gap-1 overflow-x-auto">
        {[
          { id: 'dashboard', label: 'Oncology Console', icon: 'grid_view' },
          { id: 'screenings', label: 'Screening Logs', icon: 'list_alt' },
          { id: 'register_screening', label: 'New Screening', icon: 'medical_services', roleRestricted: ['ASHA Worker', 'Nurse'] },
          { id: 'referrals', label: 'Clinical Referrals', icon: 'share_location', roleRestricted: ['Doctor'] },
          { id: 'treatment', label: 'Treatments & Follow-up', icon: 'vaccines' },
          { id: 'audit_logs', label: 'Security Audit Logs', icon: 'security', roleRestricted: ['Administrator'] }
        ].map(tab => {
          // Check role restrictions
          if (tab.roleRestricted && !tab.roleRestricted.includes(currentRole)) return null;

          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-1.5 px-4 py-3 border-b-2 font-bold text-xs transition-colors shrink-0 ${
                isActive
                  ? 'border-emerald-600 text-emerald-800'
                  : 'border-transparent text-slate-400 hover:text-slate-700'
              }`}
            >
              <span className="material-symbols-outlined text-sm">{tab.icon}</span>
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Contents: Dashboard overview */}
      {activeTab === 'dashboard' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Info */}
          <div className="lg:col-span-2 space-y-4">
            <div className="bg-slate-50 border border-slate-150 p-5 rounded-3xl space-y-2">
              <span className="text-[10px] font-extrabold text-[#003d29] uppercase tracking-wide">ASHA NCD Mandate</span>
              <h3 className="text-base font-bold text-slate-800">Operational Clinical Protocols</h3>
              <p className="text-xs text-slate-500 leading-relaxed font-semibold">
                Every resident aged 30 and older should undergo routine cancer screenings annually. Identify warning signs early through physical visual checks (Oral Leukoplakia, Breast Palpable Lumps, Cervical VIA testing). High-risk cases are immediately routed through primary health center referrals.
              </p>
            </div>

            {/* Campaign info or quick list */}
            <div className="border border-slate-100 p-5 rounded-3xl space-y-3">
              <h4 className="text-xs font-bold text-slate-700">Eligible Screened Population (Block Center)</h4>
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-[#f0f9f6] p-4 rounded-2xl flex items-center justify-between">
                  <div>
                    <span className="text-[9px] text-slate-400 font-extrabold uppercase">ASHA Screenings Target</span>
                    <p className="text-lg font-black text-[#003d29] mt-0.5">85% Completed</p>
                  </div>
                  <span className="material-symbols-outlined text-emerald-600 text-3xl">task_alt</span>
                </div>
                <div className="bg-rose-50 p-4 rounded-2xl flex items-center justify-between">
                  <div>
                    <span className="text-[9px] text-slate-400 font-extrabold uppercase">Outstanding High Risk</span>
                    <p className="text-lg font-black text-rose-700 mt-0.5">{stats.highRisk} Cases</p>
                  </div>
                  <span className="material-symbols-outlined text-rose-600 text-3xl">warning</span>
                </div>
              </div>
            </div>
          </div>

          {/* Quick clinical referral tips */}
          <div className="lg:col-span-1 border border-slate-100 p-5 rounded-3xl space-y-4">
            <h3 className="text-xs font-bold text-slate-700">Clinical Guidelines</h3>
            <div className="space-y-3">
              <div className="border-l-4 border-rose-500 pl-3">
                <strong className="block text-xs text-slate-800">Oral Visual Inspection</strong>
                <p className="text-[10px] text-slate-400 mt-0.5">Check for whitish/reddish non-healing ulcers or patches persisting for 14+ days.</p>
              </div>
              <div className="border-l-4 border-amber-500 pl-3">
                <strong className="block text-xs text-slate-800">Clinical Breast Exam</strong>
                <p className="text-[10px] text-slate-400 mt-0.5">Inspect for hard, painless lumps, skin dimpling, or unilateral discharge.</p>
              </div>
              <div className="border-l-4 border-indigo-500 pl-3">
                <strong className="block text-xs text-slate-800">Cervical VIA Screening</strong>
                <p className="text-[10px] text-slate-400 mt-0.5">Visual inspection with 3-5% acetic acid. Sharp acetowhite lesions imply positive screening.</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tab Contents: Screening Logs */}
      {activeTab === 'screenings' && (
        <div className="border border-slate-100 rounded-3xl overflow-hidden">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-slate-100 text-slate-400 font-bold uppercase text-[9px] tracking-wider bg-slate-50/50">
                <th className="p-4">Patient ID</th>
                <th className="p-4">Name</th>
                <th className="p-4">Age/Gender</th>
                <th className="p-4">Oral Finding</th>
                <th className="p-4">Breast Finding</th>
                <th className="p-4">Cervical (VIA)</th>
                <th className="p-4">Risk Evaluation</th>
                <th className="p-4">Care Pathway</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700 font-semibold">
              {screenings.map((s, idx) => (
                <tr key={idx} className="hover:bg-slate-50/50">
                  <td className="p-4 font-mono text-emerald-700 font-bold">{s.id}</td>
                  <td className="p-4 text-slate-850 font-bold">{s.name}</td>
                  <td className="p-4">{s.age} Y / {s.gender}</td>
                  <td className="p-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${s.oral === 'Negative' ? 'bg-emerald-50 text-emerald-800' : 'bg-rose-50 text-rose-700'}`}>
                      {s.oral}
                    </span>
                  </td>
                  <td className="p-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${s.breast === 'Negative' ? 'bg-emerald-50 text-emerald-800' : 'bg-rose-50 text-rose-700'}`}>
                      {s.breast}
                    </span>
                  </td>
                  <td className="p-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${s.cervical === 'Negative' ? 'bg-emerald-50 text-emerald-800' : s.cervical === 'N/A' ? 'bg-slate-50 text-slate-400' : 'bg-rose-50 text-rose-700'}`}>
                      {s.cervical}
                    </span>
                  </td>
                  <td className="p-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-extrabold uppercase ${
                      s.riskLevel === 'Critical Risk' || s.riskLevel === 'High Risk'
                        ? 'bg-rose-50 text-rose-700 border border-rose-100'
                        : s.riskLevel === 'Medium Risk'
                          ? 'bg-amber-50 text-amber-700 border border-amber-100'
                          : 'bg-emerald-50 text-emerald-700 border border-emerald-100'
                    }`}>
                      {s.riskLevel}
                    </span>
                  </td>
                  <td className="p-4">
                    <span className="bg-slate-100 text-slate-700 border border-slate-200 px-2 py-0.5 rounded text-[10px] font-bold">
                      {s.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Tab Contents: Register screening form */}
      {activeTab === 'register_screening' && (
        <form onSubmit={handleRegisterScreening} className="border border-slate-100 rounded-3xl p-5 space-y-5 max-w-2xl">
          <div>
            <h3 className="text-sm font-bold text-slate-800">Add New NCD &amp; Cancer Screening Profile</h3>
            <p className="text-xs text-slate-400 mt-0.5">Please ensure patient demographics match national program records.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Select Patient</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none focus:bg-white"
                value={selectedPatientId}
                onChange={e => setSelectedPatientId(e.target.value)}
              >
                {allPatients.map(p => (
                  <option key={p.id} value={p.id}>{p.name} ({p.age} Yrs - {p.id})</option>
                ))}
              </select>
            </div>
            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Oral Exam Finding</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none focus:bg-white"
                value={oralFinding}
                onChange={e => setOralFinding(e.target.value)}
              >
                <option value="Negative">Negative (Normal)</option>
                <option value="Leukoplakia">Leukoplakia (Whitish patch)</option>
                <option value="Erythroplakia">Erythroplakia (Reddish patch)</option>
                <option value="Ulcer (Non-healing)">Ulcer (Non-healing &gt; 2 weeks)</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Breast Exam Finding</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none"
                value={breastFinding}
                onChange={e => setBreastFinding(e.target.value)}
              >
                <option value="Negative">Negative (Normal)</option>
                <option value="Lump Detected">Palpable Lump Detected</option>
                <option value="Pain/Tenderness">Unilateral Pain/Tenderness</option>
                <option value="Nipple Discharge">Nipple Discharge / Retraction</option>
              </select>
            </div>
            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Cervical Examination (VIA)</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none"
                value={cervicalFinding}
                onChange={e => setCervicalFinding(e.target.value)}
              >
                <option value="Negative">Negative (VIA Normal)</option>
                <option value="VIA Positive">Positive (Acetowhite lesions)</option>
                <option value="N/A">Not Applicable / Male Patient</option>
              </select>
            </div>
          </div>

          <div className="flex justify-end pt-3">
            <button
              type="submit"
              className="px-5 py-2.5 bg-[#003d29] hover:brightness-110 text-white font-bold rounded-xl text-xs transition-all active:scale-95"
            >
              Submit &amp; Risk Evaluate
            </button>
          </div>
        </form>
      )}

      {/* Tab Contents: Clinical Referrals */}
      {activeTab === 'referrals' && (
        <div className="space-y-5">
          <div className="bg-slate-50 border border-slate-150 p-5 rounded-3xl">
            <h3 className="text-sm font-bold text-slate-800">Pending Referrals Desk (Medical Officer Profile)</h3>
            <p className="text-xs text-slate-400 mt-0.5">As a Medical Officer, review high-risk screenings and issue formal oncology clinic referrals.</p>
          </div>

          <div className="border border-slate-100 rounded-3xl overflow-hidden">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-100 text-slate-400 font-bold uppercase text-[9px] tracking-wider bg-slate-50/50">
                  <th className="p-4">Patient Name</th>
                  <th className="p-4">Risk Level</th>
                  <th className="p-4">Abnormal Findings</th>
                  <th className="p-4">Referral Center</th>
                  <th className="p-4">Priority</th>
                  <th className="p-4">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-slate-700 font-semibold">
                {screenings.filter(s => s.status === 'Referred').map((s, idx) => (
                  <tr key={idx} className="hover:bg-slate-50/50">
                    <td className="p-4 font-bold text-slate-800">{s.name}</td>
                    <td className="p-4">
                      <span className="bg-rose-50 text-rose-700 border border-rose-100 px-2.5 py-0.5 rounded text-[10px] uppercase font-bold">
                        {s.riskLevel}
                      </span>
                    </td>
                    <td className="p-4 text-xs font-semibold text-slate-500">
                      Oral: {s.oral} • Breast: {s.breast} • VIA: {s.cervical}
                    </td>
                    <td className="p-4">
                      <select 
                        className="bg-white border border-slate-200 rounded-lg p-1 text-xs font-bold"
                        value={referralHospital}
                        onChange={e => setReferralHospital(e.target.value)}
                      >
                        <option value="District General Hospital">District General Hospital</option>
                        <option value="Regional Cancer Care Center">Regional Cancer Center</option>
                        <option value="Taluk Oncology Unit">Taluk Oncology Unit</option>
                      </select>
                    </td>
                    <td className="p-4">
                      <select 
                        className="bg-white border border-slate-200 rounded-lg p-1 text-xs font-bold"
                        value={urgency}
                        onChange={e => setUrgency(e.target.value)}
                      >
                        <option value="Routine">Routine</option>
                        <option value="Urgent">Urgent</option>
                        <option value="Emergency">Emergency</option>
                      </select>
                    </td>
                    <td className="p-4">
                      <button
                        onClick={() => handleIssueReferral(s.id, s.name)}
                        className="px-3.5 py-1.5 bg-[#003d29] hover:brightness-110 text-white rounded-lg text-xs font-bold transition-all"
                      >
                        Authorize &amp; Sign
                      </button>
                    </td>
                  </tr>
                ))}
                {screenings.filter(s => s.status === 'Referred').length === 0 && (
                  <tr>
                    <td colSpan="6" className="text-center py-6 text-slate-400 italic">No pending referrals waiting for approval.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab Contents: Treatments & Follow-ups */}
      {activeTab === 'treatment' && (
        <div className="space-y-5">
          <div>
            <h3 className="text-sm font-bold text-slate-800">Oncology Treatment &amp; Compliance Log</h3>
            <p className="text-xs text-slate-400 mt-0.5">Track patient treatment compliance, chemotherapy follow-up, and home monitoring.</p>
          </div>

          <div className="border border-slate-100 rounded-3xl overflow-hidden">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-100 text-slate-400 font-bold uppercase text-[9px] tracking-wider bg-slate-50/50">
                  <th className="p-4">ID</th>
                  <th className="p-4">Patient Name</th>
                  <th className="p-4">Regimen / Clinic</th>
                  <th className="p-4">Status</th>
                  <th className="p-4">Medication Compliance</th>
                  <th className="p-4">Next Scheduled Visit</th>
                  <th className="p-4">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-slate-700 font-semibold">
                {treatments.map((t, idx) => (
                  <tr key={idx} className="hover:bg-slate-50/50">
                    <td className="p-4 font-mono text-emerald-700 font-bold">{t.id}</td>
                    <td className="p-4 text-slate-800 font-bold">{t.patientName}</td>
                    <td className="p-4">{t.regimen}</td>
                    <td className="p-4">
                      <span className="bg-emerald-50 text-emerald-800 border border-emerald-100 px-2 py-0.5 rounded text-[10px] font-bold">
                        {t.status}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        t.compliance === 'High' 
                          ? 'bg-emerald-50 text-emerald-800' 
                          : t.compliance === 'Medium' 
                            ? 'bg-amber-50 text-amber-800' 
                            : 'bg-rose-50 text-rose-800'
                      }`}>
                        {t.compliance} Compliance
                      </span>
                    </td>
                    <td className="p-4 text-slate-400">{t.nextVisit}</td>
                    <td className="p-4">
                      <button
                        onClick={() => {
                          alert(`Home visit scheduled for ${t.patientName} on ${t.nextVisit}. SMS notification sent to family.`);
                          logAuditAction('VISIT_SCHEDULE', `Scheduled cancer care follow-up visit for ${t.patientName}`);
                        }}
                        className="px-3 py-1.5 bg-emerald-50 text-emerald-800 hover:bg-emerald-100 rounded-lg text-xs font-bold transition-all"
                      >
                        Schedule Visit
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab Contents: Security Audit Logs */}
      {activeTab === 'audit_logs' && (
        <div className="space-y-4">
          <div className="bg-slate-50 border border-slate-150 p-5 rounded-3xl">
            <h3 className="text-sm font-bold text-slate-800 flex items-center gap-1.5">
              <span className="material-symbols-outlined text-slate-600 text-lg">admin_panel_settings</span>
              Cryptographic Audit Logs (Federal Security Mandate)
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">FEDERAL MANDATE: Logs trace all user switches, screening submissions, and referral signings.</p>
          </div>

          <div className="border border-slate-100 rounded-3xl overflow-hidden">
            <table className="w-full text-left text-xs border-collapse">
              <thead>
                <tr className="border-b border-slate-100 text-slate-400 font-bold uppercase text-[9px] tracking-wider bg-slate-50/50">
                  <th className="p-4">Timestamp</th>
                  <th className="p-4">User ID</th>
                  <th className="p-4">Role Profile</th>
                  <th className="p-4">Action Code</th>
                  <th className="p-4">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-slate-600 font-semibold font-mono text-[11px]">
                {auditLogs.map((log, idx) => (
                  <tr key={idx} className="hover:bg-slate-50/50">
                    <td className="p-4 text-slate-400">{log.timestamp}</td>
                    <td className="p-4 text-[#003d29] font-bold">{log.user}</td>
                    <td className="p-4 text-slate-500">{log.role}</td>
                    <td className="p-4 text-emerald-800 font-bold">{log.action}</td>
                    <td className="p-4 text-slate-700 font-sans font-medium">{log.details}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

    </div>
  );
}
