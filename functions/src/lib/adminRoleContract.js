function normalizeUserType(value) {
  return String(value || "").trim().toLowerCase();
}

function isAdminByUserType(userData) {
  const userType = normalizeUserType(userData?.userType);
  return userType === "admin";
}

function isModeratorByUserType(userData) {
  const userType = normalizeUserType(userData?.userType);
  return userType === "moderator" || userType === "admin";
}

module.exports = {
  normalizeUserType,
  isAdminByUserType,
  isModeratorByUserType,
};
