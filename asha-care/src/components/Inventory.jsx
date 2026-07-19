import React from 'react';

export default function Inventory() {
  const stock = [
    { name: "Tetanus Toxoid (TT)", type: "Vaccine", stock: 120, status: "Normal", min: 30 },
    { name: "Oral Polio Vaccine (OPV)", type: "Vaccine", stock: 240, status: "Normal", min: 50 },
    { name: "MMR Vaccine", type: "Vaccine", stock: 18, status: "Low Stock Alert", min: 20 },
    { name: "Iron & Folic Acid Tablets", type: "Supplements", stock: 1500, status: "Normal", min: 500 },
    { name: "Calcium Carbonate", type: "Supplements", stock: 800, status: "Normal", min: 300 },
    { name: "Paracetamol Syrup", type: "Medicine", stock: 5, status: "Critical Alert", min: 15 },
  ];

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6">
      <div>
        <h2 className="text-xl font-bold text-slate-800">Vaccine & Medicine Stock Inventory</h2>
        <p className="text-xs text-slate-400 font-semibold mt-0.5">Track current stock status at block PHC subcenters.</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs border-collapse">
          <thead>
            <tr className="border-b border-slate-150 text-slate-400 font-bold uppercase text-[9px] tracking-wider">
              <th className="pb-3">Item Name</th>
              <th className="pb-3">Type</th>
              <th className="pb-3">Quantity Available</th>
              <th className="pb-3">Safety Limit (Min)</th>
              <th className="pb-3">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 text-slate-700 font-medium">
            {stock.map((item, idx) => (
              <tr key={idx} className="hover:bg-slate-50/50">
                <td className="py-4 text-slate-800 font-bold">{item.name}</td>
                <td className="py-4 text-slate-400">{item.type}</td>
                <td className="py-4 font-bold">{item.stock} unit(s)</td>
                <td className="py-4 font-mono">{item.min}</td>
                <td className="py-4">
                  <span className={`inline-flex items-center gap-1 text-[10px] font-extrabold px-2.5 py-1 rounded-md border ${
                    item.status === 'Critical Alert'
                      ? 'text-rose-600 bg-rose-50 border-rose-100 animate-pulse'
                      : item.status === 'Low Stock Alert'
                      ? 'text-amber-600 bg-amber-50 border-amber-100'
                      : 'text-emerald-600 bg-emerald-50 border-emerald-100'
                  }`}>
                    {item.status}
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
