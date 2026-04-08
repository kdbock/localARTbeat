"use strict";

const DEFAULT_ACK_HOURS = 72;
const DEFAULT_COMPLETION_DAYS = 30;

function asDate(value) {
  if (!value) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (typeof value.toDate === "function") {
    const converted = value.toDate();
    return converted instanceof Date && !Number.isNaN(converted.getTime()) ? converted : null;
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function addHours(baseDate, hours) {
  return new Date(baseDate.getTime() + hours * 60 * 60 * 1000);
}

function addDays(baseDate, days) {
  return new Date(baseDate.getTime() + days * 24 * 60 * 60 * 1000);
}

function getRequestType(data = {}) {
  return String(data.requestType || data.type || "").trim().toLowerCase();
}

function getStatus(data = {}) {
  return String(data.status || "").trim().toLowerCase();
}

function computeDueDates(data = {}, now = new Date()) {
  const requestedAt = asDate(data.requestedAt) || now;
  const ackHours = Number(data.slaAcknowledgementHours) || DEFAULT_ACK_HOURS;
  const completionDays = Number(data.slaCompletionDays) || DEFAULT_COMPLETION_DAYS;
  const ackDueAt = asDate(data.slaAcknowledgementDueAt) || addHours(requestedAt, ackHours);
  const completionDueAt = asDate(data.slaCompletionDueAt) || addDays(requestedAt, completionDays);
  return {requestedAt, ackDueAt, completionDueAt};
}

function evaluateSlaBreaches(data = {}, now = new Date()) {
  const status = getStatus(data);
  const {ackDueAt, completionDueAt} = computeDueDates(data, now);
  const acknowledgedAt = asDate(data.acknowledgedAt);
  const fulfilledAt = asDate(data.fulfilledAt);
  const deniedAt = asDate(data.deniedAt);
  const terminal = status === "fulfilled" || status === "denied" || !!fulfilledAt || !!deniedAt;

  const ackOverdue = !terminal && !acknowledgedAt && now > ackDueAt;
  const completionOverdue = !terminal && now > completionDueAt;

  return {
    status,
    ackOverdue,
    completionOverdue,
    ackDueAt,
    completionDueAt,
  };
}

module.exports = {
  DEFAULT_ACK_HOURS,
  DEFAULT_COMPLETION_DAYS,
  getRequestType,
  getStatus,
  computeDueDates,
  evaluateSlaBreaches,
};
