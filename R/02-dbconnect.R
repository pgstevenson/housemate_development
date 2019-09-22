library(odbc)

# VirtualBox Dev Server
con <- dbConnect(odbc::odbc(),
                 .connection_string = "Driver={PostgreSQL Unicode(x64)};
                 Server=192.168.0.17;\n
                 Database=postgres;\n
                 UID=postgres;\n
                 PWD=14KfFfJ@IHp1;\n
                 Port=5432;")

con <- dbConnect(odbc::odbc(),
                 .connection_string = "Driver={PostgreSQL Unicode(x64)};
                 Server=localhost;\n
                 Database=postgres;\n
                 UID=postgres;\n
                 PWD=14KfFfJ@IHp1;\n
                 Port=5432;")

# AWS production server
con <- dbConnect(odbc::odbc(),
                 .connection_string = "Driver={PostgreSQL Unicode(x64)};
                 Server=ec2-13-54-159-243.ap-southeast-2.compute.amazonaws.com;\n
                 Database=postgres;\n
                 UID=postgres;\n
                 PWD=14KfFfJ@IHp1;\n
                 Port=5432;")
