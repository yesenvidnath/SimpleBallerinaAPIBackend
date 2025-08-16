import ballerina/http;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/log;

// Database configuration
configurable string host = "localhost";
configurable int port = 3306;
configurable string user = "root";
configurable string password = "1234";
configurable string database = "squidgames_DB";

// MySQL client
mysql:Client dbClient = check new (
    host = host,
    port = port,
    user = user,
    password = password,
    database = database
);

// Updated User record type with Email field
type User record {
    int ID?;
    string UserName;
    string Email;        // New email field
    string Passwrod;
};

// Updated Login request type
type LoginRequest record {
    string Email;        // Changed from UserName to Email
    string Passwrod;
};

// Registration request type
type RegisterRequest record {
    string UserName;
    string Email;
    string Passwrod;
};

// Response types
type UserResponse record {
    int id;
    string username;
    string email;        // Added email to response
    string message;
};

type ErrorResponse record {
    string message;
    string 'error;
};

// CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["AUTHORIZATION", "Content-Type"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    }
}
service / on new http:Listener(8080) {

    // Health check endpoint
    resource function get health() returns string {
        return "MySQL Backend is running!";
    }

    // OPTIONS handler for CORS preflight requests
    resource function options .(http:RequestContext ctx, http:Request req) returns http:Response {
        http:Response res = new;
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
        res.setHeader("Access-Control-Max-Age", "3600");
        res.statusCode = 200;
        return res;
    }

    // Get all users
    resource function get users() returns User[]|ErrorResponse {
        sql:ParameterizedQuery query = `SELECT ID, UserName, Email, Passwrod FROM login`;
        stream<User, sql:Error?> resultStream = dbClient->query(query);
        
        User[] users = [];
        error? e = from User user in resultStream
            do {
                users.push(user);
            };
        
        if e is error {
            log:printError("Error retrieving users", e);
            return {
                message: "Failed to retrieve users",
                'error: e.message()
            };
        }
        
        error? closeResult = resultStream.close();
        if closeResult is error {
            log:printError("Error closing result stream", closeResult);
            return {
                message: "Failed to close result stream",
                'error: closeResult.message()
            };
        }
        return users;
    }

    // Get user by ID
    resource function get users/[int id]() returns User|ErrorResponse {
        sql:ParameterizedQuery query = `SELECT ID, UserName, Email, Passwrod FROM login WHERE ID = ${id}`;
        User|sql:Error result = dbClient->queryRow(query);
        
        if result is sql:Error {
            log:printError("Error retrieving user", result);
            return {
                message: "User not found",
                'error: result.message()
            };
        }
        
        return result;
    }

    // Create new user (Registration)
    resource function post users(@http:Payload RegisterRequest newUser) returns UserResponse|ErrorResponse {
        sql:ParameterizedQuery query = `INSERT INTO login (UserName, Email, Passwrod) VALUES (${newUser.UserName}, ${newUser.Email}, ${newUser.Passwrod})`;
        sql:ExecutionResult|sql:Error result = dbClient->execute(query);
        
        if result is sql:Error {
            log:printError("Error creating user", result);
            
            // Handle duplicate email error
            if result.message().includes("Duplicate entry") && result.message().includes("Email") {
                return {
                    message: "Email already exists",
                    'error: "An account with this email already exists"
                };
            }
            
            return {
                message: "Failed to create user",
                'error: result.message()
            };
        }
        
        int|string? lastInsertId = result.lastInsertId;
        if lastInsertId is int {
            return {
                id: lastInsertId,
                username: newUser.UserName,
                email: newUser.Email,
                message: "User created successfully"
            };
        } else {
            return {
                message: "User created but ID not available",
                'error: "Unknown ID"
            };
        }
    }

    // Login endpoint (now uses email instead of username)
    resource function post login(@http:Payload LoginRequest loginReq) returns UserResponse|ErrorResponse {
        sql:ParameterizedQuery query = `SELECT ID, UserName, Email FROM login WHERE Email = ${loginReq.Email} AND Passwrod = ${loginReq.Passwrod}`;
        User|sql:Error result = dbClient->queryRow(query);
        
        if result is sql:Error {
            log:printError("Login failed", result);
            return {
                message: "Invalid email or password",
                'error: "Authentication failed"
            };
        }
        
        return {
            id: result.ID ?: 0,
            username: result.UserName,
            email: result.Email,
            message: "Login successful"
        };
    }

    // Update user
    resource function put users/[int id](@http:Payload RegisterRequest updatedUser) returns UserResponse|ErrorResponse {
        sql:ParameterizedQuery query = `UPDATE login SET UserName = ${updatedUser.UserName}, Email = ${updatedUser.Email}, Passwrod = ${updatedUser.Passwrod} WHERE ID = ${id}`;
        sql:ExecutionResult|sql:Error result = dbClient->execute(query);
        
        if result is sql:Error {
            log:printError("Error updating user", result);
            
            // Handle duplicate email error
            if result.message().includes("Duplicate entry") && result.message().includes("Email") {
                return {
                    message: "Email already exists",
                    'error: "Another user already has this email"
                };
            }
            
            return {
                message: "Failed to update user",
                'error: result.message()
            };
        }
        
        int? affectedRowCount = result.affectedRowCount;
        if affectedRowCount == 0 {
            return {
                message: "User not found",
                'error: "No user with specified ID"
            };
        }
        
        return {
            id: id,
            username: updatedUser.UserName,
            email: updatedUser.Email,
            message: "User updated successfully"
        };
    }

    // Delete user
    resource function delete users/[int id]() returns UserResponse|ErrorResponse {
        // First get the user to return their info
        sql:ParameterizedQuery selectQuery = `SELECT UserName, Email FROM login WHERE ID = ${id}`;
        record {string UserName; string Email;}|sql:Error userInfo = dbClient->queryRow(selectQuery);
        
        if userInfo is sql:Error {
            return {
                message: "User not found",
                'error: "No user with specified ID"
            };
        }
        
        sql:ParameterizedQuery deleteQuery = `DELETE FROM login WHERE ID = ${id}`;
        sql:ExecutionResult|sql:Error result = dbClient->execute(deleteQuery);
        
        if result is sql:Error {
            log:printError("Error deleting user", result);
            return {
                message: "Failed to delete user",
                'error: result.message()
            };
        }
        
        return {
            id: id,
            username: userInfo.UserName,
            email: userInfo.Email,
            message: "User deleted successfully"
        };
    }
}

// Initialize database connection on startup
public function main() returns error? {
    log:printInfo("Starting MySQL Backend Server...");
    log:printInfo("Server is running on http://localhost:8080");
    log:printInfo("Health check: http://localhost:8080/health");
}