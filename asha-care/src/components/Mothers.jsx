import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function Mothers({ onSelectPatient }) {
  const [families, setFamilies] = useState([]);

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

  const mothers = [];
  families.forEach(fam => {
    fam.members.forEach(m => {
      if (m.pregnancyDetails) {
        mothers.push({ ...m, familyId: fam.id, familyName: fam.name });
      }
    });
  });

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      <div>
        <h2 className="text-xl font-bold text-slate-800">Mothers Registry (ANC Care)</h2>
        <p className="text-xs text-slate-400 font-semibold mt-0.5 font-sans">Expectant mothers registry for antenatal counseling and clinical follow-up.</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr className="border-b border-slate-150 text-slate-400 font-bold uppercase text-[9px] tracking-wider">
              <th className="pb-3">Patient ID</th>
              <th className="pb-3">Name</th>
              <th className="pb-3">Age</th>
              <th className="pb-3">Gestation</th>
              <th className="pb-3">EDD Date</th>
              <th className="pb-3">Risk Assessment</th>
              <th className="pb-3">Visits Done</th>
              <th className="pb-3">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700 font-medium">
            {mothers.map(m => (
              <tr key={m.id} className="hover:bg-slate-50/50">
                <td className="py-4 font-mono text-emerald-700 font-bold">{m.id}</td>
                <td className="py-4 text-slate-800 font-bold">{m.name}</td>
                <td className="py-4">{m.age} Yrs</td>
                <td className="py-4 text-emerald-800 font-extrabold">{m.pregnancyDetails.weeks} Weeks</td>
                <td className="py-4">{m.pregnancyDetails.edd}</td>
                <td className="py-4">
                  <span className={`inline-flex items-center gap-1 text-[10px] font-extrabold px-2.5 py-1 rounded-md border ${
                    m.pregnancyDetails.riskLevel === 'High'
                      ? 'text-rose-600 bg-rose-50 border-rose-100'
                      : 'text-emerald-600 bg-emerald-50 border-emerald-100'
                  }`}>
                    {m.pregnancyDetails.riskLevel} Risk Case
                  </span>
                </td>
                <td className="py-4 font-bold">{m.pregnancyDetails.visits} Visits</td>
                <td className="py-4">
                  <button
                    onClick={() => onSelectPatient(m.familyId, m.id)}
                    className="px-3 py-1.5 bg-emerald-50 text-emerald-800 rounded-lg font-bold hover:bg-emerald-100 transition-colors"
                  >
                    View Chart
                  </button>
                </td>
              </tr>
            ))}
            {mothers.length === 0 && (
              <tr>
                <td colSpan="8" className="text-center py-6 text-slate-400 italic">No pregnant mothers currently logged.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
