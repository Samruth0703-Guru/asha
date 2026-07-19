import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function Vaccination({ t }) {
  const [families, setFamilies] = useState([]);
  const [filterStatus, setFilterStatus] = useState('all'); // 'all', 'completed', 'pending', 'overdue'
  const [selectedPatientId, setSelectedPatientId] = useState('');
  
  // Form state
  const [vaccineName, setVaccineName] = useState('BCG');
  const [adminDate, setAdminDate] = useState(new Date().toISOString().split('T')[0]);
  const [statusVal, setStatusVal] = useState('completed'); // 'completed', 'pending', 'overdue'

  // Load families
  const loadData = () => {
    const list = getStoredFamilies();
    setFamilies(list);
    if (list.length > 0 && list[0].members.length > 0) {
      setSelectedPatientId(list[0].members[0].id);
    }
  };

  useEffect(() => {
    loadData();
    window.addEventListener('asha_data_changed', loadData);
    return () => window.removeEventListener('asha_data_changed', loadData);
  }, []);

  // Flattened list of patients
  const allPatients = [];
  families.forEach(fam => {
    fam.members.forEach(m => {
      allPatients.push({ ...m, familyId: fam.id, familyName: fam.name, phone: fam.phone });
    });
  });

  // Flattened vaccinations logs
  const [vaccinationRecords, setVaccinationRecords] = useState([
    { patientId: 'PT001', patientName: 'Saraswathi Devi', familyName: 'Devi Family', vaccine: 'TT Booster', date: '15 Jul 2025', status: 'completed', phone: '9876543210' },
    { patientId: 'PT002', patientName: 'Rani K', familyName: 'Kishore Family', vaccine: 'OPV 1', date: '20 Jul 2025', status: 'pending', phone: '9443210987' },
    { patientId: 'PT003', patientName: 'Ramu K', familyName: 'Kishore Family', vaccine: 'HepB Birth Dose', date: '02 Jul 2025', status: 'overdue', phone: '9443210987' },
    { patientId: 'PT004', patientName: 'Meenakshi Sundaram', familyName: 'Sundaram Family', vaccine: 'Measles-Rubella', date: '10 Jul 2025', status: 'completed', phone: '9123456789' }
  ]);

  const handleAdministerVaccine = (e) => {
    e.preventDefault();
    const patient = allPatients.find(p => p.id === selectedPatientId);
    if (!patient) return;

    const newRecord = {
      patientId: patient.id,
      patientName: patient.name,
      familyName: patient.familyName,
      vaccine: vaccineName,
      date: new Date(adminDate).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }),
      status: statusVal,
      phone: patient.phone
    };

    setVaccinationRecords(prev => [newRecord, ...prev]);

    // Update patient list in localStorage to reflect stats if needed
    // Emit data change
    window.dispatchEvent(new Event('asha_data_changed'));
    alert(`Successfully recorded ${vaccineName} for ${patient.name}`);
  };

  const handleSendQuickSMS = (rec) => {
    alert(`SMS Alert sent to ${rec.patientName} (${rec.phone}): "Reminder: Your scheduled dose of ${rec.vaccine} is due on ${rec.date}. Please visit your local PHC."`);
  };

  const filteredRecords = vaccinationRecords.filter(rec => {
    if (filterStatus === 'all') return true;
    return rec.status === filterStatus;
  });

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 pb-5 border-b border-slate-100">
        <div>
          <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <span className="material-symbols-outlined text-emerald-700 text-2xl">vaccines</span>
            Vaccination &amp; Immunization Registry
          </h2>
          <p className="text-xs text-slate-400 font-semibold mt-0.5">
            Log child vaccines, maternal care immunizations, and dispatch automated compliance reminder alerts.
          </p>
        </div>

        {/* Status Filters */}
        <div className="flex bg-slate-100 p-1 rounded-xl text-xs font-bold">
          {['all', 'completed', 'pending', 'overdue'].map(status => (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-3 py-1.5 rounded-lg capitalize transition-all ${filterStatus === status ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
            >
              {status}
            </button>
          ))}
        </div>
      </div>

      {/* Main Grid: Form and Table */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Record vaccine form */}
        <div className="lg:col-span-1 border border-slate-100 rounded-3xl p-5 space-y-4 h-fit">
          <h3 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">Record Vaccine Dose</h3>
          
          <form onSubmit={handleAdministerVaccine} className="space-y-4">
            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Select Patient</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none focus:bg-white"
                value={selectedPatientId}
                onChange={e => setSelectedPatientId(e.target.value)}
              >
                {allPatients.map(p => (
                  <option key={p.id} value={p.id}>{p.name} ({p.id})</option>
                ))}
              </select>
            </div>

            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Vaccine Type</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-700 outline-none"
                value={vaccineName}
                onChange={e => setVaccineName(e.target.value)}
              >
                <option value="BCG">BCG (Tuberculosis)</option>
                <option value="OPV 1">OPV Birth / Dose 1 (Polio)</option>
                <option value="HepB Birth Dose">Hepatitis B Birth Dose</option>
                <option value="Pentavalent 1">Pentavalent 1 (DPT-HepB-Hib)</option>
                <option value="Rotavirus 1">Rotavirus 1 (RVV)</option>
                <option value="Measles-Rubella">Measles-Rubella (MR) 1st Dose</option>
                <option value="TT Booster">Tetanus Toxoid (TT) Pregnancy Booster</option>
              </select>
            </div>

            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Administration Date</label>
              <input 
                type="date" 
                value={adminDate}
                onChange={e => setAdminDate(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-750 outline-none"
              />
            </div>

            <div className="space-y-2">
              <label className="block text-[10px] font-extrabold text-slate-400 uppercase tracking-wider">Dose Status</label>
              <select
                className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-xs font-semibold text-slate-750 outline-none"
                value={statusVal}
                onChange={e => setStatusVal(e.target.value)}
              >
                <option value="completed">Completed</option>
                <option value="pending">Pending</option>
                <option value="overdue">Overdue</option>
              </select>
            </div>

            <button
              type="submit"
              className="w-full py-2.5 bg-[#003d29] hover:brightness-110 text-white font-bold rounded-xl text-xs transition-all active:scale-95 shadow-md"
            >
              Administer Vaccine Dose
            </button>
          </form>
        </div>

        {/* Ledger Table */}
        <div className="lg:col-span-2 border border-slate-100 rounded-3xl overflow-hidden h-fit">
          <div className="p-4 border-b border-slate-50 bg-slate-50/50">
            <h3 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">Registry Ledger Logs</h3>
          </div>
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-slate-100 text-slate-400 font-bold uppercase text-[9px] tracking-wider bg-slate-50/20">
                <th className="p-4">Patient ID</th>
                <th className="p-4">Name</th>
                <th className="p-4">Vaccine</th>
                <th className="p-4">Scheduled Date</th>
                <th className="p-4">Status</th>
                <th className="p-4">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-slate-700 font-semibold">
              {filteredRecords.map((rec, idx) => (
                <tr key={idx} className="hover:bg-slate-50/50">
                  <td className="p-4 font-mono text-emerald-700 font-bold">{rec.patientId}</td>
                  <td className="p-4 text-slate-800 font-bold">{rec.patientName}</td>
                  <td className="p-4">{rec.vaccine}</td>
                  <td className="p-4 text-slate-400">{rec.date}</td>
                  <td className="p-4">
                    <span className={`px-2.5 py-0.5 rounded text-[10px] font-extrabold uppercase ${
                      rec.status === 'completed' 
                        ? 'bg-emerald-50 text-emerald-800 border border-emerald-100' 
                        : rec.status === 'pending' 
                          ? 'bg-amber-50 text-amber-800 border border-amber-100' 
                          : 'bg-rose-50 text-rose-800 border border-rose-100'
                    }`}>
                      {rec.status}
                    </span>
                  </td>
                  <td className="p-4">
                    {(rec.status === 'pending' || rec.status === 'overdue') && (
                      <button
                        onClick={() => handleSendQuickSMS(rec)}
                        className="px-2.5 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-750 border border-indigo-100 rounded-lg text-[10px] font-bold flex items-center gap-1 transition-all active:scale-95"
                      >
                        <span className="material-symbols-outlined text-xs">sms</span> Remind
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {filteredRecords.length === 0 && (
                <tr>
                  <td colSpan="6" className="text-center py-6 text-slate-400 italic">No records matching the filter.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

      </div>

    </div>
  );
}
