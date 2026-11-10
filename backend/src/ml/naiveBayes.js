// Clasificador Naive Bayes multinomial (con suavizado de Laplace) para categorizar descripciones de gasto.
const { mulberry32, shuffle } = require('../utils/math');

const STOP = new Set(['de','la','el','los','las','un','una','unos','unas','para','por','con','en','del','al','y','o','a','mi','mis','que','se','su','sus','lo','es','no','me','te']);

function tokenize(text) {
  return String(text).toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/).filter((w) => w.length > 1 && !STOP.has(w));
}

class NaiveBayes {
  constructor() { this.classDocs = {}; this.wordCounts = {}; this.classWords = {}; this.vocab = {}; this.totalDocs = 0; }

  train(samples) {
    for (const { text, label } of samples) {
      this.classDocs[label] = (this.classDocs[label] || 0) + 1;
      this.totalDocs++;
      this.wordCounts[label] = this.wordCounts[label] || {};
      for (const w of tokenize(text)) {
        this.wordCounts[label][w] = (this.wordCounts[label][w] || 0) + 1;
        this.classWords[label] = (this.classWords[label] || 0) + 1;
        this.vocab[w] = 1;
      }
    }
    return this;
  }

  // Devuelve las categorías ordenadas por probabilidad
  predict(text) {
    const words = tokenize(text).filter((w) => this.vocab[w]); // palabras nunca vistas se ignoran
    const V = Object.keys(this.vocab).length || 1;
    const labels = Object.keys(this.classDocs);
    const logs = labels.map((c) => {
      let lp = Math.log(this.classDocs[c] / this.totalDocs);
      for (const w of words) {
        const cnt = (this.wordCounts[c] && this.wordCounts[c][w]) || 0;
        lp += Math.log((cnt + 1) / ((this.classWords[c] || 0) + V));
      }
      return lp;
    });
    const max = Math.max(...logs);
    const exps = logs.map((l) => Math.exp(l - max));
    const sum = exps.reduce((a, b) => a + b, 0);
    return labels.map((c, i) => ({ category: c, confidence: exps[i] / sum }))
      .sort((a, b) => b.confidence - a.confidence);
  }

  toJSON() { return { classDocs: this.classDocs, wordCounts: this.wordCounts, classWords: this.classWords, vocab: this.vocab, totalDocs: this.totalDocs }; }
  static fromJSON(o) { return Object.assign(new NaiveBayes(), o); }
}

// Entrena con 80 % y evalúa con 20 % (hold-out); luego reentrena con todo.
function trainClassifier(samples, seed = 7) {
  const clean = samples.filter((s) => s.text && s.text.trim().length >= 2);
  const labels = new Set(clean.map((s) => s.label));
  if (clean.length < 30 || labels.size < 2) throw new Error('Datos insuficientes para entrenar el clasificador (mínimo 30 gastos con descripción).');
  const data = shuffle([...clean], mulberry32(seed));
  const cut = Math.floor(data.length * 0.8);
  const trainSet = data.slice(0, cut), testSet = data.slice(cut);
  const nb = new NaiveBayes().train(trainSet);
  const hits = testSet.filter((s) => nb.predict(s.text)[0].category === s.label).length;
  const accuracy = testSet.length ? hits / testSet.length : 0;
  const final = new NaiveBayes().train(clean);
  return { model: final.toJSON(), metrics: { accuracy, nTrain: trainSet.length, nTest: testSet.length, classes: labels.size, method: 'Naive Bayes multinomial, hold-out 80/20' } };
}

module.exports = { NaiveBayes, trainClassifier, tokenize };
