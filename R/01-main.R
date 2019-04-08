library(dplyr)
library(tidyr)
library(tibble)
library(lubridate)
library(httr)
library(jsonlite)

api_host <- "http://localhost:5000"
api_host <- "http://ec2-13-54-159-243.ap-southeast-2.compute.amazonaws.com:5000"
api_host <- "https://housemate.pgstevenson.com:5000"

# user output
# get user details
GET(paste0(api_host, "/v1/users?email=pstevenson6@gmail.com")) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# New user
GET(paste0(api_host, "/v1/users_new?email=abc1@def.com")) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# get groups for user
GET(paste0(api_host, "/v1/groups?email=pstevenson6@gmail.com")) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# get all expenses for gid
GET(paste0(api_host, "/v1/expenses?gid=2")) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df() %>% arrange(desc(date))

#insert new; git, gid amount, date and who are required
GET("192.168.99.100:5000/v1/expenses/new?uid=2&gid=2&amount=1.00&date=20200102&cid=5") %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# edit expense entry
# GET(paste0("http://192.168.99.100:5000/v1/expenses/edit?gid=2&date=20200101&uid=2&category=3&store=4&notes=", gsub(" ", "%20", "This has been edited twice"))) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# remove expense (deleted = t)
GET("192.168.99.100:5000/v1/expenses/remove?rid=167") %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# monthly summary by person
GET(paste0(api_host, "/v1/months/person?gid=1")) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# monthly summary by category
GET("192.168.99.100:5000/v1/months/category?gid=1") %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df() %>% arrange(category, desc(month))

# all categories
GET("192.168.99.100:5000/v1/categories") %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# search stores
search_string <- paste0(c("Joondalup", "fresh"), collapse = "%20")
GET(paste0(api_host, "/v1/stores?words=", search_string)) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

GET(paste0(api_host, "/v1/stores?id=51")) %>% content(type = "text", encoding = "UTF-8") %>% fromJSON() %>% tbl_df()

# reindex database
dbGetQuery(con, "REINDEX DATABASE postgres")

# table information
dbGetQuery(con, "select column_name,data_type 
from information_schema.columns 
           where table_name = 'exp_group'")

#### google api ----

#### app R options ----

options(googleAuthR.scopes.selected = c("https://www.googleapis.com/auth/userinfo.email",
                                        "https://www.googleapis.com/auth/userinfo.profile"))

options("googleAuthR.client_id" = "1051106373510-im09s2jtrkefktaadhql1uealnc36bsj.apps.googleusercontent.com")
options("googleAuthR.client_secret" = "HefJOj91ZMUN72zfqjLgiqxp")

options("googleAuthR.webapp.client_id" = "1051106373510-im09s2jtrkefktaadhql1uealnc36bsj.apps.googleusercontent.com")
options("googleAuthR.webapp.client_secret" = "HefJOj91ZMUN72zfqjLgiqxp")

options(shiny.port = 3838, shiny.host = "0.0.0.0")
options(shiny.launch.browser = T)

tmp <- list(Authentication = list(public_fields = list(token = list(cache_path = Sys.getenv()["SHINYPROXY_OIDC_ACCESS_TOKEN"],
                                                             params = list(scope = options("googleAuthR.scopes.selected")),
                                                             app = list(key = options("googleAuthR.client_id"),
                                                                        secret = options("googleAuthR.webapp.client_secret"))))))
gar_check_existing_token(tmp)

library(googleID)
library(googleAuthR)

access_token <- "ya29.GlzBBnbOpJgXG_5YOi1t74ZcYripfF27cyqLmcNz3WZo7QIWbM-p5u5W4HFtc6b72Fmg4ayT8ibfnTPYUUjHlshlbtz11bEyykz9WhazVJtoIubxjC1kwOW4_Ypgow"
key <- "AIzaSyChnfKrvqbkGAnLoJatFsY2EKGjZRLyiTA"
client_id <- "118092552704802096762"


GET(paste0("https://www.googleapis.com/plus/v1/people/", client_id, "?key=", key)) %>%
  content(type = "text", encoding = "UTF-8") %>%
  fromJSON()

gar_auth(token = access_token, new_user = T)

tmp <- list(Authentication = list(public_fields = list(token = access_token)))

with_shiny(get_user_info, shiny_access_token = access_token())

googleAuthR::gar_check_existing_token(tmp) 

#### Discovery document
GET("https://accounts.google.com/.well-known/openid-configuration") %>%
      content(type = "text", encoding = "UTF-8") %>%
  fromJSON()


GET(paste0("https://openidconnect.googleapis.com/v1/userinfo?token=", access_token, "client_secret_basic")) %>%
  content(type = "text", encoding = "UTF-8") %>%
  fromJSON()


# http://localhost/login/oauth2/code/shinyproxy?state=WvUA7kb1vyAiF1sxUgBkteJWz0IjDcw9jrT_9QnjVIU%3D&code=4/BAEQRoGd6a-7uCEw0vqEqQhqrPO9rwlJepw3hDXjrR7tBq8qK2U0sbZcXF4d34jb1yKMjKNsSmLI0ZSisBglvy4&scope=email+openid+https://www.googleapis.com/auth/userinfo.email&authuser=0&session_state=1ebb42c3c49ed2e4f4fadaa938f013942da63e56..dd81&prompt=none