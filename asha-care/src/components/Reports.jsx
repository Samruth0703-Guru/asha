import React from 'react';

export default function Reports() {
  const reportsList = [
    { title: "Maternal Health Monthly Progress (ANC)", month: "June 2026", status: "Generated", size: "1.2 MB" },
    { title: "Child Immunization & Growth Report", month: "June 2026", status: "Generated", size: "940 KB" },
    { title: "NCD Screening Summary (Cancer / BP / Blood Sugar)", month: "May 2026", status: "Generated", size: "2.1 MB" },
    { title: "Block Inventory Vaccine Stock Requisition", month: "July 2026", status: "Draft", size: "450 KB" }
  ];

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      <div>
        <h2 className="text-xl font-bold text-slate-800">Monthly Administrative Reports</h2>
        <p className="text-xs text-slate-400 font-semibold mt-0.5">Download generated NHM/PHC performance and census statistics reports.</p>
      </div>

      <div className="space-y-3">
        {reportsList.map((rep, idx) => (
          <div key={idx} className="p-4 bg-slate-50 border border-slate-200/60 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-4 text-xs font-semibold">
            <div className="space-y-1">
              <h4 className="text-sm font-bold text-slate-800">{rep.title}</h4>
              <p className="text-slate-400">Reporting Month: {rep.month} • File Size: {rep.size}</p>
            </div>
            <div className="flex items-center gap-3">
              <span className={`px-2.5 py-1 rounded text-[10px] font-bold ${
                rep.status === 'Generated' ? 'bg-emerald-50 text-emerald-800 border border-emerald-100' : 'bg-slate-100 text-slate-500'
              }`}>
                {rep.status}
              </span>
              <button className="flex items-center gap-1 bg-emerald-700 hover:bg-emerald-800 text-white px-3 py-1.5 rounded-lg text-xs font-bold transition-colors">
                <span className="material-symbols-outlined text-sm">download</span> Download PDF
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
