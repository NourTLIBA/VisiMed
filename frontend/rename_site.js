const { execSync } = require('child_process');

const data = JSON.stringify({
  site_id: "c230fbbe-0fda-4f5d-87d4-a38f69ce1bc7",
  body: { name: "kitsunec" }
});

try {
  // Pass data as a single argument using single quotes to wrap the JSON, escaping single quotes if any existed.
  execSync(`npx netlify api updateSite --data '${data}'`, { stdio: 'inherit' });
} catch (e) {
  console.error("Failed");
}
