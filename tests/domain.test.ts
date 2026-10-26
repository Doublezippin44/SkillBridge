import { describe, it, expect } from 'vitest';
import { scoreMatch } from '../src/domain/matching';
import { availableCredits, sessionCredits } from '../src/domain/credits';
import { bookingTransitions, exchangeTransitions, canTransition } from '../src/domain/transitions';
describe('match scoring',()=>{
 it('scores reciprocal compatible matches at 100',()=>expect(scoreMatch({skill:1,reciprocal:1,availability:1,language:1,experience:1}).score).toBe(100));
 it('supports one-way matches without inventing reciprocity',()=>expect(scoreMatch({skill:1,reciprocal:0,availability:1,language:1,experience:1}).score).toBe(75));
 it('rejects invalid components',()=>expect(()=>scoreMatch({skill:NaN,reciprocal:0,availability:0,language:0,experience:0})).toThrow());
 it('rejects invalid weights',()=>expect(()=>scoreMatch({skill:1,reciprocal:1,availability:1,language:1,experience:1},{skill:1,reciprocal:1,availability:1,language:1,experience:1})).toThrow());
});
describe('credit arithmetic',()=>{
 it('charges four credits for one hour',()=>expect(sessionCredits(60)).toBe(4));
 it('excludes reserved funds',()=>expect(availableCredits(10,4)).toBe(6));
 it('rejects negative or oversubscribed wallets',()=>expect(()=>availableCredits(3,4)).toThrow());
 it('rejects fractional duration units',()=>expect(()=>sessionCredits(31)).toThrow());
});
describe('workflow transition graph',()=>{
 it('accepts a pending exchange',()=>expect(canTransition(exchangeTransitions,'pending','accepted')).toBe(true));
 it('cannot jump pending to completed',()=>expect(canTransition(exchangeTransitions,'pending','completed')).toBe(false));
 it('cannot revive cancelled bookings',()=>expect(canTransition(bookingTransitions,'cancelled','confirmed')).toBe(false));
 it('can raise a completion dispute',()=>expect(canTransition(bookingTransitions,'completed','disputed')).toBe(true));
 it('rejects prototype keys',()=>expect(canTransition(bookingTransitions,'toString','confirmed')).toBe(false));
});
