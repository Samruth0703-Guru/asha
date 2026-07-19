import React from 'react';

export default function VisitsHistory() {
  const visits = [
    { date: "2026-07-15", patient: "Priya Sharma", purpose: "Routine ANC Trimester Consultation", ASHA: "Latha M. (ANM)", status: "Completed" },
    { date: "2026-07-12", patient: "Aarav Sharma", purpose: "Hypertension Vitals check", ASHA: "Latha M. (ANM)", status: "Completed" },
    { date: "2026-07-10", patient: "Meena Ramasamy", purpose: "Diabetic glucose checks and medicines refill", ASHA: "Saraswathi R.", status: "Completed" },
    { date: "2026-07-08", patient: "Rohan Sharma", purpose: "Infant growth & immunization booster scheduling", ASHA: "Latha M. (ANM)", status: "Completed" }
  ];

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      <div>
        <h2 className="text-xl font-bold text-slate-800">ASHA Field Visit Logbook</h2>
        <p className="text-xs text-slate-400 font-semibold mt-0.5">Logs of ASHA health worker household visits conducted in Kadavur and Nallur sectors.</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr className="border-b border-slate-150 text-slate-400 font-bold uppercase text-[9px] tracking-wider">
              <th className="pb-3">Visit Date</th>
              <th className="pb-3">Patient Name</th>
              <th className="pb-3">Purpose of Visit</th>
              <th className="pb-3">Health Worker (ASHA)</th>
              <th className="pb-3">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700 font-medium">
            {visits.map((vis, idx) => (
              <tr key={idx} className="hover:bg-slate-50/50">
                <td className="py-4 font-bold text-slate-800">{vis.date}</td>
                <td className="py-4 text-emerald-800 font-extrabold">{vis.patient}</td>
                <td className="py-4 text-slate-500">{vis.purpose}</td>
                <td className="py-4">{vis.ASHA}</td>
                <td className="py-4">
                  <span className="bg-emerald-50 text-emerald-800 text-[10px] font-bold px-2 py-0.5 rounded border border-emerald-100">
                    {vis.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
