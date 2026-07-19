import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function Dashboard({ familyId, activeMemberId }) {
  const [families, setFamilies] = useState([]);
  const [currentFamily, setCurrentFamily] = useState(null);
  const [selectedMemberId, setSelectedMemberId] = useState(activeMemberId || '');

  useEffect(() => {
    const load = () => {
      const list = getStoredFamilies();
      setFamilies(list);
      if (familyId) {
        const fam = list.find(f => f.id === familyId);
        setCurrentFamily(fam);
        if (fam && !selectedMemberId) {
          setSelectedMemberId(fam.members[0]?.id || '');
        }
      }
    };
    load();
    window.addEventListener('asha_data_changed', load);
    return () => window.removeEventListener('asha_data_changed', load);
  }, [familyId, activeMemberId]);

  if (!currentFamily) {
    return (
      <div className="bg-white p-10 rounded-3xl shadow-sm border border-slate-100 text-center space-y-3">
        <div className="w-14 h-14 rounded-2xl bg-emerald-50 flex items-center justify-center mx-auto">
          <span className="material-symbols-outlined text-emerald-600 text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>group</span>
        </div>
        <h3 className="text-lg font-bold text-slate-800">No Family Selected</h3>
        <p className="text-sm text-slate-400 font-semibold">Please scan a fingerprint or select a patient to view their health profile.</p>
      </div>
    );
  }

  const selectedMember = currentFamily.members.find(m => m.id === selectedMemberId) || currentFamily.members[0];

  return (
    <div className="space-y-6">

      {/* ── Household Header ──────────────────────────────────────────────── */}
      <div className="bg-[#003d29] text-white p-6 rounded-3xl shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4 relative overflow-hidden">
        <div className="z-10 space-y-1">
          <span className="text-[10px] font-extrabold uppercase tracking-widest text-emerald-300">
            Household Profile
          </span>
          <h2 className="text-2xl font-extrabold">{currentFamily.name}</h2>
          <p className="text-sm text-emerald-200 font-semibold">
            Family ID: <strong className="text-white">{currentFamily.id}</strong>
            &nbsp;•&nbsp; Phone: {currentFamily.phone}
          </p>
        </div>
        <div className="z-10 bg-white/10 border border-white/20 px-4 py-3 rounded-2xl text-sm font-semibold text-emerald-100 max-w-sm">
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-emerald-300 block mb-0.5">Address</span>
          {currentFamily.address}
        </div>
      </div>

      {/* ── Main Grid ─────────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Left Column */}
        <div className="lg:col-span-2 space-y-6">

          {/* Active Patient Hero */}
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-4">
            <div className="flex justify-between items-start">
              <div>
                <span className="text-[10px] font-extrabold text-emerald-600 uppercase tracking-wider">Active Patient</span>
                <h3 className="text-xl font-extrabold text-slate-800 mt-1">{selectedMember.name}</h3>
                <p className="text-xs text-slate-400 font-semibold mt-1">
                  {selectedMember.gender} &nbsp;•&nbsp; {selectedMember.age} Years &nbsp;•&nbsp; {selectedMember.role}
                </p>
              </div>
              <div className="bg-slate-50 border border-slate-200 px-3 py-2 rounded-xl text-center">
                <span className="block text-[9px] font-extrabold text-slate-400 uppercase tracking-wider">Biometric ID</span>
                <strong className="text-sm text-emerald-700 font-mono">{selectedMember.id}</strong>
              </div>
            </div>

            {/* Metric Badges */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              {[
                { label: 'AADHAAR', value: selectedMember.aadhaar || 'N/A' },
                { label: 'VITALS RISK', value: selectedMember.pregnancyDetails?.riskLevel || selectedMember.riskLevel || 'Normal' },
                { label: 'ALERTS', value: `${selectedMember.alerts?.length || 0} active` },
                { label: 'SCHEDULING', value: `${selectedMember.appointments?.length || 0} scheduled` },
              ].map(({ label, value }) => (
                <div key={label} className="bg-slate-50 border border-slate-100 p-3 rounded-2xl">
                  <span className="block text-[9px] text-slate-400 font-extrabold uppercase tracking-wider">{label}</span>
                  <strong className="text-sm text-slate-700">{value}</strong>
                </div>
              ))}
            </div>
          </div>

          {/* Pregnancy Tracker */}
          {selectedMember.pregnancyDetails && (
            <div className="bg-pink-50 border border-pink-100 p-5 rounded-3xl flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="space-y-1">
                <span className="text-[10px] font-extrabold text-pink-600 uppercase tracking-wider flex items-center gap-1">
                  <span className="material-symbols-outlined text-sm">pregnant_woman</span> Pregnancy Tracker
                </span>
                <h4 className="font-bold text-pink-900">Maternal Health Progress</h4>
                <p className="text-xs text-pink-700 font-semibold">
                  Weeks Gestation: <strong>{selectedMember.pregnancyDetails.weeks} Weeks</strong>
                  &nbsp;•&nbsp; EDD: <strong>{selectedMember.pregnancyDetails.edd}</strong>
                </p>
              </div>
              <div className="bg-white/80 border border-pink-100 px-4 py-2 rounded-2xl text-xs font-bold text-pink-800">
                Visits Conducted: <strong>{selectedMember.pregnancyDetails.visits}</strong>
              </div>
            </div>
          )}

          {/* Child Health */}
          {selectedMember.childHealthRecords && (
            <div className="bg-emerald-50 border border-emerald-100 p-5 rounded-3xl flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="space-y-1">
                <span className="text-[10px] font-extrabold text-emerald-600 uppercase tracking-wider flex items-center gap-1">
                  <span className="material-symbols-outlined text-sm">child_care</span> Pediatric Tracker
                </span>
                <h4 className="font-bold text-emerald-900">Infant / Child Growth Chart</h4>
                <p className="text-xs text-emerald-700 font-semibold">
                  Height: <strong>{selectedMember.childHealthRecords.height}</strong>
                  &nbsp;•&nbsp; Weight: <strong>{selectedMember.childHealthRecords.weight}</strong>
                </p>
              </div>
              <div className="bg-white/80 border border-emerald-100 px-4 py-2 rounded-2xl text-xs font-bold text-emerald-800">
                Nutrition: <strong>{selectedMember.childHealthRecords.nutritionalStatus}</strong>
              </div>
            </div>
          )}

          {/* Clinical History */}
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-3">
            <h4 className="text-sm font-bold text-slate-700 flex items-center gap-2">
              <span className="material-symbols-outlined text-slate-400 text-lg">notes</span>
              Clinical History
            </h4>
            {selectedMember.medicalHistory?.length > 0 ? (
              <div className="space-y-2">
                {selectedMember.medicalHistory.map((h, i) => (
                  <div key={i} className="bg-slate-50 border border-slate-100 p-3.5 rounded-2xl space-y-1">
                    <div className="flex justify-between items-center text-xs">
                      <strong className="text-slate-700">{h.condition}</strong>
                      <span className="text-slate-400 font-semibold">{h.date}</span>
                    </div>
                    <p className="text-xs text-slate-400 font-medium">{h.notes}</p>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">No clinical history recorded.</p>
            )}
          </div>

          {/* Prescriptions */}
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-3">
            <h4 className="text-sm font-bold text-slate-700 flex items-center gap-2">
              <span className="material-symbols-outlined text-slate-400 text-lg">receipt_long</span>
              Prescriptions &amp; Meds
            </h4>
            {selectedMember.prescriptions?.length > 0 ? (
              <div className="space-y-2">
                {selectedMember.prescriptions.map((p, i) => (
                  <div key={i} className="flex justify-between items-center bg-slate-50 border border-slate-100 p-3.5 rounded-2xl">
                    <div>
                      <strong className="text-sm text-emerald-700">{p.name}</strong>
                      <span className="block text-[10px] text-slate-400 font-semibold mt-0.5">Dosage: {p.dosage}</span>
                    </div>
                    <span className="bg-emerald-50 text-emerald-700 border border-emerald-100 px-2.5 py-1 rounded-lg text-[10px] font-extrabold">
                      {p.duration}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">No active prescriptions.</p>
            )}
          </div>

          {/* Immunization Log */}
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-3">
            <h4 className="text-sm font-bold text-slate-700 flex items-center gap-2">
              <span className="material-symbols-outlined text-slate-400 text-lg">vaccines</span>
              Immunization Log
            </h4>
            {selectedMember.vaccinations?.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {selectedMember.vaccinations.map((v, i) => (
                  <div key={i} className="bg-slate-50 border border-slate-100 p-3.5 rounded-2xl flex justify-between items-center">
                    <div>
                      <strong className="text-sm text-emerald-700">{v.vaccine}</strong>
                      <span className="block text-[10px] text-slate-400 font-semibold mt-0.5">Date: {v.date}</span>
                    </div>
                    <span className="bg-emerald-50 text-emerald-700 border border-emerald-100 px-2.5 py-1 rounded-lg text-[10px] font-extrabold uppercase">
                      {v.status}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">No vaccine immunization history.</p>
            )}
          </div>

        </div>

        {/* Right Column */}
        <div className="space-y-6">

          {/* Family Roster */}
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-3">
            <h4 className="text-sm font-bold text-slate-700 flex items-center gap-2">
              <span className="material-symbols-outlined text-slate-400 text-lg">group</span>
              Family Roster
            </h4>
            <div className="space-y-2">
              {currentFamily.members.map(m => {
                const isActive = m.id === selectedMember.id;
                return (
                  <button
                    key={m.id}
                    onClick={() => setSelectedMemberId(m.id)}
                    className={`w-full p-3 rounded-2xl text-left transition-all border text-xs flex justify-between items-center ${
                      isActive
                        ? 'border-emerald-300 bg-emerald-50 text-emerald-800'
                        : 'border-slate-100 bg-slate-50 hover:bg-slate-100 text-slate-600'
                    }`}
                  >
                    <div>
                      <span className="block font-bold">{m.name}</span>
                      <span className="text-[10px] text-slate-400 font-semibold">{m.role} • {m.age} Yrs</span>
                    </div>
                    <span className="font-mono text-[9px] text-slate-400">{m.id}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Appointments */}
          <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-3">
            <h4 className="text-sm font-bold text-slate-700 flex items-center gap-2">
              <span className="material-symbols-outlined text-slate-400 text-lg">calendar_today</span>
              Appointments
            </h4>
            {selectedMember.appointments?.length > 0 ? (
              <div className="space-y-2">
                {selectedMember.appointments.map((app, i) => (
                  <div key={i} className="bg-slate-50 border border-slate-100 p-3.5 rounded-2xl space-y-1">
                    <div className="flex justify-between items-center">
                      <strong className="text-sm text-emerald-700">{app.doctor}</strong>
                      <span className="bg-emerald-50 text-emerald-700 border border-emerald-100 px-2 py-0.5 rounded-lg text-[9px] font-extrabold">
                        {app.time}
                      </span>
                    </div>
                    <p className="text-[10px] text-slate-400 font-medium">Reason: {app.reason}</p>
                    <span className="block text-[9px] text-slate-400 font-semibold">Date: {app.date}</span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">No appointments scheduled.</p>
            )}
          </div>

        </div>
      </div>
    </div>
  );
}
