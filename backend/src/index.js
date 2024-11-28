const sequelize = require('./config/db');

sequelize.authenticate()
    .then(() => console.log('Database connected!'))
    .catch(err => console.error('Database connection failed:', err));

// Sync models
sequelize.sync()
    .then(() => console.log('Models synced!'))
    .catch(err => console.error('Model syncing failed:', err));
