import React from 'react';

export default function Support() {
  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6 max-w-2xl mx-auto">
      <div className="text-center space-y-xs">
        <span className="material-symbols-outlined text-primary text-5xl">support_agent</span>
        <h2 className="text-xl font-bold text-slate-800">Support & Help Desk</h2>
        <p className="text-xs text-slate-400 font-semibold font-sans">Contact administration or view user documentation.</p>
      </div>

      <div className="space-y-sm">
        <div className="p-4 bg-slate-50 border border-slate-200/60 rounded-2xl flex items-start gap-4">
          <span className="material-symbols-outlined text-primary text-2xl mt-0.5">call</span>
          <div>
            <h4 className="text-xs font-bold text-slate-800">District Health Helpline</h4>
            <p className="text-[10px] text-slate-500 leading-relaxed mt-0.5">Helpline: +91 44 2432 1080 (Monday - Saturday, 9:00 AM - 5:00 PM)</p>
          </div>
        </div>

        <div className="p-4 bg-slate-50 border border-slate-200/60 rounded-2xl flex items-start gap-4">
          <span className="material-symbols-outlined text-primary text-2xl mt-0.5">mail</span>
          <div>
            <h4 className="text-xs font-bold text-slate-800">Email Support</h4>
            <p className="text-[10px] text-slate-500 leading-relaxed mt-0.5">Email: support.nhm@tn.gov.in (Average response within 24 hours)</p>
          </div>
        </div>

        <div className="p-4 bg-slate-50 border border-slate-200/60 rounded-2xl flex items-start gap-4">
          <span className="material-symbols-outlined text-primary text-2xl mt-0.5">help_outline</span>
          <div>
            <h4 className="text-xs font-bold text-slate-800">Quick FAQ Links</h4>
            <p className="text-[10px] text-slate-500 leading-relaxed mt-0.5">Need help on fingerprint authentication setup, patient registration guidelines, or offline queue syncing? View our support documentation.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
