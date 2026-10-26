export const matchWeights = { skill: .4, reciprocal: .25, availability: .15, language: .1, experience: .1 } as const;
export type MatchComponents = Record<keyof typeof matchWeights, number>;
export function scoreMatch(components: MatchComponents, weights: MatchComponents = matchWeights) {
 if (Object.values(weights).some(v => !Number.isFinite(v) || v < 0) || Math.abs(Object.values(weights).reduce((a,b)=>a+b,0)-1)>1e-9) throw new Error('Weights must sum to one');
 const reasons: string[] = [];
 let score = 0;
 for (const key of Object.keys(matchWeights) as (keyof MatchComponents)[]) {
  const value = components[key];
  if (!Number.isFinite(value) || value < 0 || value > 1) throw new Error('Components must be between zero and one');
  score += value * weights[key];
  if (value > 0) reasons.push(`${key}: ${Math.round(value * 100)}% compatibility`);
 }
 return { score: Math.round(score * 100), reasons };
}
