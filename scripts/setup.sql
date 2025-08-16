-- Database setup script
CREATE DATABASE IF NOT EXISTS squidgames_DB;
USE squidgames_DB;

-- Create login table (with typo fix option)
CREATE TABLE IF NOT EXISTS login (
    ID INT PRIMARY KEY AUTO_INCREMENT, 
    UserName VARCHAR(255),
    Email VARCHAR(255),
    Passwrod VARCHAR(255)
);

-- Optional: Fix the typo in column name (uncomment if you want to fix it)
-- ALTER TABLE login CHANGE Passwrod Password VARCHAR(255);

-- Insert some sample data for testing
INSERT INTO login (UserName, Passwrod) VALUES 
('admin', 'admin@squidgame.com', 'admin123'),
('testuser', 'test@squidgame.com', 'password123'),
('john_doe', 'john@squidgame.com', 'secret456');

-- Show the table structure
DESCRIBE login;

-- Show sample data
SELECT * FROM login;