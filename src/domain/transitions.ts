// Transition graph only. Actor/ownership/time checks belong in transactional RPCs.
export const bookingTransitions = {
 requested: ['confirmed','cancelled'], confirmed: ['completed','cancelled','no_show','disputed'],
 completed: ['disputed'], cancelled: [], no_show: ['disputed'], disputed: ['completed','cancelled','no_show'],
} as const;
export const exchangeTransitions = {
 pending: ['accepted','rejected','cancelled'], accepted: ['in_progress','cancelled','disputed'],
 rejected: [], cancelled: [], in_progress: ['completed','disputed'], completed: ['disputed'], disputed: ['in_progress','completed','cancelled'],
} as const;
export function canTransition(graph: Record<string, readonly string[]>, from: string, to: string) {
 return Object.hasOwn(graph, from) && graph[from].includes(to);
}
