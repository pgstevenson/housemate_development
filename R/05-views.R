#' define queries for postgres views/api calls
#' Paul Stevenson 2019-10-05
#'

#### categories ----

#' Get full list of categories in categories table

# Query DB

dbGetQuery(con, "SELECT id AS category_id,
                 CASE WHEN parent IS NULL THEN name ELSE CONCAT_WS('/', parent, name) END AS category
                 FROM categories")

# Query View

dbGetQuery(con, "SELECT * FROM cats")

#### users ----

#' Confirms user is active and returns details

# Query DB

dbGetQuery(con, "SELECT id AS user_id, first, last, email FROM users
                 WHERE email='{}' AND deleted = 'f'")

# Query View

dbGetQuery(con, "SELECT * FROM user_data WHERE email = '{}'")

#### groups ----

#' get a list of the user's active groups

dbGetQuery(con, "SELECT users.email, groups.id AS group_id, name, groups.deleted FROM groups
                 INNER JOIN (SELECT * FROM users_groups) AS users_groups ON groups.id = users_groups.group_id
                 INNER JOIN (SELECT id as user_id, email, deleted FROM users) AS users ON users_groups.user_id = users.user_id
                 WHERE users.email = '{}'")

dbGetQuery(con, "SELECT group_id, name, deleted FROM user_groups WHERE email = '{}'")

#### group_members ----

#' get a list of members in a group

# Query DB

dbGetQuery(con, "SELECT users_groups.group_id, users_groups.user_id, users.first, users.last, users_groups.admin FROM users_groups
                 INNER JOIN (SELECT * FROM users) AS users ON users_groups.user_id = users.id
                 WHERE group_id = {}")

# Query View

dbGetQuery(con, "SELECT user_id, first, last, admin FROM group_users WHERE group_id = {}")

#### users_new ----

#' add user to the users table
#' Needs some work, get first/last name from google auth

dbGetQuery(con, "INSERT INTO users(email) VALUES ('{}') RETURNING id AS user_id, first, last, email")

#### group_new ----

#' add new group to the groups table

dbGetQuery(con, "INSERT INTO groups(deleted) VALUES('f') RETURNING id AS group_id, name")

#### new_user_group ----

#' Link new user to new group
#' Good to know if this can, with the previous 2 inserts, can be done in a single step!

dbGetQuery(con, "INSERT INTO users_groups(uid, gid, admin) VALUES ('{}', '{}', 't')")

#### expenses ----

#' return all expenses for group id
#' Repayment int right, it's returning store not user
#' Consider limiting this to 1000 rows?

# Query DB

dbGetQuery(con, "SELECT expenses.id as id, to_char(expenses.date, 'YYYY-MM-DD') AS date,
                    users.id AS user_id, expenses.amount, cat.id AS category_id,
                    cat.category, stores.id AS store_id, stores.name AS store,
                    expenses.notes, expenses.root_id, expenses.group_id
                  FROM expenses
                  LEFT JOIN (SELECT * FROM users) AS users
                    ON expenses.user_id = users.id
                  LEFT JOIN (SELECT id, CASE WHEN parent IS NULL THEN name ELSE CONCAT_WS('/', parent, name) END AS category
                    FROM categories) AS cat
                    ON expenses.category = cat.id
                  LEFT JOIN stores
                    ON expenses.store = stores.id
                  WHERE expenses.deleted='f' AND {} = {}
                  ORDER BY expenses.date DESC") %>%
  as_tibble()

# Query View

dbGetQuery(con, "SELECT * FROM group_expenses WHERE {} = {}") %>%
  as_tibble()

dbGetQuery(con, "SELECT * FROM group_expenses WHERE group_id = 1") %>%
  as_tibble()

dbGetQuery(con, "SELECT * FROM group_expenses WHERE id = 2") %>%
  as_tibble()

#### expenses/new ----

#### expenses/remove ----

#### expenses/balance ----

#' calucalte the group's balance

#### months/person ----

#' return all expenses per person by month in group id (need to do error control)

# Query DB

dbGetQuery(con, "SELECT expenses.group_id, to_char(expenses.date, 'YYYY-MM') AS month,
        users.first AS first, sum(expenses.amount)
      FROM expenses
      INNER JOIN (SELECT * FROM users_groups) AS users_groups
        ON expenses.group_id = users_groups.group_id
      INNER JOIN (SELECT * FROM users) AS users
        ON users_groups.user_id = users.id
      WHERE expenses.group_id = {} AND expenses.deleted ='f'
      GROUP BY expenses.group_id, month, users.first
      ORDER BY month") %>%
  as_tibble() %>%
  pivot_wider(names_from = first, values_from = sum)

# Query View

dbGetQuery(con, "SELECT month, first, sum FROM month_user WHERE group_id = {}") %>%
  as_tibble() %>%
  pivot_wider(names_from = first, values_from = sum)

#### months/category ----

#' Return all expenses per category by month in group id (need to do error control)

dbGetQuery(con, "SELECT expenses.group_id, to_char(expenses.date, 'YYYY-MM') AS month, cat.category AS category, sum(expenses.amount) FROM expenses
                 LEFT JOIN (SELECT id, CASE WHEN parent IS NULL THEN name ELSE CONCAT_WS('/', parent, name) END AS category FROM categories) AS cat ON expenses.category = cat.id
                 WHERE expenses.group_id = {} AND expenses.deleted ='f'
                 GROUP BY expenses.group_id, month, cat.category
                 ORDER BY month") %>%
  as_tibble() %>%
  pivot_wider(names_from = category, values_from = sum)

dbGetQuery(con, "SELECT month, category, sum FROM month_category where group_id = {}") %>%
  as_tibble() %>%
  pivot_wider(names_from = category, values_from = sum)

#### stores ----

#' Get store(s) by dynamic search on store name, entity and city

dbGetQuery(con, "SELECT id, name, city, entity, CONCAT_WS(', ', name, city) AS out FROM stores
                 WHERE to_tsvector('english', coalesce(name,'') || ' ' || coalesce(city,'') || ' ' || coalesce(entity,'')) @@ to_tsquery('{}')
                  AND stores.deleted = 'f'")
