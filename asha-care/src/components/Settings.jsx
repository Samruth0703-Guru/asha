import React, { useState } from 'react';

export default function Settings({ currentLang, onLanguageChange, t }) {
  const [offlineSync, setOfflineSync] = useState(true);
  const [bypassBiometrics, setBypassBiometrics] = useState(false);
  const [autoVoice, setAutoVoice] = useState(false);
  const [auditLogs, setAuditLogs] = useState(true);
  const [showNotification, setShowNotification] = useState(false);

  const languages = [
    { code: 'en', name: 'English', localName: 'English' },
    { code: 'ta', name: 'Tamil', localName: 'தமிழ்' },
    { code: 'hi', name: 'Hindi', localName: 'हिन्दी' },
    { code: 'ml', name: 'Malayalam', localName: 'മലയാളം' },
    { code: 'kn', name: 'Kannada', localName: 'ಕನ್ನಡ' },
    { code: 'te', name: 'Telugu', localName: 'తెలుగు' },
    { code: 'pa', name: 'Punjabi', localName: 'ਪੰਜਾਬੀ' },
    { code: 'gu', name: 'Gujarati', localName: 'ગુજરાતી' },
    { code: 'mr', name: 'Marathi', localName: 'मराठी' }
  ];

  const handleSave = () => {
    setShowNotification(true);
    setTimeout(() => {
      setShowNotification(false);
    }, 3000);
  };

  return (
    <div className="bg-white p-6 rounded-3xl shadow-sm border border-slate-100 space-y-6 max-w-4xl">
      {/* Title */}
      <div>
        <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
          <span className="material-symbols-outlined text-emerald-700 text-2xl">settings</span>
          {t('settings')}
        </h2>
        <p className="text-xs text-slate-400 font-semibold mt-0.5">
          Configure systems interface localization languages and developer features.
        </p>
      </div>

      {/* Language Section */}
      <div className="border border-slate-100 rounded-3xl p-5 space-y-4">
        <div>
          <h3 className="text-sm font-bold text-slate-800 flex items-center gap-1.5">
            <span className="material-symbols-outlined text-slate-500 text-lg">language</span>
            {t('language_settings')}
          </h3>
          <p className="text-[10px] text-slate-400 font-semibold mt-0.5">{t('select_language')}</p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
          {languages.map((lang) => {
            const isSelected = currentLang === lang.code;
            return (
              <button
                key={lang.code}
                type="button"
                onClick={() => onLanguageChange(lang.code)}
                className={`p-3.5 rounded-2xl border text-left flex flex-col justify-between transition-all duration-150 active:scale-[0.98] ${
                  isSelected
                    ? 'border-emerald-600 bg-emerald-50 text-emerald-800'
                    : 'border-slate-150 bg-slate-50 hover:bg-slate-100 text-slate-700'
                }`}
              >
                <span className="text-xs font-bold">{lang.localName}</span>
                <span className="text-[9px] text-slate-400 font-semibold mt-1">{lang.name}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Extra settings features */}
      <div className="border border-slate-100 rounded-3xl p-5 space-y-4">
        <div>
          <h3 className="text-sm font-bold text-slate-800 flex items-center gap-1.5">
            <span className="material-symbols-outlined text-slate-500 text-lg">settings_suggest</span>
            {t('extra_settings')}
          </h3>
          <p className="text-[10px] text-slate-400 font-semibold mt-0.5">Custom configurations for development, bypasses, and syncing.</p>
        </div>

        <div className="space-y-3.5 pt-2">
          {/* Setting item 1 */}
          <label className="flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-100 cursor-pointer hover:bg-slate-100/50 transition-colors">
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-slate-500 text-lg">sync</span>
              <span className="text-xs font-bold text-slate-750">{t('offline_sync')}</span>
            </div>
            <input 
              type="checkbox" 
              checked={offlineSync} 
              onChange={e => setOfflineSync(e.target.checked)}
              className="w-4 h-4 text-emerald-600 border-slate-300 rounded focus:ring-emerald-500 cursor-pointer"
            />
          </label>

          {/* Setting item 2 */}
          <label className="flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-100 cursor-pointer hover:bg-slate-100/50 transition-colors">
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-slate-500 text-lg">fingerprint</span>
              <span className="text-xs font-bold text-slate-750">{t('biometric_bypass')}</span>
            </div>
            <input 
              type="checkbox" 
              checked={bypassBiometrics} 
              onChange={e => setBypassBiometrics(e.target.checked)}
              className="w-4 h-4 text-emerald-600 border-slate-300 rounded focus:ring-emerald-500 cursor-pointer"
            />
          </label>

          {/* Setting item 3 */}
          <label className="flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-100 cursor-pointer hover:bg-slate-100/50 transition-colors">
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-slate-500 text-lg">settings_voice</span>
              <span className="text-xs font-bold text-slate-750">{t('voice_assistant_auto')}</span>
            </div>
            <input 
              type="checkbox" 
              checked={autoVoice} 
              onChange={e => setAutoVoice(e.target.checked)}
              className="w-4 h-4 text-emerald-600 border-slate-300 rounded focus:ring-emerald-500 cursor-pointer"
            />
          </label>

          {/* Setting item 4 */}
          <label className="flex items-center justify-between p-3 bg-slate-50 rounded-2xl border border-slate-100 cursor-pointer hover:bg-slate-100/50 transition-colors">
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-slate-500 text-lg">security</span>
              <span className="text-xs font-bold text-slate-750">{t('developer_mode')}</span>
            </div>
            <input 
              type="checkbox" 
              checked={auditLogs} 
              onChange={e => setAuditLogs(e.target.checked)}
              className="w-4 h-4 text-emerald-600 border-slate-300 rounded focus:ring-emerald-500 cursor-pointer"
            />
          </label>
        </div>
      </div>

      {/* Save Button */}
      <div className="flex justify-end pt-2">
        <button
          onClick={handleSave}
          type="button"
          className="px-6 py-2.5 bg-[#003d29] hover:brightness-110 text-white font-bold rounded-xl text-xs shadow-md transition-all active:scale-95 flex items-center gap-1.5"
        >
          <span className="material-symbols-outlined text-sm">save</span>
          {t('save_settings')}
        </button>
      </div>

      {/* Success Notification Alert */}
      {showNotification && (
        <div className="fixed bottom-6 right-6 bg-slate-900 border border-slate-800 text-white p-4 rounded-2xl shadow-xl flex items-center gap-3 z-50 animate-fade-in">
          <div className="w-8 h-8 rounded-full bg-emerald-600 flex items-center justify-center text-white material-symbols-outlined text-sm">
            check
          </div>
          <div>
            <p className="text-xs font-bold text-slate-200">
              {t('settings_saved')}
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
