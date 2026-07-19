import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function Immunizations() {
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

  const vacLogs = [];
  families.forEach(fam => {
    fam.members.forEach(m => {
      if (m.vaccinations?.length > 0) {
        m.vaccinations.forEach(v => {
          vacLogs.push({ ...v, patientId: m.id, patientName: m.name, familyName: fam.name });
        });
      }
    });
  });

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      <div>
        <h2 className="text-xl font-bold text-slate-800">Immunization Registry Ledger</h2>
        <p className="text-xs text-slate-400 font-semibold mt-0.5 font-sans">Logs of child growth and expectant mother vaccine administration.</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr className="border-b border-slate-150 text-slate-400 font-bold uppercase text-[9px] tracking-wider">
              <th className="pb-3">Patient ID</th>
              <th className="pb-3">Name</th>
              <th className="pb-3">Family</th>
              <th className="pb-3">Vaccine</th>
              <th className="pb-3">Date Administered</th>
              <th className="pb-3">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700 font-medium">
            {vacLogs.map((log, idx) => (
              <tr key={idx} className="hover:bg-slate-50/50">
                <td className="py-4 font-mono text-emerald-750 font-bold">{log.patientId}</td>
                <td className="py-4 text-slate-800 font-bold">{log.patientName}</td>
                <td className="py-4">{log.familyName}</td>
                <td className="py-4 font-bold text-slate-800">{log.vaccine}</td>
                <td className="py-4">{log.date}</td>
                <td className="py-4">
                  <span className="bg-emerald-50 text-emerald-800 text-[10px] font-extrabold px-2.5 py-1 rounded border border-emerald-100 uppercase">
                    {log.status}
                  </span>
                </td>
              </tr>
            ))}
            {vacLogs.length === 0 && (
              <tr>
                <td colSpan="6" className="text-center py-6 text-slate-400 italic">No immunizations completed yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
