// ─── useDashboardStats ─────────────────────────────────────────────────────────
// A custom React hook that computes all dashboard KPI values and chart data
// directly from the patient database stored in localStorage.
//
// ► Listens to the custom "asha_data_changed" event fired by saveFamilies().
// ► Recalculates all stats instantly — no page reload needed.
// ► Returns a plain object; components are responsible only for rendering.
// ──────────────────────────────────────────────────────────────────────────────

import { useState, useEffect, useCallback } from 'react';
import { getStoredFamilies } from '../database/mockData';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Flattens the nested families → members structure into a plain array of
 * patient objects, each enriched with their parent family's metadata.
 */
function buildAllPatients(families) {
  const patients = [];
  families.forEach(fam => {
    fam.members.forEach(member => {
      patients.push({
        ...member,
        familyId: fam.id,
        familyName: fam.name,
        familyAddress: fam.address,
      });
    });
  });
  return patients;
}

/**
 * Determines whether a patient needs a clinic check.
 * Criteria: riskLevel is "High" | "Critical", OR has an alert of type
 * "Critical", OR pregnancyDetails.riskLevel is "High" | "Critical".
 */
function needsClinicCheck(patient) {
  const topLevel = (patient.riskLevel || '').toLowerCase();
  if (topLevel === 'high' || topLevel === 'critical') return true;

  const hasAlertCritical = (patient.alerts || []).some(
    a => (a.type || '').toLowerCase() === 'critical'
  );
  if (hasAlertCritical) return true;

  const pregRisk = (patient.pregnancyDetails?.riskLevel || '').toLowerCase();
  if (pregRisk === 'high' || pregRisk === 'critical') return true;

  return false;
}

/**
 * Checks whether a patient has completed all their scheduled vaccinations.
 * A patient is "fully vaccinated" when they have ≥1 vaccination record AND
 * every record has status "Completed" (case-insensitive).
 */
function isFullyVaccinated(patient) {
  const vacs = patient.vaccinations || [];
  return vacs.length > 0 && vacs.every(v => (v.status || '').toLowerCase() === 'completed');
}

// ─── Core computation ─────────────────────────────────────────────────────────

function computeStats() {
  const families = getStoredFamilies();
  const allPatients = buildAllPatients(families);

  // ── KPI counters ─────────────────────────────────────────────────────────
  const totalPatients = allPatients.length;

  const pregnantMothers = allPatients.filter(
    p => p.pregnancyDetails && (p.pregnancyDetails.weeks || 0) > 0
  ).length;

  const requiresClinicCheck = allPatients.filter(needsClinicCheck).length;

  // ── Pregnancy KPIs ────────────────────────────────────────────────────────
  const todayStr = new Date().toISOString().split('T')[0];
  const tomorrowStr = new Date(Date.now() + 86400000).toISOString().split('T')[0];

  let highRiskPregnancy = 0;
  let ancDueToday = 0;
  let ancDueTomorrow = 0;
  let missedAnc = 0;
  let expectedDeliveries = 0;
  let ttPending = 0;
  let ironPending = 0;

  allPatients.forEach(p => {
    if (p.pregnancyDetails) {
      const pd = p.pregnancyDetails;
      if (pd.riskLevel === 'High') {
        highRiskPregnancy++;
      }
      
      const schedule = pd.ancSchedule || [];
      schedule.forEach(v => {
        if (v.status !== 'Completed') {
          if (v.scheduledDate === todayStr) {
            ancDueToday++;
          } else if (v.scheduledDate === tomorrowStr) {
            ancDueTomorrow++;
          } else if (v.scheduledDate < todayStr) {
            missedAnc++;
          }
        }
      });

      if (pd.edd) {
        const eddMonth = pd.edd.substring(0, 7);
        const thisMonth = todayStr.substring(0, 7);
        if (eddMonth === thisMonth) {
          expectedDeliveries++;
        }
      }

      const meds = pd.medicines || [];
      if (meds.some(m => m.name.includes('TT') && m.status === 'Pending')) {
        ttPending++;
      }
      if (meds.some(m => m.name.includes('Iron') && m.status === 'Pending')) {
        ironPending++;
      }
    }
  });

  // Count individual vaccine records (not patients) that are "Completed"
  let completedVaccinations = 0;
  let partialVaccinations   = 0;
  let dueVaccinations       = 0;
  let overdueVaccinations   = 0;

  allPatients.forEach(p => {
    const vacs = p.vaccinations || [];
    if (vacs.length === 0) {
      dueVaccinations += 1; // has no vaccines yet — considered due
      return;
    }

    const allDone    = vacs.every(v => (v.status || '').toLowerCase() === 'completed');
    const someDone   = vacs.some(v  => (v.status || '').toLowerCase() === 'completed');
    const hasOverdue = vacs.some(v  => (v.status || '').toLowerCase() === 'overdue');

    if (allDone)         completedVaccinations += 1;
    else if (hasOverdue) overdueVaccinations   += 1;
    else if (someDone)   partialVaccinations   += 1;
    else                 dueVaccinations       += 1;
  });

  const totalVaccinationTarget = totalPatients; // every patient is a target

  const coveragePct = totalVaccinationTarget > 0
    ? Math.round((completedVaccinations / totalVaccinationTarget) * 100)
    : 0;

  // ── Village / area stats ──────────────────────────────────────────────────
  const villageMap = {};
  allPatients.forEach(p => {
    const addr = p.familyAddress || 'Unknown';
    // Extract a short village name (first comma-separated segment)
    const village = addr.split(',')[0].trim();
    if (!villageMap[village]) villageMap[village] = { total: 0, highRisk: 0 };
    villageMap[village].total += 1;
    if (needsClinicCheck(p)) villageMap[village].highRisk += 1;
  });

  // ── Gender distribution ───────────────────────────────────────────────────
  const genderMap = {};
  allPatients.forEach(p => {
    const g = p.gender || 'Unknown';
    genderMap[g] = (genderMap[g] || 0) + 1;
  });

  // ── Age group distribution ────────────────────────────────────────────────
  const ageGroups = { '0-5': 0, '6-14': 0, '15-25': 0, '26-45': 0, '46-60': 0, '60+': 0 };
  allPatients.forEach(p => {
    const age = Number(p.age) || 0;
    if      (age <= 5)   ageGroups['0-5']   += 1;
    else if (age <= 14)  ageGroups['6-14']  += 1;
    else if (age <= 25)  ageGroups['15-25'] += 1;
    else if (age <= 45)  ageGroups['26-45'] += 1;
    else if (age <= 60)  ageGroups['46-60'] += 1;
    else                 ageGroups['60+']   += 1;
  });

  // ── Recent activity feed ──────────────────────────────────────────────────
  // Build a list of timestamped events from real records
  const recentActivity = [];
  allPatients.forEach(p => {
    // Last vaccination
    (p.vaccinations || []).forEach(v => {
      if (v.date) {
        recentActivity.push({
          type: 'vaccination',
          icon: 'vaccines',
          color: 'emerald',
          label: `${p.name} — ${v.vaccine}`,
          sub: `Status: ${v.status}`,
          date: v.date,
        });
      }
    });
    // Medical history entries
    (p.medicalHistory || []).forEach(h => {
      if (h.date) {
        recentActivity.push({
          type: 'medical',
          icon: 'local_hospital',
          color: 'blue',
          label: `${p.name} — ${h.condition}`,
          sub: h.notes || '',
          date: h.date,
        });
      }
    });
    // Pregnancy first visit
    if (p.pregnancyDetails) {
      recentActivity.push({
        type: 'pregnancy',
        icon: 'pregnant_woman',
        color: 'pink',
        label: `${p.name} — ANC Registered`,
        sub: `${p.pregnancyDetails.weeks} weeks · EDD ${p.pregnancyDetails.edd}`,
        date: p.pregnancyDetails.edd || '',
      });
    }
  });

  // Sort most-recent first, limit to 8
  recentActivity.sort((a, b) => (b.date > a.date ? 1 : -1));
  const latestActivity = recentActivity.slice(0, 8);

  // ── Vaccination donut data ─────────────────────────────────────────────────
  // Compute SVG strokeDashoffset values for the donut chart
  const CIRCUMFERENCE = 251.2; // 2π × r=40
  const fullyPct     = totalVaccinationTarget > 0 ? completedVaccinations / totalVaccinationTarget : 0;
  const partialPct   = totalVaccinationTarget > 0 ? partialVaccinations   / totalVaccinationTarget : 0;
  const duePct       = totalVaccinationTarget > 0 ? dueVaccinations       / totalVaccinationTarget : 0;
  const overduePct   = totalVaccinationTarget > 0 ? overdueVaccinations   / totalVaccinationTarget : 0;

  // Arc offset = circumference × (1 - fraction) — the unfilled portion
  const fullyOffset   = CIRCUMFERENCE * (1 - fullyPct);
  const partialOffset = CIRCUMFERENCE - CIRCUMFERENCE * partialPct; // second arc offset

  return {
    // KPI Cards
    totalPatients,
    pregnantMothers,
    requiresClinicCheck,
    completedVaccinations,
    highRiskPregnancy,
    ancDueToday,
    ancDueTomorrow,
    missedAnc,
    expectedDeliveries,
    ttPending,
    ironPending,

    // Vaccination Coverage
    coveragePct,
    totalVaccinationTarget,
    partialVaccinations,
    dueVaccinations,
    overdueVaccinations,

    // Donut chart SVG values
    fullyOffset,
    partialOffset,
    CIRCUMFERENCE,

    // Charts / breakdowns
    villageMap,
    genderMap,
    ageGroups,

    // Activity feed
    latestActivity,

    // Raw data (for search)
    allPatients,
    families,
  };
}

// ─── Hook ─────────────────────────────────────────────────────────────────────

export function useDashboardStats() {
  const [stats, setStats] = useState(() => computeStats());

  const refresh = useCallback(() => {
    setStats(computeStats());
  }, []);

  useEffect(() => {
    // Re-compute whenever any component writes new patient data
    window.addEventListener('asha_data_changed', refresh);
    // Also handle cross-tab updates (e.g. another browser tab)
    window.addEventListener('storage', refresh);

    return () => {
      window.removeEventListener('asha_data_changed', refresh);
      window.removeEventListener('storage', refresh);
    };
  }, [refresh]);

  return stats;
}
