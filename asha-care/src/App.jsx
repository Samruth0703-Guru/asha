import React, { useState, useMemo, useEffect } from 'react';
import { useDashboardStats } from './hooks/useDashboardStats';
import { syncFromFirestore } from './database/mockData';
import './database/syncEngine';
import Sidebar from './components/Sidebar';
import Registration from './components/Registration';
import Dashboard from './components/Dashboard';

// Import newly created pages
import Patients from './components/Patients';
import Mothers from './components/Mothers';
import Pregnancies from './components/Pregnancies';
import Vaccination from './components/Vaccination';
import SmsPanel from './components/SmsPanel';
import Inventory from './components/Inventory';
import CancerCare from './components/CancerCare';
import Reports from './components/Reports';
import VisitsHistory from './components/VisitsHistory';
import Support from './components/Support';
import AiHealthAssistant from './components/AiHealthAssistant';
import Settings from './components/Settings';

const translations = {
  en: {
    dashboard: "Dashboard",
    patients: "Patients",
    mothers: "Mothers",
    pregnancies: "Pregnancies",
    immunizations: "Immunizations",
    inventory: "Inventory",
    ai_assistant: "AI Health Assistant",
    cancer_care: "Cancer Care",
    reports: "Reports",
    visits_history: "Visits History",
    support: "Support",
    settings: "Settings",
    logout: "Logout",
    welcome_doctor: "Welcome back, Doctor!",
    welcome_title: "Welcome to ASHA Care Block Console",
    welcome_sub: "District PHC administrative center. Track community health, vaccine metrics, and clinic stock.",
    reg_patient: "Register New Patient",
    today_date: "Today's Date",
    registered_patients: "Registered Patients",
    maternal_cases: "Maternal Care Cases",
    high_risk_cases: "High Risk Cases",
    vaccinations_done: "Vaccinations Done",
    live_db: "Live from database",
    village_health: "Village Health Overview",
    vaccination_coverage: "Vaccination Coverage",
    quick_actions: "Quick Actions",
    search_placeholder: "Search patients, villages, health records...",
    back_to_dashboard: "Back to Dashboard",
    back_to_main: "Back to Main Dashboard",
    language_settings: "Language Settings",
    select_language: "Select System Language",
    extra_settings: "Extra Features & Settings",
    offline_sync: "Enable Offline Local Database Sync",
    biometric_bypass: "Bypass Biometric Verification for Testing",
    voice_assistant_auto: "Enable Auto Voice assistant activation",
    developer_mode: "Activate Developer Audit Logs",
    save_settings: "Save Settings Configuration",
    settings_saved: "Settings updated successfully!",
    total_patients: "Total Patients",
    pregnant_mothers: "Pregnant Mothers",
    requires_clinic: "Requires Clinic Check",
    completed_immunizations: "Completed Immunizations",
    total_target: "Total Target",
    total_achieved: "Total Achieved",
    fully_vaccinated: "Fully Vaccinated",
    partially_vaccinated: "Partially Vaccinated",
    due: "Due",
    overdue: "Overdue"
  },
  ta: {
    dashboard: "முகப்புப்பலகை",
    patients: "நோயாளிகள்",
    mothers: "தாய்மார்கள்",
    pregnancies: "கர்ப்பிணிகள்",
    immunizations: "தடுப்பூசிகள்",
    inventory: "சரக்கு இருப்பு",
    ai_assistant: "செயற்கை நுண்ணறிவு உதவியாளர்",
    cancer_care: "புற்றுநோய் சிகிச்சை",
    reports: "அறிக்கைகள்",
    visits_history: "வருகை வரலாறு",
    support: "ஆதரவு",
    settings: "அமைப்புகள்",
    logout: "வெளியேறு",
    welcome_doctor: "வரவேற்கிறோம், மருத்துவரே!",
    welcome_title: "ஆஷா கேர் பிளாக் கன்சோலுக்கு உங்களை வரவேற்கிறோம்",
    welcome_sub: "வட்டார ஆரம்ப சுகாதார நிலைய நிர்வாக மையம். சமூக ஆரோக்கியம் மற்றும் தடுப்பூசிகளை கண்காணிக்கவும்.",
    reg_patient: "புதிய நோயாளியைப் பதிவுசெய்க",
    today_date: "இன்றைய தேதி",
    registered_patients: "பதிவுசெய்யப்பட்ட நோயாளிகள்",
    maternal_cases: "மகப்பேறு பராமரிப்பு வழக்குகள்",
    high_risk_cases: "அதிதீவிர ஆபத்துள்ள வழக்குகள்",
    vaccinations_done: "தடுப்பூசிகள் செலுத்தப்பட்டன",
    live_db: "தரவுத்தளத்திலிருந்து நேரலை",
    village_health: "கிராம சுகாதார மேலோட்டம்",
    vaccination_coverage: "தடுப்பூசி செலுத்துதல் அளவு",
    quick_actions: "விரைவான செயல்கள்",
    search_placeholder: "நோயாளிகள், கிராமங்கள், சுகாதார பதிவுகளைத் தேடுங்கள்...",
    back_to_dashboard: "முகப்புப்பக்கத்திற்குத் திரும்பு",
    back_to_main: "முதன்மை முகப்புப்பலகைக்குத் திரும்பு",
    language_settings: "மொழி அமைப்புகள்",
    select_language: "முறைமை மொழியைத் தேர்ந்தெடுக்கவும்",
    extra_settings: "கூடுதல் அம்சங்கள் மற்றும் அமைப்புகள்",
    offline_sync: "ஆஃப்லைன் உள்ளூர் தரவுத்தள ஒத்திசைவை இயக்கு",
    biometric_bypass: "சோதனைக்காக பயோமெட்ரிக் சரிபார்ப்பைத் தவிர்க்கவும்",
    voice_assistant_auto: "தானியங்கி குரல் உதவியாளர் செயல்பாட்டை இயக்கு",
    developer_mode: "டெவலப்பர் தணிக்கை பதிவுகளைச் செயல்படுத்து",
    save_settings: "அமைப்புகள் உள்ளமைவைச் சேமிக்கவும்",
    settings_saved: "அமைப்புகள் வெற்றிகரமாக புதுப்பிக்கப்பட்டன!",
    total_patients: "மொத்த நோயாளிகள்",
    pregnant_mothers: "கர்ப்பிணி தாய்மார்கள்",
    requires_clinic: "மருத்துவமனை சரிபார்ப்பு தேவை",
    completed_immunizations: "முடிந்த தடுப்பூசிகள்",
    total_target: "மொத்த இலக்கு",
    total_achieved: "மொத்த சாதனை",
    fully_vaccinated: "முழுமையாக தடுப்பூசி போடப்பட்டது",
    partially_vaccinated: "பகுதியளவு தடுப்பூசி போடப்பட்டது",
    due: "பாக்கி",
    overdue: "காலக்கெடு முடிந்தது"
  },
  hi: {
    dashboard: "डैशबोर्ड",
    patients: "मरीज़",
    mothers: "माताएं",
    pregnancies: "गर्भावस्था",
    immunizations: "टीकाकरण",
    inventory: "इन्वेंटरी",
    ai_assistant: "एआई स्वास्थ्य सहायक",
    cancer_care: "कैंसर देखभाल",
    reports: "रिपोर्ट",
    visits_history: "दौरे का इतिहास",
    support: "सहायता",
    settings: "सेटिंग्स",
    logout: "लॉगआउट",
    welcome_doctor: "स्वागत है, डॉक्टर!",
    welcome_title: "आशा केयर ब्लॉक कंसोल में आपका स्वागत है",
    welcome_sub: "जिला पीएचसी प्रशासनिक केंद्र। सामुदायिक स्वास्थ्य, वैक्सीन मेट्रिक्स और स्टॉक ट्रैक करें।",
    reg_patient: "नया मरीज़ पंजीकृत करें",
    today_date: "आज की तारीख",
    registered_patients: "पंजीकृत मरीज़",
    maternal_cases: "मातृत्व देखभाल मामले",
    high_risk_cases: "उच्च जोखिम वाले मामले",
    vaccinations_done: "टीकाकरण संपन्न",
    live_db: "डेटाबेस से लाइव",
    village_health: "ग्राम स्वास्थ्य अवलोकन",
    vaccination_coverage: "टीकाकरण कवरेज",
    quick_actions: "त्वरित कार्रवाई",
    search_placeholder: "मरीज़ों, गाँवों, स्वास्थ्य रिकॉर्ड खोजें...",
    back_to_dashboard: "डैशबोर्ड पर वापस जाएं",
    back_to_main: "मुख्य डैशबोर्ड पर वापस जाएं",
    language_settings: "भाषा सेटिंग्स",
    select_language: "सिस्टम भाषा चुनें",
    extra_settings: "अतिरिक्त सुविधाएँ और सेटिंग्स",
    offline_sync: "ऑफ़लाइन स्थानीय डेटाबेस सिंक सक्षम करें",
    biometric_bypass: "परीक्षण के लिए बायोमेट्रिक सत्यापन बायपास करें",
    voice_assistant_auto: "ऑटो वॉयस असिस्टेंट सक्रियण सक्षम करें",
    developer_mode: "डेवलपर ऑडिट लॉग सक्रिय करें",
    save_settings: "सेटिंग्स कॉन्फ़िगरेशन सहेजें",
    settings_saved: "सेटिंग्स सफलतापूर्वक अपडेट की गईं!",
    total_patients: "कुल मरीज़",
    pregnant_mothers: "गर्भवती माताएं",
    requires_clinic: "क्लिनिक जांच की आवश्यकता है",
    completed_immunizations: "पूर्ण टीकाकरण",
    total_target: "कुल लक्ष्य",
    total_achieved: "कुल उपलब्धि",
    fully_vaccinated: "पूर्णतः प्रतिरक्षित",
    partially_vaccinated: "आंशिक रूप से प्रतिरक्षित",
    due: "देय",
    overdue: "अतिदेय"
  },
  ml: {
    dashboard: "ഡാഷ്‌ബോർഡ്",
    patients: "രോഗികൾ",
    mothers: "അമ്മമാർ",
    pregnancies: "ഗർഭാവസ്ഥ",
    immunizations: "പ്രതിരോധ കുത്തിവയ്പ്പ്",
    inventory: "ഇൻവെന്ററി",
    ai_assistant: "AI ആരോഗ്യ സഹായി",
    cancer_care: "കാൻസർ പരിചരണം",
    reports: "റിപ്പോർട്ടുകൾ",
    visits_history: "സന്ദർശന ചരിത്രം",
    support: "പിന്തുണ",
    settings: "ക്രമീകരണങ്ങൾ",
    logout: "ലോഗ്ഔട്ട്",
    welcome_doctor: "സ്വാഗതം, ഡോക്ടർ!",
    welcome_title: "ആശ കെയർ ബ്ലോക്ക് കൺസോളിലേക്ക് സ്വാഗതം",
    welcome_sub: "ജില്ലാ പിഎച്ച്സി ഭരണകേന്ദ്രം. കമ്മ്യൂണിറ്റി ആരോഗ്യവും വാക്സിൻ നിലയും നിരീക്ഷിക്കുക.",
    reg_patient: "പുതിയ രോഗിയെ രജിസ്റ്റർ ചെയ്യുക",
    today_date: "ഇന്നത്തെ തീയതി",
    registered_patients: "രജിസ്റ്റർ ചെയ്ത രോഗികൾ",
    maternal_cases: "മാതൃ പരിചരണ കേസുകൾ",
    high_risk_cases: "ഉയർന്ന അപകടസാധ്യതയുള്ള കേസുകൾ",
    vaccinations_done: "പ്രതിരോധ കുത്തിവയ്പ്പുകൾ പൂർത്തിയായി",
    live_db: "ഡാറ്റാബേസിൽ നിന്ന് തത്സമയം",
    village_health: "ഗ്രാമ ആരോഗ്യ അവലോകനം",
    vaccination_coverage: "വാക്സിനേഷൻ കവറേജ്",
    quick_actions: "ദ്രുത പ്രവർത്തനങ്ങൾ",
    search_placeholder: "രോഗികൾ, ഗ്രാമങ്ങൾ, ആരോഗ്യ രേഖകൾ തിരയുക...",
    back_to_dashboard: "ഡാഷ്‌ബോർഡിലേക്ക് തിരികെ പോകുക",
    back_to_main: "പ്രധാന ഡാഷ്‌ബോർഡിലേക്ക് പോകുക",
    language_settings: "ഭാഷാ ക്രമീകരണങ്ങൾ",
    select_language: "സിസ്റ്റം ഭാഷ തിരഞ്ഞെടുക്കുക",
    extra_settings: "അധിക ഫീച്ചറുകളും ക്രമീകരണങ്ങളും",
    offline_sync: "ഓഫ്‌ലൈൻ ലോക്കൽ ഡാറ്റാബേസ് സമന്വയം പ്രവർത്തനക്ഷമമാക്കുക",
    biometric_bypass: "പരിശോധനയ്ക്കായി ബയോമെട്രിക് സ്ഥിരീകരണം ഒഴിവാക്കുക",
    voice_assistant_auto: "ഓട്ടോ വോയ്‌സ് അസിസ്റ്റന്റ് ആക്ടിവേഷൻ പ്രവർത്തനക്ഷമമാക്കുക",
    developer_mode: "ഡെവലപ്പർ ഓഡിറ്റ് ലോഗുകൾ സജീവമാക്കുക",
    save_settings: "ക്രമീകരണങ്ങൾ സംരക്ഷിക്കുക",
    settings_saved: "ക്രമീകരണങ്ങൾ വിജയകരമായി അപ്ഡേറ്റ് ചെയ്തു!",
    total_patients: "ആകെ രോഗികൾ",
    pregnant_mothers: "ഗർഭിണികളായ അമ്മമാർ",
    requires_clinic: "ക്ലിനിക്ക് പരിശോധന ആവശ്യമാണ്",
    completed_immunizations: "പൂർത്തിയായ കുത്തിവയ്പ്പുകൾ",
    total_target: "ആകെ ലക്ഷ്യം",
    total_achieved: "ആകെ കൈവരിച്ചത്",
    fully_vaccinated: "പൂർണ്ണമായി വാക്സിനേഷൻ എടുത്തു",
    partially_vaccinated: "ഭാഗികമായി വാക്സിനേഷൻ എടുത്തു",
    due: "ബാക്കി",
    overdue: "കാലാവധി കഴിഞ്ഞത്"
  },
  kn: {
    dashboard: "ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
    patients: "ರೋಗಿಗಳು",
    mothers: "ತಾಯಂದಿರು",
    pregnancies: "ಗರ್ಭಾವಸ್ಥೆ",
    immunizations: "ಲಸಿಕಾಕರಣ",
    inventory: "ದಾಸ್ತಾನು",
    ai_assistant: "AI ಆರೋಗ್ಯ ಸಹಾಯಕ",
    cancer_care: "ಕ್ಯಾನ್ಸರ್ ಆರೈಕೆ",
    reports: "ವರದಿಗಳು",
    visits_history: "ಭೇಟಿ ಇತಿಹಾಸ",
    support: "ಬೆಂಬಲ",
    settings: "ಸೆಟ್ಟಿಂಗ್ಸ್",
    logout: "ಲಾಗ್ ಔಟ್",
    welcome_doctor: "ಸ್ವಾಗತ, ವೈದ್ಯರೇ!",
    welcome_title: "ಆಶಾ ಕೇರ್ ಬ್ಲಾಕ್ ಕನ್ಸೋಲ್‌ಗೆ ಸ್ವಾಗತ",
    welcome_sub: "ಜಿಲ್ಲಾ ಪಿಎಚ್‌ಸಿ ಆಡಳಿತ ಕೇಂದ್ರ. ಸಮುದಾಯ ಆರೋಗ್ಯ ಮತ್ತು ಲಸಿಕೆ ಅಂಕಿಅಂಶಗಳನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಿ.",
    reg_patient: "ಹೊಸ ರೋಗಿ ನೋಂದಾಯಿಸಿ",
    today_date: "ಇಂದಿನ ದಿನಾಂಕ",
    registered_patients: "ನೋಂದಾಯಿತ ರೋಗಿಗಳು",
    maternal_cases: "ಮಾತೃತ್ವ ಆರೈಕೆ ಪ್ರಕರಣಗಳು",
    high_risk_cases: "ಹೆಚ್ಚಿನ ಅಪಾಯದ ಪ್ರಕರಣಗಳು",
    vaccinations_done: "ಲಸಿಕೆಗಳು ಪೂರ್ಣಗೊಂಡಿವೆ",
    live_db: "ಡೇಟಾಬೇಸ್‌ನಿಂದ ಲೈವ್",
    village_health: "ಗ್ರಾಮ ಆರೋಗ್ಯ ಅವಲೋಕನ",
    vaccination_coverage: "ಲಸಿಕೆ ವ್ಯಾಪ್ತಿ",
    quick_actions: "ತ್ವರಿತ ಕ್ರಮಗಳು",
    search_placeholder: "ರೋಗಿಗಳು, ಹಳ್ಳಿಗಳು, ಆರೋಗ್ಯ ದಾಖಲೆಗಳನ್ನು ಹುಡುಕಿ...",
    back_to_dashboard: "ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ಗೆ ಹಿಂತಿರುಗಿ",
    back_to_main: "ಮುಖ್ಯ ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ಗೆ ಹಿಂತಿರುಗಿ",
    language_settings: "ಭಾಷಾ ಸೆಟ್ಟಿಂಗ್ಸ್",
    select_language: "ಸಿಸ್ಟಮ್ ಭಾಷೆಯನ್ನು ಆರಿಸಿ",
    extra_settings: "ಹೆಚ್ಚುವರಿ ವೈಶಿಷ್ಟ್ಯಗಳು ಮತ್ತು ಸೆಟ್ಟಿಂಗ್ಸ್",
    offline_sync: "ಆಫ್‌ಲೈನ್ ಸ್ಥಳೀಯ ಡೇಟಾಬೇಸ್ ಸಿಂಕ್ ಸಕ್ರಿಯಗೊಳಿಸಿ",
    biometric_bypass: "ಪರೀಕ್ಷೆಗಾಗಿ ಬಯೋಮೆಟ್ರಿಕ್ ಪರಿಶೀಲನೆಯನ್ನು ಬೈಪಾಸ್ ಮಾಡಿ",
    voice_assistant_auto: "ಸ್ವಯಂ ಧ್ವನಿ ಸಹಾಯಕ ಸಕ್ರಿಯಗೊಳಿಸುವಿಕೆಯನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ",
    developer_mode: "ಡೆವಲಪರ್ ಆಡಿಟ್ ಲಾಗ್‌ಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ",
    save_settings: "ಸೆಟ್ಟಿಂಗ್ಸ್ ಕಾನ್ಫಿಗರೇಶನ್ ಉಳಿಸಿ",
    settings_saved: "ಸೆಟ್ಟಿಂಗ್ಸ್ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ!",
    total_patients: "ಒಟ್ಟು ರೋಗಿಗಳು",
    pregnant_mothers: "ಗರ್ಭಿಣಿ ತಾಯಂದಿರು",
    requires_clinic: "ಕ್ಲಿನಿಕ್ ತಪಾಸಣೆ ಅಗತ್ಯವಿದೆ",
    completed_immunizations: "ಪೂರ್ಣಗೊಂಡ ಲಸಿಕೆಗಳು",
    total_target: "ಒಟ್ಟು ಗುರಿ",
    total_achieved: "ಒಟ್ಟು ಸಾಧನೆ",
    fully_vaccinated: "ಸಂಪೂರ್ಣವಾಗಿ ಲಸಿಕೆ ಹಾಕಲಾಗಿದೆ",
    partially_vaccinated: "ಭಾಗಶಃ ಲಸಿಕೆ ಹಾಕಲಾಗಿದೆ",
    due: "ಬಾಕಿ",
    overdue: "ಅವಧಿ ಮೀರಿದ"
  },
  te: {
    dashboard: "డ్యాష్‌బోర్డ్",
    patients: "రోగులు",
    mothers: "తల్లులు",
    pregnancies: "గర్భధారణలు",
    immunizations: "టీకాలు",
    inventory: "ఇన్వెంటరీ",
    ai_assistant: "AI ఆరోగ్య సహాయకుడు",
    cancer_care: "క్యాన్సర్ సంరక్షణ",
    reports: "నివేదికలు",
    visits_history: "సందర్శన చరిత్ర",
    support: "మద్దతు",
    settings: "సెట్టింగులు",
    logout: "లాగ్అవుట్",
    welcome_doctor: "స్వాగతం, డాక్టర్!",
    welcome_title: "ఆశా కేర్ బ్లాక్ కన్సోల్‌కు ప్రవేశం",
    welcome_sub: "జిల్లా పీహెచ్‌సీ పరిపాలనా కేంద్రం. కమ్యూనిటీ ఆరోగ్యం మరియు వ్యాక్సిన్ వివరాలను పర్యవేక్షించండి.",
    reg_patient: "కొత్త రోగిని నమోదు చేయండి",
    today_date: "నేటి తేదీ",
    registered_patients: "నమోదైన రోగులు",
    maternal_cases: "మాతృ సంరక్షణ కేసులు",
    high_risk_cases: "అధిక ప్రమాద కేసులు",
    vaccinations_done: "టీకాలు వేయబడ్డాయి",
    live_db: "డేటాబేస్ నుండి లైవ్",
    village_health: "ఆరోగ్య గ్రామ అవలోకనం",
    vaccination_coverage: "టీకా కవరేజ్",
    quick_actions: "త్వరిత చర్యలు",
    search_placeholder: "రోగులు, గ్రామాలు, ఆరోగ్య రికార్డులను వెతకండి...",
    back_to_dashboard: "డ్యాష్‌బోర్డ్‌కు తిరిగి వెళ్ళు",
    back_to_main: "ప్రధాన డ్యాష్‌బోర్డ్‌కు తిరిగి వెళ్ళు",
    language_settings: "భాషా సెట్టింగులు",
    select_language: "సిస్టమ్ భాషను ఎంచుకోండి",
    extra_settings: "అదనపు ఫీచర్లు & సెట్టింగులు",
    offline_sync: "ఆఫ్‌లైన్ స్థానిక డేటాబేస్ సమకాలీకరణను ప్రారంభించు",
    biometric_bypass: "పరీక్ష కోసం బయోమెట్రిక్ ధృవీకరణను దాటవేయి",
    voice_assistant_auto: "ఆటో వాయిస్ అసిస్టెంట్ యాక్టివేషన్‌ను ప్రారంభించు",
    developer_mode: "డెవలపర్ ఆడిట్ లాగ్‌లను సక్రియం చేయి",
    save_settings: "సెట్టింగుల కాన్ఫిగరేషన్‌ను సేవ్ చేయి",
    settings_saved: "సెట్టింగులు విజయవంతంగా నవీకరించబడ్డాయి!",
    total_patients: "మొత్తం రోగులు",
    pregnant_mothers: "గర్భవతులు",
    requires_clinic: "క్లినిక్ తనిఖీ అవసరం",
    completed_immunizations: "పూర్తయిన టీకాలు",
    total_target: "మొత్తం లక్ష్యం",
    total_achieved: "మొత్తం సాధించినది",
    fully_vaccinated: "పూర్తిగా టీకా వేయబడింది",
    partially_vaccinated: "పాక్షికంగా టీకా వేయబడింది",
    due: "బాకీ",
    overdue: "గడువు ముగిసిన"
  },
  pa: {
    dashboard: "ਡੈਸ਼ਬੋਰਡ",
    patients: "ਮਰੀਜ਼",
    mothers: "ਮਾਵਾਂ",
    pregnancies: "ਗਰਭ ਅਵਸਥਾ",
    immunizations: "ਟੀਕਾਕਰਨ",
    inventory: "ਇਨਵੈਂਟਰੀ",
    ai_assistant: "AI ਸਿਹਤ ਸਹਾਇਕ",
    cancer_care: "ਕੈਂਸਰ ਦੇਖਭਾਲ",
    reports: "ਰਿਪੋਰਟਾਂ",
    visits_history: "ਦੌਰੇ ਦਾ ਇਤਿਹਾਸ",
    support: "ਸਹਾਇਤਾ",
    settings: "ਸੈਟਿੰਗਾਂ",
    logout: "ਲੌਗਆਉਟ",
    welcome_doctor: "ਜੀ ਆਇਆਂ ਨੂੰ, ਡਾਕਟਰ ਸਾਹਿਬ!",
    welcome_title: "ਆਸ਼ਾ ਕੇਅਰ ਬਲਾਕ ਕੰਸੋਲ ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ",
    welcome_sub: "ਜ਼ਿਲ੍ਹਾ ਪੀਐਚਸੀ ਪ੍ਰਸ਼ਾਸਨਿਕ ਕੇਂਦਰ। ਕਮਿਊਨਿਟੀ ਸਿਹਤ ਅਤੇ ਵੈਕਸੀਨ ਦੇ ਅੰਕੜਿਆਂ ਦੀ ਨਿਗਰਾਨੀ ਕਰੋ।",
    reg_patient: "ਨਵਾਂ ਮਰੀਜ਼ ਰਜਿਸਟਰ ਕਰੋ",
    today_date: "ਅੱਜ ਦੀ ਤਾਰੀਖ",
    registered_patients: "ਰਜਿਸਟਰਡ ਮਰੀਜ਼",
    maternal_cases: "ਮਾਵਾਂ ਦੀ ਦੇਖਭਾਲ ਦੇ ਕੇਸ",
    high_risk_cases: "ਉੱਚ ਜੋਖਮ ਵਾਲੇ ਕੇਸ",
    vaccinations_done: "ਟੀਕਾਕਰਨ ਮੁਕੰਮਲ",
    live_db: "ਡਾਟਾਬੇਸ ਤੋਂ ਲਾਈਵ",
    village_health: "ਪਿੰਡ ਦੀ ਸਿਹਤ ਸੰਖੇਪ",
    vaccination_coverage: "ਟੀਕਾਕਰਨ ਕਵਰੇਜ",
    quick_actions: "ਤੁਰੰਤ ਕਾਰਵਾਈਆਂ",
    search_placeholder: "ਮਰੀਜ਼ਾਂ, ਪਿੰਡਾਂ, ਸਿਹਤ ਰਿਕਾਰਡਾਂ ਦੀ ਖੋਜ ਕਰੋ...",
    back_to_dashboard: "ਡੈਸ਼ਬੋਰਡ 'ਤੇ ਵਾਪਸ ਜਾਓ",
    back_to_main: "ਮੁੱਖ ਡੈਸ਼ਬੋਰਡ 'ਤੇ ਵਾਪਸ ਜਾਓ",
    language_settings: "ਭਾਸ਼ਾ ਸੈਟਿੰਗਾਂ",
    select_language: "ਸਿਸਟਮ ਭਾਸ਼ਾ ਚੁਣੋ",
    extra_settings: "ਵਾਧੂ ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ ਅਤੇ ਸੈਟਿੰਗਾਂ",
    offline_sync: "ਔਫਲਾਈਨ ਸਥਾਨਕ ਡਾਟਾਬੇਸ ਸਿੰਕ ਨੂੰ ਸਮਰੱਥ ਕਰੋ",
    biometric_bypass: "ਟੈਸਟਿੰਗ ਲਈ ਬਾਇਓਮੀਟ੍ਰਿਕ ਤਸਦੀਕ ਨੂੰ ਬਾਈਪਾਸ ਕਰੋ",
    voice_assistant_auto: "ਆਟੋ ਵੌਇਸ ਅਸਿਸਟੈਂਟ ਐਕਟੀਵੇਸ਼ਨ ਨੂੰ ਸਮਰੱਥ ਕਰੋ",
    developer_mode: "ਡਿਵੈਲਪਰ ਆਡਿਟ ਲੌਗਸ ਨੂੰ ਸਰਗਰਮ ਕਰੋ",
    save_settings: "ਸੈਟਿੰਗਾਂ ਕੌਂਫਿਗਰੇਸ਼ਨ ਸੁਰੱਖਿਅਤ ਕਰੋ",
    settings_saved: "ਸੈਟਿੰਗਾਂ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤੀਆਂ ਗਈਆਂ!",
    total_patients: "ਕੁੱਲ ਮਰੀਜ਼",
    pregnant_mothers: "ਗਰਭਵਤੀ ਮਾਵਾਂ",
    requires_clinic: "ਕਲੀਨਿਕ ਜਾਂਚ ਦੀ ਲੋੜ ਹੈ",
    completed_immunizations: "ਪੂਰਾ ਹੋਇਆ ਟੀਕਾਕਰਨ",
    total_target: "ਕੁੱਲ ਟੀਚਾ",
    total_achieved: "ਕੁੱਲ ਪ੍ਰਾਪਤੀ",
    fully_vaccinated: "ਪੂਰੀ ਤਰ੍ਹਾਂ ਟੀਕਾਕਰਨ ਕੀਤਾ ਗਿਆ",
    partially_vaccinated: "ਆਂਸ਼ਿਕ ਤੌਰ 'ਤੇ ਟੀਕਾਕਰਨ ਕੀਤਾ ਗਿਆ",
    due: "ਦੇਣਦਾਰੀ",
    overdue: "ਬਕਾਇਆ"
  },
  gu: {
    dashboard: "ડેશબોર્ડ",
    patients: "દર્દીઓ",
    mothers: "માતાઓ",
    pregnancies: "સગર્ભાવસ્થા",
    immunizations: "રસીકરણ",
    inventory: "ઈન્વેન્ટરી",
    ai_assistant: "AI આરોગ્ય સહાયક",
    cancer_care: "કેન્સર સંભાળ",
    reports: "અહેવાલો",
    visits_history: "મુલાકાત ઇતિહાસ",
    support: "સહાય",
    settings: "સેટિંગ્સ",
    logout: "લોગઆઉट",
    welcome_doctor: "સ્વાગત છે, ડૉક્ટર!",
    welcome_title: "આશા કેર બ્લોક કન્સોલમાં આપનું સ્વાગત છે",
    welcome_sub: "જિલ્લા પીએચસી વહીવટી કેન્દ્ર. સામુદાયિક આરોગ્ય અને રસીના આંકડા મોનિટર કરો.",
    reg_patient: "નવા દર્દીની નોંધણી કરો",
    today_date: "આજની તારીખ",
    registered_patients: "નોંધાયેલા દર્દીઓ",
    maternal_cases: "માતૃત્વ સંભાળ કેસ",
    high_risk_cases: "ઉચ્ચ જોખમ ધરાવતા કેસ",
    vaccinations_done: "રસીકરણ પૂર્ણ",
    live_db: "ડેટાબેઝમાંથી લાઈવ",
    village_health: "ગ્રામ્ય આરોગ્ય સમીક્ષા",
    vaccination_coverage: "રસીકરણ કવરેજ",
    quick_actions: "ઝડપી કાર્યો",
    search_placeholder: "દર્દીઓ, ગામો, આરોગ્ય રેકોર્ડ શોધો...",
    back_to_dashboard: "ડેશબોર્ડ પર પાછા જાઓ",
    back_to_main: "મુખ્ય ડેશબોર્ડ પર પાછા જાઓ",
    language_settings: "ભાષા સેટિંગ્સ",
    select_language: "સિસ્ટમ ભાષા પસંદ કરો",
    extra_settings: "વધારાની સુવિધાઓ અને સેટિંગ્સ",
    offline_sync: "ઑફલાઇન સ્થાનિક ડેટાબેઝ સિંક સક્ષમ કરો",
    biometric_bypass: "પરીક્ષણ માટે બાયોમેટ્રિક વેરિફિકેશન બાયપાસ કરો",
    voice_assistant_auto: "ઑટો વૉઇસ આસિસ્ટન્ટ સક્રિયકરણ સક્ષમ કરો",
    developer_mode: "ડેવલપર ઓડિટ લોગ સક્રિય કરો",
    save_settings: "સેટિંગ્સ સાચવો",
    settings_saved: "સેટિંગ્સ સફળતાપૂર્વક અપડેટ થઈ ગઈ!",
    total_patients: "કુલ દર્દીઓ",
    pregnant_mothers: "સગર્ભા માતાઓ",
    requires_clinic: "ક્લિનિક તપાસની જરૂર છે",
    completed_immunizations: "પૂર્ણ રસીકરણ",
    total_target: "કુલ લક્ષ્ય",
    total_achieved: "કુલ સિદ્ધિ",
    fully_vaccinated: "સંપૂર્ણ રસીકરણ થયેલ",
    partially_vaccinated: "અંશતઃ રસીકરણ થયેલ",
    due: "બાકી",
    overdue: "વિલંબિત"
  },
  mr: {
    dashboard: "डॅशबोर्ड",
    patients: "रुग्ण",
    mothers: "माता",
    pregnancies: "गरोदरपण",
    immunizations: "लसीकरण",
    inventory: "इन्व्हेंटरी",
    ai_assistant: "AI आरोग्य सहाय्यक",
    cancer_care: "कर्करोग काळजी",
    reports: "अहवाल",
    visits_history: "भेटीचा इतिहास",
    support: "मदत",
    settings: "सेटिंग्ज",
    logout: "लॉगआउट",
    welcome_doctor: "स्वागत आहे, डॉक्टर!",
    welcome_title: "आशा केअर ब्लॉक कन्सोलमध्ये आपले स्वागत आहे",
    welcome_sub: "जिल्हा पीएचसी प्रशासकीय केंद्र. आरोग्य व लसीकरणाची आकडेवारी पहा.",
    reg_patient: "नवीन रुग्णाची नोंदणी करा",
    today_date: "आजची तारीख",
    registered_patients: "नोंदणीकृत रुग्ण",
    maternal_cases: "मातृ काळजी प्रकरणे",
    high_risk_cases: "उच्च जोखीम प्रकरणे",
    vaccinations_done: "लसीकरण पूर्ण",
    live_db: "डेटाबेसवरून थेट",
    village_health: "गाव आरोग्य आढावा",
    vaccination_coverage: "लसीकरण कव्हरेज",
    quick_actions: "जलद कृती",
    search_placeholder: "रुग्ण, गावे, आरोग्य रेकॉर्ड शोधा...",
    back_to_dashboard: "डॅशबोर्डवर परत जा",
    back_to_main: "मुख्य डॅशबोर्डवर परत जा",
    language_settings: "भाषा सेटिंग्ज",
    select_language: "सिस्टम भाषा निवडा",
    extra_settings: "अतिरिक्त वैशिष्ट्ये आणि सेटिंग्ज",
    offline_sync: "ऑफलाइन स्थानिक डेटाबेस सिंक सक्षम करा",
    biometric_bypass: "चाचणीसाठी बायोमेट्रिक पडताळणी बायपास करा",
    voice_assistant_auto: "ऑटो व्हॉइस असिस्टंट सक्रियकरण सक्षम करा",
    developer_mode: "डेव्हलपर ऑडिट लॉग सक्रिय करा",
    save_settings: "सेटिंग्ज जतन करा",
    settings_saved: "सेटिंग्ज यशस्वीरित्या जतन केल्या!",
    total_patients: "एकूण रुग्ण",
    pregnant_mothers: "गरोदर माता",
    requires_clinic: "क्लिनिक तपासणी आवश्यक",
    completed_immunizations: "पूर्ण लसीकरण",
    total_target: "एकूण लक्ष्य",
    total_achieved: "एकूण साध्य",
    fully_vaccinated: "पूर्णपणे लसीकरण झालेले",
    partially_vaccinated: "अंशतः लसीकरण झालेले",
    due: "थकीत",
    overdue: "मुदत संपलेली"
  }
};

function App() {
  const [currentTab, setCurrentTab] = useState('dashboard');

  const [smsPatientId, setSmsPatientId] = useState('');
  const [smsTemplate, setSmsTemplate] = useState('');

  const [syncState, setSyncState] = useState({
    status: navigator.onLine ? 'synced' : 'offline',
    pending: 0
  });
  const [toasts, setToasts] = useState([]);

  // Load persistent cloud records on startup
  useEffect(() => {
    syncFromFirestore();

    const handleSyncChange = (e) => {
      setSyncState({
        status: e.detail.status,
        pending: e.detail.pending
      });
    };

    const handleToast = (e) => {
      const { message, type } = e.detail;
      const newToast = { id: Date.now() + Math.random(), message, type };
      setToasts(prev => [...prev, newToast]);
      setTimeout(() => {
        setToasts(prev => prev.filter(t => t.id !== newToast.id));
      }, 4000);
    };

    // Set initial values
    try {
      const q = JSON.parse(localStorage.getItem('pending_sync_queue') || '[]');
      setSyncState({
        status: navigator.onLine ? 'synced' : 'offline',
        pending: q.length
      });
    } catch (err) {}

    window.addEventListener('asha_sync_status_changed', handleSyncChange);
    window.addEventListener('asha_toast_notification', handleToast);
    return () => {
      window.removeEventListener('asha_sync_status_changed', handleSyncChange);
      window.removeEventListener('asha_toast_notification', handleToast);
    };
  }, []);
  const [mapType, setMapType] = useState('m'); // 'm' for normal, 'k' for satellite, 'p' for terrain
  const [language, setLanguage] = useState(localStorage.getItem('asha_lang') || 'en');

  // Auth state
  const [familyId, setFamilyId] = useState('');
  const [activeMemberId, setActiveMemberId] = useState('');

  // ── Real-time dashboard statistics ────────────────────────────────────────
  const stats = useDashboardStats();

  // Search
  const [headerSearch, setHeaderSearch] = useState('');

  const t = (key) => {
    if (key === 'vaccination') {
      const vTrans = {
        en: 'Vaccination',
        ta: 'தடுப்பூசி',
        hi: 'टीकाकरण',
        ml: 'വാക്സിനേഷൻ',
        kn: 'ಲಸಿಕಾಕರಣ',
        te: 'టీకాలు',
        pa: 'ਟੀਕਾਕਰਨ',
        gu: 'રસીકરણ',
        mr: 'लसीकरण'
      };
      return vTrans[language] || vTrans['en'];
    }
    if (key === 'sms') {
      const sTrans = {
        en: 'SMS Alerts Desk',
        ta: 'எஸ்எம்எஸ் விழிப்பூட்டல்கள்',
        hi: 'एसएमएस अलर्ट',
        ml: 'എസ്എംഎസ് അലേർട്ടുകൾ',
        kn: 'ಮೊಬೈಲ್ ಸಂದೇಶ',
        te: 'మొబైల్ సందేశాలు',
        pa: 'ਮੋਬਾਈਲ ਸੁਨੇਹੇ',
        gu: 'મોબાઇલ સંદેશા',
        mr: 'मोबाईल संदेश'
      };
      return sTrans[language] || sTrans['en'];
    }
    return translations[language]?.[key] || translations['en']?.[key] || key;
  };

  const handleLanguageChange = (newLang) => {
    setLanguage(newLang);
    localStorage.setItem('asha_lang', newLang);
  };

  const handleAuthSuccess = (famId, memberId) => {
    setFamilyId(famId);
    setActiveMemberId(memberId);
    setCurrentTab('dashboard');
  };

  const handleSelectPatient = (famId, memberId) => {
    setFamilyId(famId);
    setActiveMemberId(memberId);
    setCurrentTab('dashboard');
  };

  const handleRegisterSuccess = () => {
    setCurrentTab('patients');
  };

  const handleLogout = () => {
    setFamilyId('');
    setActiveMemberId('');
    setCurrentTab('dashboard');
  };

  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex bg-[#f8fafc] text-slate-800 font-sans min-h-screen">
      {/* SideNavBar Shell */}
      <Sidebar 
        currentTab={currentTab} 
        setCurrentTab={setCurrentTab} 
        onLogout={handleLogout}
        t={t}
        isOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col md:pl-[260px] pl-0 w-full overflow-hidden">
        
        {/* TopNavBar Shell */}
        <header className="h-[70px] sticky top-0 z-10 bg-white flex justify-between items-center px-4 md:px-8 border-b border-slate-100">
          <div className="flex items-center gap-4 flex-1">
            <span onClick={() => setSidebarOpen(true)} className="material-symbols-outlined text-slate-400 cursor-pointer hover:text-slate-600 md:hidden block">menu</span>
            <div className="relative w-full max-w-md">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-lg">search</span>
              <input 
                className="w-full bg-[#f1f5f9] border-none rounded-xl py-2.5 pl-12 pr-4 text-xs font-semibold text-slate-700 placeholder-slate-400 outline-none focus:ring-1 focus:ring-emerald-500/30 transition-all" 
                placeholder={t('search_placeholder')} 
                type="text"
                value={headerSearch}
                onChange={e => {
                  setHeaderSearch(e.target.value);
                  if (e.target.value.trim()) setCurrentTab('patients');
                }}
              />
            </div>
          </div>
          
          <div className="flex items-center gap-6">
            {/* Sync Status Pill */}
            <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold shadow-sm border ${
              syncState.status === 'offline' ? 'bg-rose-50 border-rose-200 text-rose-700' :
              syncState.status === 'syncing' ? 'bg-amber-50 border-amber-200 text-amber-700 animate-pulse' :
              syncState.status === 'synced' ? 'bg-emerald-50 border-emerald-200 text-emerald-700' :
              'bg-blue-50 border-blue-200 text-blue-700'
            }`}>
              <span className="material-symbols-outlined text-sm">
                {syncState.status === 'offline' ? 'cloud_off' :
                 syncState.status === 'syncing' ? 'sync' : 'cloud_done'}
              </span>
              <span>
                {syncState.status === 'offline' ? 'Offline' :
                 syncState.status === 'syncing' ? 'Syncing...' : 'Synced'}
              </span>
              {syncState.pending > 0 && (
                <span className="bg-slate-200/50 px-1.5 py-0.5 rounded-md text-[10px]">
                  {syncState.pending} pending
                </span>
              )}
            </div>

            <button className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-slate-50 transition-colors relative">
              <span className="material-symbols-outlined text-slate-500 text-xl">notifications</span>
              <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-rose-500 rounded-full"></span>
            </button>
            <button className="w-10 h-10 flex items-center justify-center rounded-full hover:bg-slate-50 transition-colors">
              <span className="material-symbols-outlined text-slate-500 text-xl">wb_sunny</span>
            </button>
            
            <div className="h-8 w-[1px] bg-slate-100"></div>
            
            <div className="flex items-center gap-3">
              <div className="text-right">
                <p className="text-xs font-bold text-slate-800 leading-none">Dr. Rajesh</p>
                <p className="text-[10px] font-semibold text-slate-400 mt-1">MO - PHC</p>
              </div>
              <div className="w-10 h-10 rounded-full overflow-hidden bg-emerald-50 flex items-center justify-center ring-2 ring-emerald-500/10">
                <img 
                  className="w-full h-full object-cover" 
                  alt="Dr. Rajesh"
                  src="https://lh3.googleusercontent.com/aida-public/AB6AXuDQQKDnoIW6yrZEUBwkiF_j7aWfb05QJiFhZg_kBkZosEJSEEVut6o3ELTRpUWUlJFufA7LVupVrKEtUtHaVHwMsCVnMdEN2r-YyzRJ0jWo6j2Cg6bOu2gHUi858MMmoTOBSFpc8RPMVlEwhH4_94IemhNSeUA4sW0X9S9bF7vh-rW9gkIg0HqrXnB2pnLRqdjCBAApY8QFyQr21tXqxMQu5gyFt_F9AvWje-nVoYhUCxFNPobRJFJLkg"
                />
              </div>
            </div>
          </div>
        </header>

        {/* Content Canvas */}
        <main className="p-8 overflow-y-auto">
          {currentTab !== 'dashboard' && (
            <div className="flex justify-start mb-6">
              <button 
                onClick={() => setCurrentTab('dashboard')}
                className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 hover:border-slate-300 text-slate-600 hover:text-slate-800 rounded-xl text-xs font-bold shadow-sm transition-all active:scale-95"
              >
                <span className="material-symbols-outlined text-sm font-bold">arrow_back</span>
                {t('back_to_dashboard')}
              </button>
            </div>
          )}

          {currentTab === 'dashboard' && (
            <>
              {familyId ? (
                <div className="space-y-4">
                  <div className="flex justify-start">
                    <button 
                      onClick={() => {
                        setFamilyId('');
                        setActiveMemberId('');
                      }}
                      className="flex items-center gap-2 px-4 py-2.5 bg-white border border-slate-200 hover:border-slate-300 text-slate-600 hover:text-slate-800 rounded-xl text-xs font-bold shadow-sm transition-all active:scale-95"
                    >
                      <span className="material-symbols-outlined text-sm font-bold">arrow_back</span>
                      {t('back_to_main')}
                    </button>
                  </div>
                  <Dashboard familyId={familyId} activeMemberId={activeMemberId} />
                </div>
              ) : (
                <>
                  {/* Welcome Banner Section */}
                  <section className="relative w-full h-[260px] bg-white rounded-3xl overflow-hidden shadow-sm flex items-center border border-slate-100 mb-8">
                    <div className="relative z-10 px-8 w-[60%] space-y-4">
                      <div className="flex items-center gap-1.5 text-xs text-emerald-700 font-bold">
                        <span>{t('welcome_doctor')}</span>
                        <span>👋</span>
                      </div>
                      <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">
                        {t('welcome_title')}
                      </h1>
                      <p className="text-xs text-slate-500 max-w-lg leading-relaxed">
                        {t('welcome_sub')}
                      </p>
                      <button 
                        onClick={() => setCurrentTab('register')}
                        className="flex items-center gap-2 px-5 py-2.5 bg-[#003d29] text-white rounded-xl text-xs font-bold hover:brightness-110 active:scale-95 transition-all shadow-md shadow-emerald-950/20"
                      >
                        <span className="material-symbols-outlined text-sm">person_add</span>
                        {t('reg_patient')}
                      </button>
                    </div>
                    <div className="absolute right-0 top-0 h-full w-[45%] z-0">
                      <img 
                        className="w-full h-full object-cover object-center" 
                        alt="ASHA Consultation" 
                        src="https://lh3.googleusercontent.com/aida-public/AB6AXuBKagPQrRN5-FeXXpGNEfQT-I4XUN2v3HVzM_mR4mWnZOMZBnPDaGAdHWpBSsEf4QzANUt_HBIbcxisANbok6YRvVL0OvXYsa4dzNixGILml6ELAXGT6Bnk4cf9kmRzQUaS8jMFUnn2qmBEV3CwZVcoGZwYKhnwPiHpF53oN87h-pzdn3mBexeNiBOupBVcl7tn0PJO_UQxVBXBHOvDq0c0XUdq09M0H7Dxpr-YHG_9-2h523_tWA6MkA"
                      />
                    </div>
                    {/* Date Badge Overlay */}
                    <div className="absolute top-6 right-6 z-10 bg-white/90 backdrop-blur-md px-4 py-3 rounded-2xl shadow-sm border border-slate-100 flex flex-col items-center min-w-[120px]">
                      <span className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">{t('today_date')}</span>
                      <span className="text-sm font-extrabold text-[#003d29] mt-0.5 font-sans">
                        {new Date().toLocaleDateString(language === 'ta' ? 'ta-IN' : 'en-IN', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </span>
                      <span className="text-[10px] text-slate-500 font-semibold mt-0.5">
                        {new Date().toLocaleDateString(language === 'ta' ? 'ta-IN' : 'en-IN', { weekday: 'long' })}
                      </span>
                    </div>
                  </section>

                  {/* Stats Grid */}
                  <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    {/* Card 1 — Total Patients */}
                    <div className="bg-white p-5 rounded-3xl shadow-sm border border-slate-100 flex flex-col justify-between h-[150px] transition-transform hover:-translate-y-0.5">
                      <div className="flex justify-between items-start">
                        <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>group</span>
                        </div>
                        <div className="text-right">
                          <span className="text-[10px] text-slate-400 font-extrabold uppercase block tracking-wider">{t('registered_patients')}</span>
                          <span className="text-2xl font-extrabold text-slate-800 leading-none">{stats.totalPatients.toLocaleString('en-IN')}</span>
                          <span className="block text-[10px] text-slate-400 font-semibold mt-0.5">{t('total_patients')}</span>
                        </div>
                      </div>
                      <div className="flex justify-between items-center text-[10px] pt-2 border-t border-slate-50">
                        <span className="text-emerald-600 font-bold flex items-center gap-0.5">
                          <span className="material-symbols-outlined text-xs">database</span> {t('live_db')}
                        </span>
                        <svg className="w-16 h-5" preserveAspectRatio="none" viewBox="0 0 100 20">
                          <path d="M0 15 Q 10 5, 20 12 T 40 8 T 60 15 T 80 5 T 100 10" fill="none" stroke="#10b981" strokeWidth="2"></path>
                        </svg>
                      </div>
                    </div>

                    {/* Card 2 — Pregnant Mothers */}
                    <div className="bg-white p-5 rounded-3xl shadow-sm border border-slate-100 flex flex-col justify-between h-[150px] transition-transform hover:-translate-y-0.5">
                      <div className="flex justify-between items-start">
                        <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>pregnant_woman</span>
                        </div>
                        <div className="text-right">
                          <span className="text-[10px] text-slate-400 font-extrabold uppercase block tracking-wider">{t('maternal_cases')}</span>
                          <span className="text-2xl font-extrabold text-slate-800 leading-none">{stats.pregnantMothers.toLocaleString('en-IN')}</span>
                          <span className="block text-[10px] text-slate-400 font-semibold mt-0.5">{t('pregnant_mothers')}</span>
                        </div>
                      </div>
                      <div className="flex justify-between items-center text-[10px] pt-2 border-t border-slate-50">
                        <span className="text-emerald-600 font-bold flex items-center gap-0.5">
                          <span className="material-symbols-outlined text-xs">database</span> {t('live_db')}
                        </span>
                        <svg className="w-16 h-5" preserveAspectRatio="none" viewBox="0 0 100 20">
                          <path d="M0 10 Q 15 18, 30 10 T 60 12 T 100 5" fill="none" stroke="#10b981" strokeWidth="2"></path>
                        </svg>
                      </div>
                    </div>

                    {/* Card 3 — Requires Clinic Check */}
                    <div className="bg-white p-5 rounded-3xl shadow-sm border border-slate-100 flex flex-col justify-between h-[150px] transition-transform hover:-translate-y-0.5">
                      <div className="flex justify-between items-start">
                        <div className="w-10 h-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>warning</span>
                        </div>
                        <div className="text-right">
                          <span className="text-[10px] text-slate-400 font-extrabold uppercase block tracking-wider">{t('high_risk_cases')}</span>
                          <span className="text-2xl font-extrabold text-slate-800 leading-none">{stats.requiresClinicCheck.toLocaleString('en-IN')}</span>
                          <span className="block text-[10px] text-slate-400 font-semibold mt-0.5">{t('requires_clinic')}</span>
                        </div>
                      </div>
                      <div className="flex justify-between items-center text-[10px] pt-2 border-t border-slate-50">
                        <span className="text-rose-600 font-bold flex items-center gap-0.5">
                          <span className="material-symbols-outlined text-xs">database</span> {t('live_db')}
                        </span>
                        <svg className="w-16 h-5" preserveAspectRatio="none" viewBox="0 0 100 20">
                          <path d="M0 18 L 20 15 L 40 16 L 60 12 L 80 14 L 100 10" fill="none" stroke="#f43f5e" strokeWidth="2"></path>
                        </svg>
                      </div>
                    </div>

                    {/* Card 4 — Completed Immunizations */}
                    <div className="bg-white p-5 rounded-3xl shadow-sm border border-slate-100 flex flex-col justify-between h-[150px] transition-transform hover:-translate-y-0.5">
                      <div className="flex justify-between items-start">
                        <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl" style={{ fontVariationSettings: "'FILL' 1" }}>vaccines</span>
                        </div>
                        <div className="text-right">
                          <span className="text-[10px] text-slate-400 font-extrabold uppercase block tracking-wider">{t('vaccinations_done')}</span>
                          <span className="text-2xl font-extrabold text-slate-800 leading-none">{stats.completedVaccinations.toLocaleString('en-IN')}</span>
                          <span className="block text-[10px] text-slate-400 font-semibold mt-0.5">{t('completed_immunizations')}</span>
                        </div>
                      </div>
                      <div className="flex justify-between items-center text-[10px] pt-2 border-t border-slate-50">
                        <span className="text-emerald-600 font-bold flex items-center gap-0.5">
                          <span className="material-symbols-outlined text-xs">database</span> {t('live_db')}
                        </span>
                        <svg className="w-16 h-5" preserveAspectRatio="none" viewBox="0 0 100 20">
                          <path d="M0 15 L 25 10 L 50 15 L 75 5 L 100 2" fill="none" stroke="#10b981" strokeWidth="2"></path>
                        </svg>
                      </div>
                    </div>
                  </section>

                  {/* Middle Section: Maps & Vaccination Coverage */}
                  <section className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
                    {/* Village Map Overview */}
                    <div className="lg:col-span-2 bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden flex flex-col">
                      <div className="p-5 flex justify-between items-center border-b border-slate-50">
                        <div>
                          <h3 className="text-sm font-bold text-slate-800">{t('village_health')}</h3>
                          <p className="text-[10px] text-slate-400 font-semibold mt-0.5">Risk clusters and follow-up map index representation.</p>
                        </div>
                        <div className="flex bg-slate-100 p-1 rounded-xl text-[10px] font-bold">
                          <button 
                            onClick={() => setMapType('m')}
                            className={`px-3 py-1 rounded-lg transition-all ${mapType === 'm' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
                          >
                            Normal
                          </button>
                          <button 
                            onClick={() => setMapType('k')}
                            className={`px-3 py-1 rounded-lg transition-all ${mapType === 'k' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
                          >
                            Satellite
                          </button>
                          <button 
                            onClick={() => setMapType('p')}
                            className={`px-3 py-1 rounded-lg transition-all ${mapType === 'p' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
                          >
                            Terrain
                          </button>
                        </div>
                      </div>
                      <div className="relative flex-1 min-h-[350px] bg-slate-100">
                        <iframe
                          className="w-full h-full border-0"
                          title="Google Maps"
                          src={`https://maps.google.com/maps?q=11.1416,78.5956&t=${mapType}&z=12&ie=UTF8&iwloc=&output=embed`}
                          allowFullScreen
                          loading="lazy"
                        ></iframe>
                        
                        {/* Legend */}
                        <div className="absolute bottom-4 left-4 bg-white/95 backdrop-blur-md p-3.5 rounded-2xl shadow-sm border border-slate-100 flex flex-col gap-2 pointer-events-none">
                          <div className="flex items-center gap-2 text-[10px] font-bold">
                            <span className="w-2 h-2 rounded-full bg-rose-600"></span>
                            <span className="text-slate-600">High Risk</span>
                          </div>
                          <div className="flex items-center gap-2 text-[10px] font-bold">
                            <span className="w-2 h-2 rounded-full bg-amber-500"></span>
                            <span className="text-slate-600">Medium Risk</span>
                          </div>
                          <div className="flex items-center gap-2 text-[10px] font-bold">
                            <span className="w-2 h-2 rounded-full bg-emerald-600"></span>
                            <span className="text-slate-600">Low Risk</span>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Coverage donut card */}
                    <div className="bg-white p-5 rounded-3xl shadow-sm border border-slate-100 flex flex-col justify-between">
                      <h3 className="text-sm font-bold text-slate-800">{t('vaccination_coverage')}</h3>
                      
                      <div className="relative flex items-center justify-center my-6">
                        <div className="relative w-36 h-36">
                          <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
                            <circle cx="50" cy="50" fill="none" r="40" stroke="#f1f5f9" strokeWidth="12"></circle>
                            <circle
                              cx="50" cy="50" fill="none" r="40"
                              stroke="#10b981"
                              strokeDasharray={stats.CIRCUMFERENCE}
                              strokeDashoffset={stats.fullyOffset}
                              strokeLinecap="round"
                              strokeWidth="12"
                            ></circle>
                            <circle
                              cx="50" cy="50" fill="none" r="40"
                              stroke="#f59e0b"
                              strokeDasharray={stats.CIRCUMFERENCE}
                              strokeDashoffset={stats.partialOffset}
                              strokeLinecap="round"
                              strokeWidth="12"
                              className="rotate-[270deg] origin-center"
                            ></circle>
                          </svg>
                          <div className="absolute inset-0 flex flex-col items-center justify-center">
                            <span className="text-2xl font-extrabold text-[#003d29] leading-none">{stats.coveragePct}%</span>
                            <span className="text-[10px] text-slate-400 font-bold mt-1">Coverage</span>
                          </div>
                        </div>
                      </div>

                      <div className="space-y-2 text-[11px] font-semibold">
                        <div className="flex justify-between items-center">
                          <div className="flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                            <span className="text-slate-500">{t('fully_vaccinated')}</span>
                          </div>
                          <span className="text-slate-700">
                            {stats.completedVaccinations.toLocaleString('en-IN')}{' '}
                            <span className="text-slate-400 font-medium">({stats.coveragePct}%)</span>
                          </span>
                        </div>
                        <div className="flex justify-between items-center">
                          <div className="flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-amber-500"></span>
                            <span className="text-slate-500">{t('partially_vaccinated')}</span>
                          </div>
                          <span className="text-slate-700">
                            {stats.partialVaccinations.toLocaleString('en-IN')}{' '}
                            <span className="text-slate-400 font-medium">
                              ({stats.totalVaccinationTarget > 0
                                ? Math.round((stats.partialVaccinations / stats.totalVaccinationTarget) * 100)
                                : 0}%)
                            </span>
                          </span>
                        </div>
                        <div className="flex justify-between items-center">
                          <div className="flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-rose-500"></span>
                            <span className="text-slate-500">{t('due')}</span>
                          </div>
                          <span className="text-slate-700">
                            {stats.dueVaccinations.toLocaleString('en-IN')}{' '}
                            <span className="text-slate-400 font-medium">
                              ({stats.totalVaccinationTarget > 0
                                ? Math.round((stats.dueVaccinations / stats.totalVaccinationTarget) * 100)
                                : 0}%)
                            </span>
                          </span>
                        </div>
                        <div className="flex justify-between items-center">
                          <div className="flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-slate-300"></span>
                            <span className="text-slate-500">{t('overdue')}</span>
                          </div>
                          <span className="text-slate-700">
                            {stats.overdueVaccinations.toLocaleString('en-IN')}{' '}
                            <span className="text-slate-400 font-medium">
                              ({stats.totalVaccinationTarget > 0
                                ? Math.round((stats.overdueVaccinations / stats.totalVaccinationTarget) * 100)
                                : 0}%)
                            </span>
                          </span>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-4 mt-4 pt-4 border-t border-slate-50">
                        <div className="flex items-center gap-2">
                          <div className="w-8 h-8 rounded-lg bg-slate-50 flex items-center justify-center text-slate-500">
                            <span className="material-symbols-outlined text-lg">group</span>
                          </div>
                          <div>
                            <p className="text-[9px] text-slate-400 font-bold leading-tight uppercase">{t('total_target')}</p>
                            <p className="text-xs font-extrabold text-[#003d29]">{stats.totalVaccinationTarget.toLocaleString('en-IN')}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <div className="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600">
                            <span className="material-symbols-outlined text-lg">check_circle</span>
                          </div>
                          <div>
                            <p className="text-[9px] text-slate-400 font-bold leading-tight uppercase">{t('total_achieved')}</p>
                            <p className="text-xs font-extrabold text-[#003d29]">{stats.completedVaccinations.toLocaleString('en-IN')}</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  </section>

                  {/* Quick Actions Row */}
                  <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
                    {/* Action 1 */}
                    <button 
                      onClick={() => setCurrentTab('assistant')}
                      className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 hover:border-emerald-500/30 flex items-center justify-between text-left group transition-all"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl">medical_services</span>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-slate-800">{t('ai_assistant')}</p>
                          <p className="text-[9px] text-slate-400 font-semibold">Scan and detect</p>
                        </div>
                      </div>
                      <span className="material-symbols-outlined text-slate-300 group-hover:text-emerald-600 transition-colors text-lg">chevron_right</span>
                    </button>

                    {/* Action 2 */}
                    <button 
                      onClick={() => setCurrentTab('assistant')}
                      className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 hover:border-emerald-500/30 flex items-center justify-between text-left group transition-all"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl">psychology</span>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-slate-800">{t('ai_assistant')}</p>
                          <p className="text-[9px] text-slate-400 font-semibold">Get AI powered</p>
                        </div>
                      </div>
                      <span className="material-symbols-outlined text-slate-300 group-hover:text-emerald-600 transition-colors text-lg">chevron_right</span>
                    </button>

                    {/* Action 3 */}
                    <button 
                      onClick={() => setCurrentTab('inventory')}
                      className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 hover:border-emerald-500/30 flex items-center justify-between text-left group transition-all"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl">inventory_2</span>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-slate-800">{t('inventory')}</p>
                          <p className="text-[9px] text-slate-400 font-semibold">Check medicine &amp;</p>
                        </div>
                      </div>
                      <span className="material-symbols-outlined text-slate-300 group-hover:text-emerald-600 transition-colors text-lg">chevron_right</span>
                    </button>

                    {/* Action 4 */}
                    <button 
                      onClick={() => setCurrentTab('reports')}
                      className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 hover:border-emerald-500/30 flex items-center justify-between text-left group transition-all"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-orange-50 text-orange-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl">description</span>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-slate-800">{t('reports')}</p>
                          <p className="text-[9px] text-slate-400 font-semibold">View and download</p>
                        </div>
                      </div>
                      <span className="material-symbols-outlined text-slate-300 group-hover:text-emerald-600 transition-colors text-lg">chevron_right</span>
                    </button>

                    {/* Action 5 */}
                    <button 
                      onClick={() => setCurrentTab('history')}
                      className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 hover:border-emerald-500/30 flex items-center justify-between text-left group transition-all"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl">history</span>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-slate-800">{t('visits_history')}</p>
                          <p className="text-[9px] text-slate-400 font-semibold">Track field visit</p>
                        </div>
                      </div>
                      <span className="material-symbols-outlined text-slate-300 group-hover:text-emerald-600 transition-colors text-lg">chevron_right</span>
                    </button>

                    {/* Action 6 */}
                    <button 
                      onClick={() => setCurrentTab('support')}
                      className="bg-white p-4 rounded-2xl shadow-sm border border-slate-100 hover:border-emerald-500/30 flex items-center justify-between text-left group transition-all"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                          <span className="material-symbols-outlined text-xl">support_agent</span>
                        </div>
                        <div>
                          <p className="text-xs font-bold text-slate-800">{t('support')}</p>
                          <p className="text-[9px] text-slate-400 font-semibold">Get help and</p>
                        </div>
                      </div>
                      <span className="material-symbols-outlined text-slate-300 group-hover:text-emerald-600 transition-colors text-lg">chevron_right</span>
                    </button>
                  </section>
                </>
              )}
            </>
          )}

          {currentTab === 'register' && (
            <Registration onRegisterSuccess={handleRegisterSuccess} />
          )}

          {/* Fully Functional Pages */}
          {currentTab === 'patients' && (
            <Patients 
              onRegisterClick={() => setCurrentTab('register')} 
              onSelectPatient={handleSelectPatient}
              searchFilter={headerSearch}
            />
          )}

          {currentTab === 'mothers' && (
            <Mothers onSelectPatient={handleSelectPatient} />
          )}

          {currentTab === 'pregnancies' && (
            <Pregnancies onSendSmsClick={(pId) => {
              setSmsPatientId(pId);
              setSmsTemplate('anc_alert');
              setCurrentTab('sms');
            }} />
          )}

          {currentTab === 'vaccination' && (
            <Vaccination t={t} />
          )}

          {currentTab === 'sms' && (
            <SmsPanel 
              preselectedPatientId={smsPatientId} 
              preselectedTemplate={smsTemplate}
              clearPreselected={() => {
                setSmsPatientId('');
                setSmsTemplate('');
              }}
            />
          )}

          {currentTab === 'inventory' && (
            <Inventory />
          )}

          {currentTab === 'assistant' && (
            <AiHealthAssistant />
          )}

          {currentTab === 'cancer' && (
            <CancerCare />
          )}

          {currentTab === 'reports' && (
            <Reports />
          )}

          {currentTab === 'history' && (
            <VisitsHistory />
          )}

          {currentTab === 'support' && (
            <Support />
          )}

          {currentTab === 'settings' && (
            <Settings currentLang={language} onLanguageChange={handleLanguageChange} t={t} />
          )}
        </main>
      </div>

      {/* Toast Notification Container */}
      <div className="fixed bottom-6 right-6 z-50 flex flex-col gap-2">
        {toasts.map(toast => (
          <div key={toast.id} className={`flex items-center gap-2 px-4 py-3 rounded-2xl shadow-xl border text-xs font-bold transition-all duration-300 transform translate-y-0 ${
            toast.type === 'success' ? 'bg-emerald-50 border-emerald-200 text-emerald-800' :
            toast.type === 'warning' ? 'bg-amber-50 border-amber-200 text-amber-800' :
            'bg-slate-50 border-slate-250 text-slate-800'
          }`}>
            <span className="material-symbols-outlined text-sm">
              {toast.type === 'success' ? 'check_circle' :
               toast.type === 'warning' ? 'warning' : 'info'}
            </span>
            {toast.message}
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;
