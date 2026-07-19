import React from 'react';

export default function Sidebar({ currentTab, setCurrentTab, onLogout, t, isOpen, onClose }) {
  const navItems = [
    { id: 'dashboard', label: t('dashboard'), icon: 'grid_view' },
    { id: 'patients', label: t('patients'), icon: 'person' },
    { id: 'mothers', label: t('mothers'), icon: 'pregnant_woman' },
    { id: 'pregnancies', label: t('pregnancies'), icon: 'baby_changing_station' },
    { id: 'vaccination', label: t('vaccination'), icon: 'vaccines' },
    { id: 'inventory', label: t('inventory'), icon: 'inventory' },
    { id: 'assistant', label: t('ai_assistant'), icon: 'settings_suggest' },
    { id: 'cancer', label: t('cancer_care'), icon: 'clinical_notes' },
    { id: 'reports', label: t('reports'), icon: 'description' },
    { id: 'history', label: t('visits_history'), icon: 'history' },
    { id: 'support', label: t('support'), icon: 'support_agent' },
    { id: 'sms', label: t('sms'), icon: 'sms' },
    { id: 'settings', label: t('settings'), icon: 'settings' },
  ];

  return (
    <>
      {/* Mobile Sidebar Overlay Backdrop */}
      {isOpen && (
        <div 
          onClick={onClose} 
          className="fixed inset-0 bg-slate-900/60 z-20 md:hidden backdrop-blur-sm transition-opacity duration-300"
        />
      )}
      <aside className={`w-[260px] h-screen fixed left-0 top-0 bg-[#1e293b] text-slate-300 flex flex-col py-6 px-4 gap-2 z-30 overflow-y-auto custom-scrollbar transition-transform duration-300 md:translate-x-0 ${
        isOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
      {/* Brand Header */}
      <div className="flex items-center gap-3 px-2 mb-6">
        <div className="w-10 h-10 bg-emerald-600 rounded-xl flex items-center justify-center text-white">
          <span className="material-symbols-outlined text-2xl font-bold" style={{ fontVariationSettings: "'FILL' 1" }}>
            health_and_safety
          </span>
        </div>
        <div className="flex flex-col">
          <span className="text-md font-bold text-white leading-none tracking-wide">
            ASHA CARE+
          </span>
          <span className="text-[10px] text-slate-400 font-semibold mt-1">Block Console</span>
        </div>
      </div>

      {/* Nav Link List */}
      <nav className="flex-1 flex flex-col gap-1">
        {navItems.map((item) => {
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => { setCurrentTab(item.id); if (onClose) onClose(); }}
              className={`flex items-center gap-4 px-4 py-3 rounded-xl transition-all duration-150 text-left text-sm font-semibold w-full ${
                isActive
                  ? 'bg-emerald-50 text-emerald-800 shadow-sm'
                  : 'hover:bg-slate-800 text-slate-400 hover:text-slate-100'
              }`}
            >
              <span className="material-symbols-outlined text-xl">{item.icon}</span>
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer Banner */}
      <div className="mt-6 pt-4 border-t border-slate-800 space-y-4">
        {/* Logout */}
        <button
          onClick={onLogout}
          className="flex items-center gap-4 px-4 py-3 text-slate-400 hover:text-rose-400 hover:bg-slate-800/50 rounded-xl w-full text-left text-sm font-semibold transition-colors"
        >
          <span className="material-symbols-outlined text-xl">logout</span>
          <span>{t('logout')}</span>
        </button>

        {/* Campaign Banner Card */}
        <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-2xl p-4 flex flex-col gap-2 relative overflow-hidden">
          <span className="text-[10px] text-emerald-400 font-extrabold uppercase tracking-wide">
            Campaign Info
          </span>
          <p className="text-xs text-emerald-100 font-medium leading-relaxed font-sans">
            Make Every Mother Count, Every Life Matters.
          </p>
          <div className="flex justify-end mt-1">
            <img 
              className="h-12 w-auto object-contain opacity-80"
              alt="Maternal Health"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuDqebMuKHIgqbWUAjgcnnREurIc6bWG6C3ja9tL197KVXSIETRj8_PL6Xg4LjI3Ys54eQBvSpUmTt76DGIvxD4Eb2GGmNFqCH_qi6mV2sn75KONjNOMzfV_4Zm3jRYTmaSh_9ZYokch8rhW5R2GkTym_mtpjOdKRFcTsA4ZX2kOnXiDegWtPQsGL9xE_dgScLwzrMo7mgzHf5_JWpUbkRNzvk-46esrVBXyzynL3s1B48PcCTwuT3ZYBQ" 
            />
          </div>
        </div>
      </div>
    </aside>
    </>
  );
}
