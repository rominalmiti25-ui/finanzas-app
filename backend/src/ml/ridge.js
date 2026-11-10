// Regresión lineal múltiple con regularización L2 (Ridge), resuelta con ecuaciones normales.
const { mean, std } = require('../utils/math');

function solve(A, b) {
  const n = b.length;
  const M = A.map((row, i) => [...row, b[i]]);
  for (let c = 0; c < n; c++) {
    let p = c;
    for (let r = c + 1; r < n; r++) if (Math.abs(M[r][c]) > Math.abs(M[p][c])) p = r;
    [M[c], M[p]] = [M[p], M[c]];
    if (Math.abs(M[c][c]) < 1e-12) throw new Error('Matriz singular');
    for (let r = c + 1; r < n; r++) {
      const f = M[r][c] / M[c][c];
      for (let k = c; k <= n; k++) M[r][k] -= f * M[c][k];
    }
  }
  const x = new Array(n).fill(0);
  for (let i = n - 1; i >= 0; i--) {
    let s = M[i][n];
    for (let j = i + 1; j < n; j++) s -= M[i][j] * x[j];
    x[i] = s / M[i][i];
  }
  return x;
}

class Ridge {
  constructor(lambda = 1) { this.lambda = lambda; }

  fit(X, y) {
    const n = X.length, d = X[0].length;
    this.means = []; this.stds = [];
    for (let j = 0; j < d; j++) {
      const col = X.map((r) => r[j]);
      this.means.push(mean(col));
      this.stds.push(std(col) || 1);
    }
    this.yMean = mean(y);
    const Z = X.map((r) => r.map((v, j) => (v - this.means[j]) / this.stds[j]));
    const yc = y.map((v) => v - this.yMean);
    const A = Array.from({ length: d }, () => new Array(d).fill(0));
    const b = new Array(d).fill(0);
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < d; j++) {
        b[j] += Z[i][j] * yc[i];
        for (let k = 0; k < d; k++) A[j][k] += Z[i][j] * Z[i][k];
      }
    }
    for (let j = 0; j < d; j++) A[j][j] += this.lambda;
    this.w = solve(A, b);
    return this;
  }

  predict(x) {
    let s = this.yMean;
    for (let j = 0; j < this.w.length; j++) s += this.w[j] * ((x[j] - this.means[j]) / this.stds[j]);
    return s;
  }

  toJSON() { return { lambda: this.lambda, means: this.means, stds: this.stds, yMean: this.yMean, w: this.w }; }
  static fromJSON(o) { return Object.assign(new Ridge(o.lambda), o); }
}

module.exports = { Ridge };
