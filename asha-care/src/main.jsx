import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

// ─── ONE-TIME DATA PURGE ──────────────────────────────────────────────────────
// Clears all demo/local patient data from localStorage immediately.
// Safe to remove this block after the first load confirms data is gone.
localStorage.removeItem('asha_families');
localStorage.removeItem('asha_data_version');
// ─────────────────────────────────────────────────────────────────────────────

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
