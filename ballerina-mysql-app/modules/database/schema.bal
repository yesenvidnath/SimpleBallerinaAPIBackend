import ballerinax/mysql;
import ballerinax/mysql.driver as _;

// Define the MySQL database connection configuration
configurable string dbHost = "localhost";
configurable string dbUser = "root";
configurable int dbPort = 3306;
configurable string dbPassword = "1234";
configurable string dbName = "squidgames_DB";

// Initialize the MySQL client
public final mysql:Client dbClient = check new(
    host = dbHost,
    user = dbUser,
    password = dbPassword,
    port = dbPort,
    database = dbName
);

// Define the database schema
public function createSchema() returns error? {
    // Create a table for login if it doesn't exist
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS login (
            ID INT PRIMARY KEY AUTO_INCREMENT,
            UserName VARCHAR(255),
            Passwrod VARCHAR(255)
        )
    `);
}
