const puppeteer = require('puppeteer-core');
const fs = require('fs');

(async () => {
  const edgePaths = [
    'C:\\\\Program Files (x86)\\\\Microsoft\\\\Edge\\\\Application\\\\msedge.exe',
    'C:\\\\Program Files\\\\Microsoft\\\\Edge\\\\Application\\\\msedge.exe'
  ];
  
  let executablePath = null;
  for (const p of edgePaths) {
    if (fs.existsSync(p)) {
      executablePath = p;
      break;
    }
  }
  
  if (!executablePath) {
    console.log("Could not find Edge browser.");
    return;
  }

  const browser = await puppeteer.launch({
    executablePath: executablePath,
    headless: "new"
  });
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', error => console.log('PAGE ERROR:', error.message));
  page.on('response', response => {
    if (!response.ok()) {
      console.log('FAILED REQUEST:', response.url(), response.status());
    }
  });
  
  console.log("Navigating to http://localhost:8081...");
  await page.goto('http://localhost:8081');
  
  console.log("Waiting 3 seconds for page load...");
  await new Promise(r => setTimeout(r, 3000));
  
  // Capture a screenshot to see what it actually looks like!
  await page.screenshot({ path: 'C:\\\\Users\\\\Padamanaban\\\\.gemini\\\\antigravity-ide\\\\brain\\\\569279a7-8a8d-4c7c-8d63-8e97aee6170f\\\\debug_screenshot.png' });
  console.log("Saved debug_screenshot.png to artifacts");
  
  await browser.close();
})();
