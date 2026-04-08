const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const storageRulesPath = path.resolve(__dirname, "../../storage.rules");

test("storage rules use request.resource.contentType for write-time MIME checks", () => {
  const rules = fs.readFileSync(storageRulesPath, "utf8");
  const invalidWriteChecks = [
    "allow write: if isAuthorized() && request.auth.uid == userId &&\n        // Validate video file types\n        (resource.contentType",
    "allow write: if isAuthorized() && request.auth.uid == userId &&\n        // Validate audio file types\n        (resource.contentType",
    "allow write: if isAuthorized() && request.auth.uid == userId &&\n        // Validate file types for written content\n        (resource.contentType",
  ];

  for (const invalidSnippet of invalidWriteChecks) {
    assert.equal(
      rules.includes(invalidSnippet),
      false,
      "Found legacy resource.contentType check in a write-time MIME validator"
    );
  }

  assert.equal(
    rules.includes("request.resource.contentType"),
    true,
    "Missing request.resource.contentType checks in storage.rules"
  );
});
