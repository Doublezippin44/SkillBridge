// 1 credit = 15 minutes. Non-redeemable; no cash value. All arithmetic is integer-only.
export function sessionCredits(minutes: number) {
 if (!Number.isSafeInteger(minutes) || minutes <= 0 || minutes % 15 !== 0) throw new Error('Duration must be a positive multiple of 15 minutes');
 return minutes / 15;
}
export function availableCredits(balance: number, reserved: number) {
 if (![balance, reserved].every(Number.isSafeInteger) || balance < 0 || reserved < 0 || reserved > balance) throw new Error('Invalid wallet');
 return balance - reserved;
}
