library(dplyr)
library(stringr)
library(tidyr)
library(odbc)
library(DBI)
library(readxl)

setwd("C:/Users/pstevenson/Documents/GitHub/housemate")

# Read in data
df <- read_xlsx("data-raw/20190310_expenses_clean.xlsx",
          sheet = "Expenses",
          range = cell_cols("A:I")) %>%
  tbl_df()

# convert to factors
df$who <- df$who %>% factor()
df$category <- df$category %>% factor()
df$store <- df$store %>% factor()
df$id <- df$id %>% as.integer()
df$gid <- df$gid %>% as.integer()
df$deleted <- df$deleted %>% as.logical()
df$notes <- df$notes %>% as.character()

# convert date to posgres format
df$date <- df$date %>% as.character()
df$date <- gsub("-", "", df$date) %>% as.integer()

# person df
person <- tibble(id = as.integer(1:2), first = c("Jess", "Paul"), last = c("Pandohee", "Stevenson"), email = c("jessica.pandohee@gmail.com", "pstevenson6@gmail.com"), deleted = F)
df$who <- df$who %>% as.integer()

# groups
exp_group <- tibble(id = as.integer(1:2), name = c("Love nest", "test group"), owner = as.integer(2), deleted = F)

# group df
user_group <- tibble(id = c(1, 2, 3) %>% as.integer(), uid = c(1, 2, 2) %>% as.integer(), gid = c(1, 1, 2) %>% as.integer())

# store df
store <- tibble(id = df$store %>% unique() %>% labels() %>% as.integer(),
                    name = df$store %>% unique() %>% levels(),
                    deleted = F)
store <- store[store$id != 25, ]
store$name <- gsub("(,,)", ",NULL,", store$name)
store$name <- gsub(",$", ",NULL", store$name)
store <- separate(store, name, into = c("name", "entity", "city"), sep = ",")
df$store <- df$store %>% as.integer()

store[store$name == "NULL", ]$name <- NA
store[store$entity == "NULL", ]$entity <- NA
store[store$city == "NULL", ]$city <- NA

# category df
cat <- tibble(id = df$category %>% unique %>% labels() %>% as.integer(),
           name = df$category %>% unique %>% levels(),
           parent = "NULL")
cat[grepl("^Bills.*", cat$name), "parent"] <- "Bills"
cat$name <- sub("Bills\\\\", "", cat$name)
df$category <- df$category %>% as.integer()
cat <- bind_rows(cat, tibble(id = 11, name = "Bills", parent = "NULL"))

cat[cat$parent == "NULL", ]$parent <- NA

# init db tables
if (dbExistsTable(con, "expenses")) dbRemoveTable(con, "expenses")
dbCreateTable(con, "expenses", df)
dbWriteTable(con, "expenses", df, overwrite = T)
dbGetQuery(con, "ALTER TABLE expenses ADD PRIMARY KEY (id)")
dbGetQuery(con, paste0("CREATE SEQUENCE expenses_id_seq MINVALUE ", as.character(max(df$id) + 1)))
dbGetQuery(con, "ALTER TABLE expenses ALTER id SET DEFAULT nextval('expenses_id_seq')")
dbGetQuery(con, "ALTER SEQUENCE expenses_id_seq OWNED BY expenses.id")
dbGetQuery(con, "ALTER TABLE expenses ADD COLUMN mod_user INTEGER,
           ADD COLUMN root_id INTEGER,
           ADD COLUMN mod_timestamp TIMESTAMP")
dbGetQuery(con, "ALTER TABLE ONLY expenses ALTER COLUMN category SET DEFAULT NULL,
           ALTER COLUMN store SET DEFAULT NULL,
           ALTER COLUMN notes SET DEFAULT NULL,
           ALTER COLUMN root_id SET DEFAULT NULL,
           ALTER COLUMN mod_user SET DEFAULT NULL,
           ALTER COLUMN mod_timestamp SET DEFAULT NOW()");
dbGetQuery(con, "ALTER TABLE ONLY expenses ALTER COLUMN deleted SET DEFAULT 'f'");

if (dbExistsTable(con, "categories")) dbRemoveTable(con, "categories")
dbCreateTable(con, "categories", cat)
dbWriteTable(con, "categories", cat, overwrite = T)
dbGetQuery(con, "ALTER TABLE categories ADD PRIMARY KEY (id)")
dbGetQuery(con, paste0("CREATE SEQUENCE categories_id_seq MINVALUE ", as.character(max(cat$id) + 1)))
dbGetQuery(con, "ALTER TABLE categories ALTER id SET DEFAULT nextval('categories_id_seq')")
dbGetQuery(con, "ALTER SEQUENCE categories_id_seq OWNED BY categories.id")

if (dbExistsTable(con, "person")) dbRemoveTable(con, "person")
dbGetQuery(con, "DROP SEQUENCE IF EXISTS person_id_seq")
dbCreateTable(con, "person", person)
dbWriteTable(con, "person", person, overwrite = T)
dbGetQuery(con, "ALTER TABLE person ADD PRIMARY KEY (id)")
dbGetQuery(con, paste0("CREATE SEQUENCE person_id_seq MINVALUE ", as.character(max(person$id) + 1)))
dbGetQuery(con, "ALTER TABLE person ALTER id SET DEFAULT nextval('person_id_seq')")
dbGetQuery(con, "ALTER SEQUENCE person_id_seq OWNED BY person.id")

if (dbExistsTable(con, "user_group")) dbRemoveTable(con, "user_group")
dbGetQuery(con, "DROP SEQUENCE IF EXISTS user_group_id_seq")
dbWriteTable(con, "user_group", user_group, overwrite = T)
dbGetQuery(con, "ALTER TABLE user_group ADD PRIMARY KEY (id)")
dbGetQuery(con, paste0("CREATE SEQUENCE user_group_id_seq MINVALUE ", as.character(max(user_group$id) + 1)))
dbGetQuery(con, "ALTER TABLE user_group ALTER id SET DEFAULT nextval('user_group_id_seq')")
dbGetQuery(con, "ALTER SEQUENCE user_group_id_seq OWNED BY user_group.id")

if (dbExistsTable(con, "exp_group")) dbRemoveTable(con, "exp_group")
dbGetQuery(con, "DROP SEQUENCE IF EXISTS exp_group_id_seq")
dbWriteTable(con, "exp_group", exp_group, overwrite = T)
dbGetQuery(con, "ALTER TABLE exp_group ADD PRIMARY KEY (id)")
dbGetQuery(con, paste0("CREATE SEQUENCE exp_group_id_seq MINVALUE ", as.character(max(exp_group$id) + 1)))
dbGetQuery(con, "ALTER TABLE exp_group ALTER id SET DEFAULT nextval('exp_group_id_seq')")
dbGetQuery(con, "ALTER SEQUENCE exp_group_id_seq OWNED BY exp_group.id")

if (dbExistsTable(con, "stores")) dbRemoveTable(con, "stores")
dbCreateTable(con, "stores", store)
dbWriteTable(con, "stores", store, overwrite = T)
dbGetQuery(con, "ALTER TABLE stores ADD PRIMARY KEY (id)")
dbGetQuery(con, paste0("CREATE SEQUENCE stores_id_seq MINVALUE ", as.character(max(store$id) + 1)))
dbGetQuery(con, "ALTER TABLE stores ALTER id SET DEFAULT nextval('stores_id_seq')")
dbGetQuery(con, "ALTER SEQUENCE stores_id_seq OWNED BY stores.id")
dbGetQuery(con, "CREATE INDEX stores_idx ON stores USING GIN (to_tsvector('english', name || ' ' || city || ' ' || entity))")
