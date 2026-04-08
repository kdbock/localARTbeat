"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  DEFAULT_ACK_HOURS,
  DEFAULT_COMPLETION_DAYS,
  getRequestType,
  evaluateSlaBreaches,
} = require("../src/lib/dataRequestSla");

test("getRequestType normalizes request type and fallback field", () => {
  assert.equal(getRequestType({requestType: " Deletion "}), "deletion");
  assert.equal(getRequestType({type: "DOWNLOAD"}), "download");
  assert.equal(getRequestType({}), "");
});

test("evaluateSlaBreaches uses default SLA windows", () => {
  const requestedAt = new Date("2026-01-01T00:00:00.000Z");
  const now = new Date("2026-01-05T00:00:00.000Z");
  const result = evaluateSlaBreaches(
    {status: "pending", requestedAt},
    now,
  );

  assert.equal(result.ackOverdue, true);
  assert.equal(result.completionOverdue, false);
  assert.equal(
    result.ackDueAt.toISOString(),
    new Date(
      requestedAt.getTime() + DEFAULT_ACK_HOURS * 60 * 60 * 1000,
    ).toISOString(),
  );
  assert.equal(
    result.completionDueAt.toISOString(),
    new Date(
      requestedAt.getTime() + DEFAULT_COMPLETION_DAYS * 24 * 60 * 60 * 1000,
    ).toISOString(),
  );
});

test("evaluateSlaBreaches does not flag terminal requests", () => {
  const now = new Date("2026-03-01T00:00:00.000Z");
  const result = evaluateSlaBreaches(
    {
      status: "fulfilled",
      requestedAt: "2026-01-01T00:00:00.000Z",
      fulfilledAt: "2026-01-10T00:00:00.000Z",
    },
    now,
  );

  assert.equal(result.ackOverdue, false);
  assert.equal(result.completionOverdue, false);
});
