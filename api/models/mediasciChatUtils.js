/**
 * Utilities for message and conversation handling
 */

/**
 * Maximum retention period for any chat in hours (3 hours)
 * This acts as a hard limit regardless of temporary chat settings
 */
const MAX_CHAT_RETENTION_HOURS = 3; // 3 hours

/**
 * Maximum expiration date for any chat (3 hours from now)
 */
const MAX_CHAT_EXPIRATION = (() => {
  const date = new Date();
  date.setHours(date.getHours() + MAX_CHAT_RETENTION_HOURS);
  return date;
})();

/**
 * Enforces maximum retention period on expiredAt field
 * @param {Date|null} expiredAt - The current expiration date
 * @returns {Date} The enforced expiration date (capped at maximum)
 */
const enforceMaxRetention = (expiredAt) => {
  if (!expiredAt) {
    return MAX_CHAT_EXPIRATION;
  } else if (expiredAt > MAX_CHAT_EXPIRATION) {
    return MAX_CHAT_EXPIRATION;
  }
  return expiredAt;
};

module.exports = {
  MAX_CHAT_RETENTION_HOURS,
  MAX_CHAT_EXPIRATION,
  enforceMaxRetention,
};
