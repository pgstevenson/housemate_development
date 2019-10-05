#' Import database tables downloaed as CSV files
#' (Downloaded via PGAdmin 4)
#' Paul Stevenson - 2019-09-22
#' 

#### libraries ----

library(dplyr)
library(purrr)
library(lubridate)
library(readr)
library(stringr)
library(tidyr)

#### import data ---

data_source <- "data/20190922_tables"
dat <- map(list.files(path = data_source), ~read_csv(paste(data_source, ., sep = "/")))
names(dat) <- str_remove(list.files(path = data_source), ".csv")

#### Wrangling ----

# rename "person" table to "people"

names(dat) <- str_replace(names(dat), "person", "people")

# fix expenses date format

dat$expenses <- mutate_at(dat$expenses, "date", ymd)

# change to integers

dat <- map(dat, ~(mutate_at(., "id", as.integer)))
dat$expenses <- mutate_at(dat$expenses, c("gid", "root_id", "mod_user", "who", "category", "store"), as.integer)
dat$user_group <- mutate_at(dat$user_group, c("gid", "uid"), as.integer)
dat$exp_group <- mutate_at(dat$exp_group, "tier", as.integer)

# update stores with values from "notes" (22 Sep 19 extract)

new_stores <- tibble(name = c(dat$expenses %>%
  filter(!is.na(notes)) %>%
  filter(str_detect(notes, ",")) %>%
  filter(!str_detect(notes, "Chromecast|Brakes|Titanic|EB\\sGames|4235|PRICHODKO")) %>%
  .$notes,
  "Google,GOOGLE*GOOGLE,", "EB Games,EB GAMES JO,Joondalup",
  "Woolworths Petrol,EG FUELCO 4235 JOONDAL,Joondalup", "Blackwood Cafe,B M PRICHODKO PTY LTD,Nannup"),
  id = (max(dat$stores$id) + 1):(max(dat$stores$id) + length(name))) %>%
  select(id, name) %>%
  separate(name, into = c("name", "entity", "city"), sep = ",") %>%
  mutate(deleted = FALSE) %>%
  mutate_if(is.character, str_squish) %>%
  mutate_if(is.character, str_replace, "^$", NA_character_)

new_stores[new_stores$name == "Echo Point Motor Inn",]$city <- "Katoomba"
new_stores[new_stores$name == "Echo Point Motor Inn",]$entity <- NA
new_stores[new_stores$name == "Google",]$city <- "Online"
  
dat$stores <- bind_rows(dat$stores, new_stores)

dat$stores[dat$stores$id == 14,]$entity <- "BUNNINGS 746000"
dat$stores[dat$stores$id == 14,]$name <- "Bunnings"

#### add in missing id = 1 ----

dat$expenses <- bind_rows(tibble(date = Sys.Date(), who = 2, category = 9, amount = 0, store = NA, gid = 2,
                 id = 1, deleted = TRUE, notes = NA, mod_timestamp = NA, mod_user = NA, root_id = NA),
          dat$expenses)

#### arrange all tables by id ----

dat <- lapply(dat, function(x) arrange(x, id))

#### Write to database ----

#### groups ----

tmp <- apply(dat$exp_group, 1, function(x) {
  dbGetQuery(con, paste0("INSERT INTO groups(name, deleted, tier) VALUES ('", x["name"], "', ", x["deleted"], ", ", x["tier"], ")"))
})

#### categories ----

tmp <- apply(dat$categories, 1, function(x) {
  x <- sapply(x, function(y) gsub("'", "''", y))
  x <- sapply(x, trimws)
  dbGetQuery(con, paste0("INSERT INTO categories(name, parent) VALUES (",
                         "NULLIF('", x["name"], "', 'NA'), ",
                         "NULLIF('", x["parent"], "', 'NA')",
                         ")"))
})

#### users ----

tmp <- apply(dat$people, 1, function(x) {
  x <- sapply(x, function(y) gsub("'", "''", y))
  x <- sapply(x, trimws)
  dbGetQuery(con, paste0("INSERT INTO users(first, last, email, deleted) VALUES (",
                         "NULLIF('", x["first"], "', 'NA'), ",
                         "NULLIF('", x["last"], "', 'NA'), '", x["email"], "', ", x["deleted"], ")"))
})

#### stores ----

tmp <- apply(dat$stores, 1, function(x) {
  x <- sapply(x, function(y) gsub("'", "''", y))
  x <- sapply(x, trimws)
  dbGetQuery(con, paste0("INSERT INTO stores(name, entity, city, deleted) VALUES (",
                         "NULLIF('", x["name"], "', 'NA'), ",
                         "NULLIF('", x["entity"], "', 'NA'), ", 
                         "NULLIF('", x["city"], "', 'NA'), ",
                         x["deleted"], ")"))
})

#### expenses ----

tmp <- apply(dat$expenses, 1, function(x) {
  x["mod_timestamp"] <- ifelse(is.na(x["mod_timestamp"]),
                               format(Sys.time(), format = "%Y-%m-%dT%H:%M:%S"),
                               format(x["mod_timestamp"], format = "%Y-%m-%dT%H:%M:%S"))
  x <- sapply(x, function(y) gsub("'", "''", y))
  x <- sapply(x, function(y) ifelse(is.na(y), "NA", y))
  x["notes"] <- paste0("'", x["notes"], "'")
  x["category"] <- ifelse(x["category"] == "NA", "null", x["category"])
  x["store"] <- ifelse(x["store"] == "NA", "null", x["store"])
  x["mod_user"] <- ifelse(x["mod_user"] == "NA", "null", x["mod_user"])
  x["root_id"] <- ifelse(x["root_id"] == "NA", "null", x["root_id"])
  x <- sapply(x, trimws)
  dbGetQuery(con, paste0("INSERT INTO expenses(date, user_id, category, amount, store, group_id, deleted, notes, mod_timestamp, mod_user, root_id) VALUES ('",
                         x["date"], "', ",
                         x["who"], ", ",
                         "NULLIF(", x["category"], ", null)::int, ",
                         x["amount"], ", ",
                         "NULLIF(", x["store"], ", null)::int, ",
                         x["gid"], ", ",
                         x["deleted"], ", ",
                         "NULLIF(", x["notes"], ", 'NA'), ",
                         "'",x["mod_timestamp"], "', ",
                         "NULLIF(", x["mod_user"], ", null)::int, ",
                         "NULLIF(", x["root_id"], ", null)::int",
                         ")"))
})

#### users_groups ----

tmp <- apply(dat$user_group, 1, function(x) {
  dbGetQuery(con, paste0("INSERT INTO users_groups(user_id, group_id, admin) VALUES (",
                         x["uid"], ", ", x["gid"], ", '", x["admin"], "')"))
})
