import React, { useState, useEffect } from 'react';
import { getStoredFamilies } from '../database/mockData';

export default function FingerprintScanner({ onAuthSuccess, initialSelectedFpId }) {
  const [families, setFamilies] = useState([]);
  const [selectedFpId, setSelectedFpId] = useState(initialSelectedFpId || '');
  const [isScanning, setIsScanning] = useState(false);
  const [progress, setProgress] = useState(0);
  const [message, setMessage] = useState({ type: '', text: '' });

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

  useEffect(() => {
    if (initialSelectedFpId) setSelectedFpId(initialSelectedFpId);
  }, [initialSelectedFpId]);

  const playSound = (freq, duration, type = 'sine') => {
    try {
      const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = audioCtx.createOscillator();
      const gainNode = audioCtx.createGain();

      oscillator.type = type;
      oscillator.frequency.value = freq;
      gainNode.gain.setValueAtTime(0.08, audioCtx.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + duration);

      oscillator.connect(gainNode);
      gainNode.connect(audioCtx.destination);

      oscillator.start();
      oscillator.stop(audioCtx.currentTime + duration);
    } catch (_) {}
  };

  const handleScan = () => {
    if (!selectedFpId.trim()) {
      setMessage({ type: 'error', text: 'Select or type a Fingerprint ID (e.g. FP001).' });
      return;
    }

    setMessage({ type: '', text: '' });
    setIsScanning(true);
    setProgress(0);
    playSound(750, 0.1, 'triangle');

    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          return 100;
        }
        return prev + 10;
      });
    }, 120);
  };

  useEffect(() => {
    if (progress === 100 && isScanning) {
      setIsScanning(false);
      setProgress(0);

      let foundFamily = null;
      let foundMember = null;

      for (const fam of families) {
        const member = fam.members.find(m => m.id.toLowerCase() === selectedFpId.toLowerCase().trim());
        if (member) {
          foundFamily = fam;
          foundMember = member;
          break;
        }
      }

      if (foundMember) {
        playSound(1200, 0.15, 'sine');
        setTimeout(() => playSound(1600, 0.25, 'sine'), 80);
        setMessage({ type: 'success', text: `Access granted! Welcome ${foundMember.name}. Redirecting to Health Dashboard...` });
        
        setTimeout(() => {
          onAuthSuccess(foundFamily.id, foundMember.id);
        }, 1500);
      } else {
        playSound(180, 0.45, 'sawtooth');
        setMessage({ type: 'error', text: `Access denied. Biometric record for "${selectedFpId}" not found.` });
      }
    }
  }, [progress, isScanning]);

  const allFpOptions = [];
  families.forEach(f => {
    f.members.forEach(m => {
      allFpOptions.push({ id: m.id, name: m.name, famName: f.name });
    });
  });

  return (
    <div className="bg-surface-container-lowest p-lg rounded-xl stat-card-shadow border border-outline-variant/30 max-w-xl mx-auto flex flex-col items-center gap-lg">
      <div className="text-center space-y-xs">
        <span className="material-symbols-outlined text-primary text-5xl">fingerprint</span>
        <h2 className="font-headline-md text-headline-md font-bold text-primary">Biometric Fingerprint Authentication</h2>
        <p className="text-sm text-on-surface-variant">ASHA Patient Verification Console</p>
      </div>

      {/* Simulated Scanner Area */}
      <div className="relative w-36 h-36 bg-slate-50 border border-outline-variant/30 rounded-2xl flex items-center justify-center overflow-hidden">
        {isScanning && (
          <div className="absolute left-0 right-0 h-1 bg-on-secondary-container shadow-md shadow-on-secondary-container animate-bounce top-0" />
        )}
        <span className={`material-symbols-outlined text-7xl transition-colors duration-200 ${
          isScanning ? 'text-on-secondary-container' : 'text-slate-400'
        }`}>
          fingerprint
        </span>
      </div>

      {/* Progress Bar */}
      {isScanning && (
        <div className="w-full space-y-xs">
          <div className="flex justify-between text-xs font-bold text-on-secondary-container">
            <span>READING BIOMETRICS...</span>
            <span>{progress}%</span>
          </div>
          <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
            <div className="h-full bg-on-secondary-container transition-all duration-100" style={{ width: `${progress}%` }} />
          </div>
        </div>
      )}

      {/* Message Output */}
      {message.text && (
        <div className={`w-full p-sm rounded-xl font-bold flex items-center gap-xs text-sm border ${
          message.type === 'success' ? 'bg-secondary-container/20 border-on-secondary-container/20 text-on-secondary-container' : 'bg-error-container/20 border-error/20 text-error'
        }`}>
          <span className="material-symbols-outlined">{message.type === 'success' ? 'check_circle' : 'warning'}</span>
          {message.text}
        </div>
      )}

      {/* Input Options panel */}
      <div className="w-full space-y-md pt-md border-t border-outline-variant/30">
        <div className="flex flex-col gap-base">
          <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Select Pre-registered Fingerprint</label>
          <select
            value={selectedFpId}
            onChange={e => setSelectedFpId(e.target.value)}
            className="w-full p-3 bg-surface-container border border-outline-variant rounded-xl text-sm focus:outline-none"
          >
            <option value="">-- Choose Profile --</option>
            {allFpOptions.map(opt => (
              <option key={opt.id} value={opt.id}>
                {opt.id} - {opt.name} ({opt.famName})
              </option>
            ))}
          </select>
        </div>

        <div className="flex gap-sm">
          <input
            type="text"
            placeholder="Or enter custom ID (e.g. FP001)"
            value={selectedFpId}
            onChange={e => setSelectedFpId(e.target.value)}
            className="flex-1 p-3 bg-surface-container border border-outline-variant rounded-xl text-sm focus:outline-none"
          />
          <button
            onClick={handleScan}
            disabled={isScanning}
            className="px-6 bg-primary text-on-primary font-bold rounded-xl hover:brightness-110 active:scale-95 transition-transform"
          >
            Scan Print
          </button>
        </div>
      </div>
    </div>
  );
}
