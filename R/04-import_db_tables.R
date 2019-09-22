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

#### Write to database ----

dbWriteTable(con, "categories", dat$categories, overwrite = T)
dbWriteTable(con, "exp_group", dat$exp_group, overwrite = T)
dbWriteTable(con, "expenses", dat$expenses, overwrite = T)
dbWriteTable(con, "people", dat$people, overwrite = T)
dbWriteTable(con, "stores", dat$stores, overwrite = T)
dbWriteTable(con, "user_group", dat$user_group, overwrite = T)
