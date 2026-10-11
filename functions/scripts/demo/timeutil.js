'use strict';

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const SP_OFFSET_MS = -3 * HOUR;

function spStartOfDay(ms) {
  const local = ms + SP_OFFSET_MS;
  const day = local - (((local % DAY) + DAY) % DAY);
  return day - SP_OFFSET_MS;
}

function spDow(dayStartMs) {
  const days = Math.floor((dayStartMs + SP_OFFSET_MS) / DAY);
  return (((4 + days) % 7) + 7) % 7;
}

function spDayKey(ms) {
  return new Date(ms + SP_OFFSET_MS).toISOString().slice(0, 10);
}

function spMonthDay(ms) {
  return spDayKey(ms).slice(5);
}

module.exports = { MINUTE, HOUR, DAY, SP_OFFSET_MS, spStartOfDay, spDow, spDayKey, spMonthDay };
