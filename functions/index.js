const { initializeApp } = require('firebase-admin/app');

initializeApp();

exports.joinQueue = require('./src/handlers/join').joinQueue;
exports.addManualEntry = require('./src/handlers/manual').addManualEntry;
exports.submitFeedback = require('./src/handlers/feedback').submitFeedback;
exports.resolveSlug = require('./src/handlers/slug').resolveSlug;

const deleteHandlers = require('./src/handlers/delete');
exports.deleteQueue = deleteHandlers.deleteQueue;
exports.deleteAccount = deleteHandlers.deleteAccount;

const dsrHandlers = require('./src/handlers/dsr');
exports.findCustomerData = dsrHandlers.findCustomerData;
exports.exportCustomerData = dsrHandlers.exportCustomerData;
exports.eraseCustomerData = dsrHandlers.eraseCustomerData;

const entriesHandlers = require('./src/handlers/entries');
exports.syncPublicTicket = entriesHandlers.syncPublicTicket;
exports.reconcileWaitingCounts = entriesHandlers.reconcileWaitingCounts;

exports.updateServiceEstimate = require('./src/handlers/estimate').updateServiceEstimate;
exports.applyQueueSchedules = require('./src/handlers/schedule').applyQueueSchedules;
exports.expireStaleEntries = require('./src/handlers/expire').expireStaleEntries;
exports.purgeOldHistory = require('./src/handlers/history').purgeOldHistory;
exports.onQueueOpened = require('./src/handlers/openwatch').onQueueOpened;
exports.evaluateQueueAlerts = require('./src/handlers/alerts').evaluateQueueAlerts;
