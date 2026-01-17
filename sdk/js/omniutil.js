export function processTransaction(partnerId, userId, amountUsd, rewardRate) {
  const merit = amountUsd * rewardRate;

  return {
    tx_id: crypto.randomUUID(),
    partner_id: partnerId,
    user_id: userId,
    amount_usd: amountUsd,
    merit_generated: merit,
    timestamp: new Date().toISOString()
  };
}
