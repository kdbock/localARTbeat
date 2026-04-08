const test = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeUserType,
  isAdminByUserType,
  isModeratorByUserType,
} = require("../src/lib/adminRoleContract");

test("normalizeUserType lowercases and trims", () => {
  assert.equal(normalizeUserType("  Admin "), "admin");
});

test("isAdminByUserType allows canonical admin field", () => {
  assert.equal(isAdminByUserType({userType: "admin"}), true);
});

test("isAdminByUserType denies legacy role-only admin", () => {
  assert.equal(isAdminByUserType({role: "admin"}), false);
});

test("isAdminByUserType denies non-admin userType", () => {
  assert.equal(isAdminByUserType({userType: "artist"}), false);
});

test("isModeratorByUserType allows moderator", () => {
  assert.equal(isModeratorByUserType({userType: "moderator"}), true);
});

test("isModeratorByUserType allows admin", () => {
  assert.equal(isModeratorByUserType({userType: "admin"}), true);
});

test("isModeratorByUserType denies role-only moderator", () => {
  assert.equal(isModeratorByUserType({role: "moderator"}), false);
});
