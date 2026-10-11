'use strict';

function hashSeed(text) {
  let h = 2166136261 >>> 0;
  for (let i = 0; i < text.length; i += 1) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 16777619) >>> 0;
  }
  return h >>> 0;
}

function mulberry32(seed) {
  let a = seed | 0;
  return function next() {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function createRng(seed) {
  const numeric = typeof seed === 'string' ? hashSeed(seed) : seed >>> 0;
  const next = mulberry32(numeric);
  const rng = {
    seed: numeric,
    next,
    float(min, max) {
      return min + next() * (max - min);
    },
    int(min, max) {
      return min + Math.floor(next() * (max - min + 1));
    },
    chance(p) {
      return next() < p;
    },
    pick(list) {
      return list[Math.floor(next() * list.length)];
    },
    normal(mean = 0, sd = 1) {
      let u = 0;
      while (u === 0) u = next();
      const v = next();
      return mean + sd * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
    },
    lognormal(median, sigma) {
      return median * Math.exp(sigma * rng.normal());
    },
    poisson(lambda) {
      if (!(lambda > 0)) return 0;
      if (lambda > 30) return Math.max(0, Math.round(rng.normal(lambda, Math.sqrt(lambda))));
      const limit = Math.exp(-lambda);
      let k = 0;
      let p = 1;
      do {
        k += 1;
        p *= next();
      } while (p > limit);
      return k - 1;
    },
    binomial(n, p) {
      let k = 0;
      for (let i = 0; i < n; i += 1) if (next() < p) k += 1;
      return k;
    },
    token(length, alphabet) {
      let out = '';
      for (let i = 0; i < length; i += 1) out += alphabet[Math.floor(next() * alphabet.length)];
      return out;
    },
    fork(label) {
      return createRng(`${numeric}:${label}`);
    },
  };
  return rng;
}

module.exports = { createRng, hashSeed, mulberry32 };
