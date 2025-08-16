# MySQL Backend with Ballerina

A simple REST API backend built with Ballerina that connects to a MySQL database.

## Prerequisites

1. **Install Ballerina**: Download from https://ballerina.io/downloads/
2. **MySQL Server**: Ensure MySQL is running
3. **MySQL Workbench**: For database management

## Setup Instructions

### 1. Database Setup
- Open MySQL Workbench
- Run the SQL script from `scripts/setup.sql`
- Verify the `squidgames_DB` database and `login` table are created

### 2. Configuration
- Open `Config.toml`
- Update MySQL credentials:
  ```toml
  password = "your_actual_mysql_password"
  user = "your_mysql_username"  # if not root