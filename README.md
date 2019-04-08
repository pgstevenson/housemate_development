Housemate
================

*Existing apps with similar purpose: easyshare or Splitr*

This app helps you and the people you live with keep track of household
expenses.

This app has multiple components that have been set up in the following
containers in the Docker environment.

  - api - python API
  - web - nginx server (not currently active)
  - webapp - location of shiny appliction

The R project in the “r” directory contains some extra functions to help
develop the API and to read data into the postgreSQL database (which is
a persistent volume “pgdata” in the docker-compose file).

User access is managed through OAuth (Google).

The project is managed through a private BitBucket repository.

## Steps to get docker app running (dev env)

1.  docker-compose down (optional - removes old images)
2.  docker-compose up
3.  run R/02-dbconnect.R (gets r connected to the db - must do if 1. was
    done)
4.  run R/03-db\_init.R (populates db)
5.  192.168.99.100

## To Do list

  - Eventually
      - In monthly summary, add tooltip with amount when hovering over a
        point
      - PREMIUM FEATURE - monthly group reports
      - move edit item into a modal
      - document the app
      - PREMIUM FEATURE - more analyitics plots (forcasting/tracking
        against average of last few months)
      - link categories to group and have owner add/edit/remove
      - nice loggin screen
      - backup db
      - add in a currency setting
      - android app
      - iOS app
      - FAQ/contact
      - Admin controls
      - API Dashboard
  - Feature suggestions
      - Group levels (Tier 1 - free - 2 users per group, Tier 2 - $10
        p/m - unlimited group size, Tier 3 - $20 p/m - Advanced
        analytics
      - Group savings event (save total amount where people make
        payments + forecast, set amount where each person in group owes
        set amount)
