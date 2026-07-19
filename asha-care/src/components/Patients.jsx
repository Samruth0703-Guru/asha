import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function Patients({ onRegisterClick, onSelectPatient, searchFilter = '' }) {
  const [families, setFamilies] = useState([]);
  const [searchTerm, setSearchTerm] = useState(searchFilter);

  // Sync the header search into the local search box
  useEffect(() => {
    setSearchTerm(searchFilter);
  }, [searchFilter]);

  useEffect(() => {
    const load = () => setFamilies(getStoredFamilies());
    load();
    // Re-load when patient data changes (registration, edit, delete)
    window.addEventListener('asha_data_changed', load);
    window.addEventListener('storage', load);
    return () => {
      window.removeEventListener('asha_data_changed', load);
      window.removeEventListener('storage', load);
    };
  }, []);

  const allPatients = [];
  families.forEach(fam => {
    fam.members.forEach(m => {
      allPatients.push({ ...m, familyId: fam.id, familyName: fam.name, address: fam.address });
    });
  });

  const filteredPatients = allPatients.filter(p =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.familyName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-slate-800">Community Patients Registry</h2>
          <p className="text-xs text-slate-400 font-semibold mt-0.5">Manage and view medical profiles of all block residents.</p>
        </div>
        <button
          onClick={onRegisterClick}
          className="px-5 py-2.5 bg-emerald-700 text-white rounded-xl text-xs font-bold hover:bg-emerald-800 transition-colors flex items-center gap-1.5 self-start md:self-auto"
        >
          <span className="material-symbols-outlined text-sm">person_add</span> Register New Patient
        </button>
      </div>

      <div className="relative">
        <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-lg">search</span>
        <input
          type="text"
          placeholder="Filter by name, ID, family group..."
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
          className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 pl-12 pr-4 text-xs font-semibold text-slate-700 outline-none focus:ring-1 focus:ring-emerald-500/20 focus:bg-white transition-all"
        />
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr className="border-b border-slate-150 text-slate-400 font-bold uppercase text-[9px] tracking-wider">
              <th className="pb-3">Patient ID</th>
              <th className="pb-3">Name</th>
              <th className="pb-3">Age/Gender</th>
              <th className="pb-3">Role</th>
              <th className="pb-3">Family ID</th>
              <th className="pb-3">Address</th>
              <th className="pb-3">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700 font-medium">
            {filteredPatients.map(p => (
              <tr key={p.id} className="hover:bg-slate-50/50">
                <td className="py-4 font-mono text-emerald-700 font-bold">{p.id}</td>
                <td className="py-4 text-slate-800 font-bold">{p.name}</td>
                <td className="py-4">{p.age} Yrs / {p.gender}</td>
                <td className="py-4">{p.role}</td>
                <td className="py-4 font-mono">{p.familyId}</td>
                <td className="py-4 text-slate-400 max-w-[200px] truncate">{p.address}</td>
                <td className="py-4">
                  <button
                    onClick={() => onSelectPatient(p.familyId, p.id)}
                    className="px-3 py-1.5 bg-emerald-50 text-emerald-800 rounded-lg font-bold hover:bg-emerald-100 transition-colors flex items-center gap-1"
                  >
                    <span className="material-symbols-outlined text-xs">visibility</span> View Dashboard
                  </button>
                </td>
              </tr>
            ))}
            {filteredPatients.length === 0 && (
              <tr>
                <td colSpan="7" className="text-center py-6 text-slate-400 italic">No patients found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
