const pad = (n) => String(n).padStart(2, '0');

function todayStr(d = new Date()) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}
function currentYm(d = new Date()) { return todayStr(d).slice(0, 7); }
function ymIndex(ym) { const [y, m] = ym.split('-').map(Number); return y * 12 + (m - 1); }
function ymFromIndex(i) { return `${Math.floor(i / 12)}-${pad((i % 12) + 1)}`; }
function daysInMonth(ym) { const [y, m] = ym.split('-').map(Number); return new Date(y, m, 0).getDate(); }
function isValidDateStr(s) {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const [y, m, d] = s.split('-').map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.getUTCFullYear() === y && dt.getUTCMonth() === m - 1 && dt.getUTCDate() === d;
}
function tomorrowStr() { const d = new Date(); d.setDate(d.getDate() + 1); return todayStr(d); }

module.exports = { todayStr, currentYm, ymIndex, ymFromIndex, daysInMonth, isValidDateStr, tomorrowStr };
